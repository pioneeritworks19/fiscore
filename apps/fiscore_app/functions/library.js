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

async function ensurePublishedLibrary(contentType) {
  const library = starterLibrary(contentType);
  const collection = publishedLibraryCollection(contentType);
  const entries = Object.entries(library);
  const snapshots = await Promise.all(
    entries.map(([libraryItemId]) => collection.doc(libraryItemId).get()),
  );
  const batch = db.batch();
  let changed = false;
  entries.forEach(([libraryItemId, item], index) => {
    const existing = snapshots[index].data();
    const currentVersion = Number(existing?.libraryVersion || 0);
    const starterVersion = Number(item.libraryVersion || item.version || 1);
    if (snapshots[index].exists && currentVersion >= starterVersion) {
      return;
    }
    changed = true;
    batch.set(collection.doc(libraryItemId), {
      ...item,
      libraryItemId,
      publishingSource: "fiscore",
      status: "published",
      publishedAt:
        existing?.publishedAt || admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });
  if (changed) {
    await batch.commit();
  }
  const catalogSnapshot = await collection
    .where("status", "==", "published")
    .get();
  return catalogSnapshot.docs.map((document) => ({
    libraryItemId: document.id,
    ...document.data(),
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
  await ensurePublishedLibrary(contentType);
  const librarySnapshot = await publishedLibraryCollection(contentType)
    .doc(libraryItemId)
    .get();
  if (!librarySnapshot.exists || librarySnapshot.data().status !== "published") {
    throw new HttpsError("not-found", "Library item was not found.");
  }
  const item = librarySnapshot.data();
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
    updateAvailable: false,
    lastSyncedAt: now,
    updatedAt: now,
    createdAt: currentData?.createdAt || now,
    publishedAt: currentData?.publishedAt || now,
  }, { merge: true });
  return { itemId: reference.id };
});

module.exports = { listFiScoreLibrary, adoptFiScoreLibraryItem };
