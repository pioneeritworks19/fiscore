const { onCall, HttpsError } = require("firebase-functions/v2/https");
const {
  admin,
  db,
  region,
  siteActionRoles,
  requireAuth,
  cleanString,
  requireTenantRole,
} = require("./shared/runtime");
const { starterChecklistLibrary, starterTrainingLibrary } = require("./catalogs");

const libraryBrowseRoles = ["tenant_owner", "admin", "manager", "auditor", "staff"];

function starterLibrary(contentType) {
  const library = contentType === "checklist"
    ? starterChecklistLibrary
    : contentType === "training"
      ? starterTrainingLibrary
      : null;
  if (!library) {
    throw new HttpsError("invalid-argument", "Library content type is invalid.");
  }
  return library;
}

function publishedLibraryCollection(contentType) {
  starterLibrary(contentType);
  return db.collection(`fiscoreLibrary/${contentType}/items`);
}

function libraryVersion(item) {
  return Number(item?.libraryVersion || item?.version || 1);
}

function versionReference(collection, libraryItemId, version) {
  return collection.doc(libraryItemId).collection("versions").doc(String(version));
}

function publishedVersionData(item, libraryItemId, version) {
  return {
    ...item,
    libraryItemId,
    libraryVersion: version,
    version,
    publishingSource: "fiscore",
    status: "published",
  };
}

function publishedSummaryData(item, libraryItemId, currentVersion, existing) {
  const { sections, quickCheckQuestions, mediaAssets, ...summary } = item;
  return {
    ...summary,
    libraryItemId,
    libraryVersion: currentVersion,
    currentVersion,
    latestPublishedVersion: currentVersion,
    publishingSource: "fiscore",
    status: "published",
    publishedAt:
      existing?.publishedAt || admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

async function ensurePublishedLibrary(contentType) {
  const library = starterLibrary(contentType);
  const collection = publishedLibraryCollection(contentType);
  const entries = Object.entries(library);
  const batch = db.batch();
  let changed = false;
  for (const [libraryItemId, item] of entries) {
    const reference = collection.doc(libraryItemId);
    const snapshot = await reference.get();
    const existing = snapshot.data();
    const existingVersion = snapshot.exists
      ? Number(existing.currentVersion || existing.libraryVersion || 0)
      : 0;
    const starterVersion = libraryVersion(item);

    if (snapshot.exists && existingVersion > 0) {
      const existingVersionReference = versionReference(
        collection,
        libraryItemId,
        existingVersion,
      );
      const existingVersionSnapshot = await existingVersionReference.get();
      if (!existingVersionSnapshot.exists) {
        changed = true;
        batch.set(
          existingVersionReference,
          publishedVersionData(existing, libraryItemId, existingVersion),
        );
      }
    }

    const starterVersionReference = versionReference(
      collection,
      libraryItemId,
      starterVersion,
    );
    const starterVersionSnapshot = await starterVersionReference.get();
    if (!starterVersionSnapshot.exists) {
      changed = true;
      batch.set(
        starterVersionReference,
        publishedVersionData(item, libraryItemId, starterVersion),
      );
    }

    if (!snapshot.exists || starterVersion >= existingVersion) {
      if (
        !snapshot.exists ||
        existing.currentVersion !== starterVersion ||
        existing.latestPublishedVersion !== starterVersion
      ) {
        changed = true;
      }
      batch.set(
        reference,
        publishedSummaryData(item, libraryItemId, starterVersion, existing),
      );
    }
  }
  if (changed) {
    await batch.commit();
  }
  const catalogSnapshot = await collection
    .where("status", "==", "published")
    .get();
  return Promise.all(catalogSnapshot.docs.map(async (document) => {
    const summary = document.data();
    const currentVersion = Number(
      summary.currentVersion || summary.libraryVersion || 1,
    );
    const versionSnapshot = await versionReference(
      collection,
      document.id,
      currentVersion,
    ).get();
    return {
      libraryItemId: document.id,
      ...summary,
      ...(versionSnapshot.data() || {}),
      currentVersion,
      latestPublishedVersion:
        Number(summary.latestPublishedVersion || currentVersion),
    };
  }));
}

function tenantItemPath(tenantId, contentType, libraryItemId) {
  const collection = contentType === "checklist"
    ? "checklistTemplates"
    : contentType === "training"
      ? "trainings"
      : null;
  if (!collection) {
    throw new HttpsError("invalid-argument", "Library content type is invalid.");
  }
  return `tenants/${tenantId}/${collection}/${libraryItemId}`;
}

const listFiScoreLibrary = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const contentType = cleanString(request.data?.contentType, "Content type", 40);
  await requireTenantRole(tenantId, auth.uid, libraryBrowseRoles);
  const entries = (await ensurePublishedLibrary(contentType)).map((item) => [
    item.libraryItemId,
    item,
  ]);
  const tenantSnapshots = await Promise.all(
    entries.map(([libraryItemId]) =>
      db.doc(tenantItemPath(tenantId, contentType, libraryItemId)).get(),
    ),
  );
  const statusBatch = db.batch();
  let statusChanged = false;
  entries.forEach(([libraryItemId, item], index) => {
    const snapshot = tenantSnapshots[index];
    const tenantItem = snapshot.data();
    if (!snapshot.exists || tenantItem.syncMode !== "synced_from_library") {
      return;
    }
    const libraryVersion = Number(item.libraryVersion || item.version || 1);
    const updateAvailable = Number(tenantItem.libraryVersion || 0) < libraryVersion;
    if (
      tenantItem.updateAvailable !== updateAvailable ||
      tenantItem.syncStatus !==
        (updateAvailable ? "update_available" : "up_to_date")
    ) {
      statusChanged = true;
      statusBatch.set(snapshot.ref, {
        updateAvailable,
        syncStatus: updateAvailable ? "update_available" : "up_to_date",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
  });
  if (statusChanged) {
    await statusBatch.commit();
  }
  return {
    items: entries.map(([libraryItemId, item], index) => {
      const tenantItem = tenantSnapshots[index].data();
      const libraryVersion = Number(
        item.libraryVersion || item.version || 1,
      );
      const tenantLibraryVersion = Number(tenantItem?.libraryVersion || 0);
      return {
        libraryItemId,
        ...item,
        inMyLibrary: tenantSnapshots[index].exists,
        tenantLibraryVersion: tenantLibraryVersion,
        updateAvailable:
          tenantSnapshots[index].exists && tenantLibraryVersion < libraryVersion,
      };
    }),
  };
});

const adoptFiScoreLibraryItem = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const contentType = cleanString(request.data?.contentType, "Content type", 40);
  const libraryItemId = cleanString(
    request.data?.libraryItemId,
    "Library item ID",
    120,
  );
  await requireTenantRole(tenantId, auth.uid, siteActionRoles);
  const publishedItems = await ensurePublishedLibrary(contentType);
  const item = publishedItems.find(
    (publishedItem) => publishedItem.libraryItemId === libraryItemId,
  );
  if (!item || item.status !== "published") {
    throw new HttpsError("not-found", "Library item was not found.");
  }
  const reference = db.doc(tenantItemPath(tenantId, contentType, libraryItemId));
  const current = await reference.get();
  const currentData = current.data();
  const sourceField = contentType === "checklist"
    ? "templateSource"
    : "trainingSource";
  if (
    current.exists &&
    currentData[sourceField] !== "library_synced" &&
    currentData.syncMode !== "synced_from_library"
  ) {
    throw new HttpsError(
      "already-exists",
      "A tenant-created item already uses this identifier.",
    );
  }
  const now = admin.firestore.FieldValue.serverTimestamp();
  await reference.set({
    ...item,
    ...(contentType === "checklist"
      ? {
        sourceTemplateId: libraryItemId,
        stableTemplateId: libraryItemId,
      }
      : {}),
    isActive: true,
    status: "active",
    libraryVersionPath:
      `fiscoreLibrary/${contentType}/items/${libraryItemId}/versions/${item.libraryVersion}`,
    updateAvailable: false,
    lastSyncedAt: now,
    updatedAt: now,
    createdAt: currentData?.createdAt || now,
    publishedAt: currentData?.publishedAt || now,
  }, { merge: true });
  return { itemId: reference.id };
});

module.exports = { listFiScoreLibrary, adoptFiScoreLibraryItem };
