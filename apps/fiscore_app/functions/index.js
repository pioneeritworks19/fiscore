const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onObjectFinalized } = require("firebase-functions/v2/storage");
const admin = require("firebase-admin");
const { GoogleAuth } = require("google-auth-library");

admin.initializeApp();

const db = admin.firestore();
const bucket = admin.storage().bucket();
const region = "us-central1";
const storageRegion = "us-east1";
const apiBaseUrl = "https://fiscore-app-api-558552038453.us-central1.run.app";
const ownerRoles = ["tenant_owner"];
const inviteRoles = ["tenant_owner", "admin", "manager"];
const allowedMemberRoles = ["admin", "manager", "auditor", "staff"];
const googleAuth = new GoogleAuth();

function requireAuth(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in is required.");
  }
  return request.auth;
}

function normalizedEmail(auth) {
  const email = auth.token.email;
  if (!email) {
    throw new HttpsError("failed-precondition", "Signed-in user has no email.");
  }
  return email.toLowerCase();
}

function cleanString(value, fieldName, maxLength) {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `${fieldName} is required.`);
  }
  const cleaned = value.trim();
  if (!cleaned || cleaned.length > maxLength) {
    throw new HttpsError("invalid-argument", `${fieldName} is invalid.`);
  }
  return cleaned;
}

async function requireTenantRole(tenantId, uid, roles) {
  const memberRef = db.doc(`tenants/${tenantId}/members/${uid}`);
  const memberSnap = await memberRef.get();
  if (!memberSnap.exists) {
    throw new HttpsError("permission-denied", "Tenant membership is required.");
  }

  const member = memberSnap.data();
  if (member.status !== "active" || !roles.includes(member.role)) {
    throw new HttpsError("permission-denied", "Insufficient tenant role.");
  }

  return member;
}

async function callApi(path) {
  const client = await googleAuth.getIdTokenClient(apiBaseUrl);
  const response = await client.request({ url: `${apiBaseUrl}${path}` });
  return response.data;
}

function restaurantSummaryPayload(item) {
  return {
    masterRestaurantId: item.master_restaurant_id,
    displayName: item.display_name,
    addressLine1: item.address_line1,
    city: item.city,
    stateCode: item.state_code,
    zipCode: item.zip_code || null,
    status: item.status,
    inspectionCount: item.inspection_count || 0,
    latestInspectionDate: item.latest_inspection_date || null,
    sourceLinkCount: item.source_link_count || 0,
  };
}

function asArray(value) {
  return Array.isArray(value) ? value : [];
}

function safeText(value, fallback = null) {
  return typeof value === "string" && value.trim() ? value.trim() : fallback;
}

function violationTitle(finding) {
  return (
    safeText(finding.normalized_title) ||
    safeText(finding.official_code) ||
    safeText(finding.official_text, "Imported public inspection finding")
  );
}

function summarizeInspectionImport(inspections) {
  const latestInspection = inspections[0] || null;
  const latestInspectionId = latestInspection?.master_inspection_id || null;
  const importedFindingCount = inspections.reduce(
    (total, inspection) => total + asArray(inspection.findings).length,
    0,
  );
  const openViolationCount = latestInspection
    ? asArray(latestInspection.findings).length
    : 0;

  return {
    latestInspection,
    latestInspectionId,
    importedFindingCount,
    openViolationCount,
    closedViolationCount: Math.max(importedFindingCount - openViolationCount, 0),
  };
}

async function commitBatches(writes) {
  const chunkSize = 450;
  for (let index = 0; index < writes.length; index += chunkSize) {
    const batch = db.batch();
    for (const write of writes.slice(index, index + chunkSize)) {
      batch.set(write.ref, write.data, write.options || {});
    }
    await batch.commit();
  }
}

function violationAttachmentFromPath(objectPath) {
  const match = objectPath.match(
    /^tenants\/([^/]+)\/sites\/([^/]+)\/violations\/([^/]+)\/attachments\/([^/]+)\/original\.[^/]+$/i,
  );
  if (!match) {
    return null;
  }
  return {
    tenantId: match[1],
    siteId: match[2],
    violationId: match[3],
    attachmentId: match[4],
  };
}

async function safeDeleteStorageFile(filePath) {
  try {
    await bucket.file(filePath).delete();
  } catch (error) {
    if (error.code !== 404) {
      throw error;
    }
  }
}

async function importMasterDataForSite({
  tenantId,
  siteRef,
  masterRestaurantId,
  detail,
  now,
  preserveExistingWorkflow = false,
}) {
  const tenantRef = db.doc(`tenants/${tenantId}`);
  const restaurant = detail?.restaurant;
  const inspections = asArray(detail?.inspections);
  if (!restaurant) {
    throw new HttpsError("not-found", "Master restaurant was not found.");
  }

  const {
    latestInspection,
    latestInspectionId,
    importedFindingCount,
    openViolationCount,
    closedViolationCount,
  } = summarizeInspectionImport(inspections);

  const writes = [
    {
      ref: siteRef,
      data: {
        inspectionCountSnapshot: restaurant.inspection_count || 0,
        latestInspectionDateSnapshot: restaurant.latest_inspection_date || null,
        latestInspectionGradeSnapshot: latestInspection?.grade || null,
        latestInspectionScoreSnapshot: latestInspection?.score ?? null,
        importedInspectionCountSnapshot: inspections.length,
        importedFindingCountSnapshot: importedFindingCount,
        openViolationCountSnapshot: openViolationCount,
        closedViolationCountSnapshot: closedViolationCount,
        pendingReviewCountSnapshot: 0,
        lastMasterDataSyncAt: now,
        updatedAt: now,
      },
      options: { merge: true },
    },
  ];

  for (const inspection of inspections) {
    const masterInspectionId = inspection.master_inspection_id;
    if (!masterInspectionId) {
      continue;
    }

    const isLatestInspection = masterInspectionId === latestInspectionId;
    const inspectionRef = siteRef.collection("inspections").doc(masterInspectionId);
    writes.push({
      ref: inspectionRef,
      data: {
        tenantId,
        siteId: siteRef.id,
        masterRestaurantId,
        masterInspectionId,
        sourceId: inspection.source_id || null,
        sourceSlug: inspection.source_slug || null,
        sourceName: inspection.source_name || null,
        sourceInspectionKey: inspection.source_inspection_key || null,
        inspectionDate: inspection.inspection_date || null,
        inspectionType: inspection.inspection_type || null,
        score: inspection.score ?? null,
        grade: inspection.grade || null,
        officialStatus: inspection.official_status || null,
        reportUrl: inspection.report_url || null,
        reportAvailabilityStatus: inspection.report_availability_status || null,
        reportFormat: inspection.report_format || null,
        reportStoragePath: inspection.report_storage_path || null,
        findingCount: asArray(inspection.findings).length,
        importState: isLatestInspection ? "latest" : "historical",
        importedAt: now,
        updatedAt: now,
      },
      options: { merge: true },
    });

    for (const finding of asArray(inspection.findings)) {
      const masterFindingId = finding.master_finding_id;
      if (!masterFindingId) {
        continue;
      }

      const defaultStatus = isLatestInspection ? "open" : "closed";
      const violationRef = siteRef.collection("violations").doc(masterFindingId);
      const findingRef = inspectionRef.collection("findings").doc(masterFindingId);
      const existingViolationSnap = preserveExistingWorkflow
        ? await violationRef.get()
        : null;
      const violationExists = existingViolationSnap?.exists === true;
      const findingSnapshot = {
        tenantId,
        siteId: siteRef.id,
        masterRestaurantId,
        masterInspectionId,
        masterFindingId,
        sourceFindingKey: finding.source_finding_key || null,
        findingOrder: finding.finding_order ?? null,
        officialCode: finding.official_code || null,
        officialClauseReference: finding.official_clause_reference || null,
        officialText: finding.official_text || "Imported public inspection finding",
        officialDetailText: finding.official_detail_text || null,
        auditorComments: finding.auditor_comments || null,
        normalizedTitle: finding.normalized_title || null,
        normalizedCategory: finding.normalized_category || null,
        severity: finding.severity || null,
        correctedDuringInspection: finding.corrected_during_inspection ?? null,
        isRepeatViolation: finding.is_repeat_violation ?? null,
        inspectionDate: inspection.inspection_date || null,
        inspectionType: inspection.inspection_type || null,
        inspectionScore: inspection.score ?? null,
        inspectionGrade: inspection.grade || null,
        officialStatus: inspection.official_status || null,
        reportUrl: inspection.report_url || null,
        importedAt: now,
        updatedAt: now,
      };

      writes.push({
        ref: findingRef,
        data: {
          ...findingSnapshot,
          mappedViolationId: violationRef.id,
          tenantViolationStatus: violationExists
            ? existingViolationSnap.data().status || defaultStatus
            : defaultStatus,
        },
        options: { merge: true },
      });

      const sourceFields = {
        ...findingSnapshot,
        sourceType: "health_department_inspection",
        sourceReferenceId: masterInspectionId,
        sourceFindingId: masterFindingId,
        title: violationTitle(finding),
        summaryText: finding.official_text || "Imported public inspection finding",
        description: finding.official_detail_text || finding.official_text || null,
        displayText: finding.official_text || "Imported public inspection finding",
        clauseReference: finding.official_clause_reference || finding.official_code || null,
        sectionLabel: finding.normalized_category || null,
        violationType: "public_inspection_finding",
        updatedAt: now,
      };

      writes.push({
        ref: violationRef,
        data: violationExists
          ? sourceFields
          : {
              ...sourceFields,
              priority: isLatestInspection ? "normal" : "historical",
              status: defaultStatus,
              lifecycleStage: defaultStatus,
              reviewStatus: "not_submitted",
              requiresReview: false,
              currentResponseType: null,
              identifiedAt: inspection.inspection_date || null,
              identifiedBy: "public_health_department",
              closedAt: isLatestInspection ? null : now,
              closedBy: isLatestInspection ? null : "system_import",
              closureReason: isLatestInspection
                ? null
                : "Historical finding imported as closed during site onboarding.",
              createdAt: now,
            },
        options: { merge: true },
      });
    }
  }

  await commitBatches(writes);

  return {
    importedInspectionCount: inspections.length,
    importedFindingCount,
    openViolationCount,
    closedViolationCount,
  };
}

exports.createTenantAndOwner = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const uid = auth.uid;
  const email = normalizedEmail(auth);
  const tenantName = cleanString(request.data?.tenantName, "Tenant name", 120);
  const displayName =
    auth.token.name || request.data?.displayName || email.split("@")[0];
  const now = admin.firestore.FieldValue.serverTimestamp();

  const tenantRef = db.collection("tenants").doc();
  const userRef = db.doc(`users/${uid}`);
  const memberRef = tenantRef.collection("members").doc(uid);

  await db.runTransaction(async (transaction) => {
    const userSnap = await transaction.get(userRef);
    if (userSnap.exists && userSnap.data().activeTenantId) {
      throw new HttpsError(
        "failed-precondition",
        "This user already belongs to a FiScore workspace.",
      );
    }

    transaction.set(
      userRef,
      {
        displayName,
        email,
        photoUrl: auth.token.picture || null,
        authProviders: auth.token.firebase?.sign_in_provider
          ? [auth.token.firebase.sign_in_provider]
          : [],
        activeTenantId: tenantRef.id,
        tenantIds: admin.firestore.FieldValue.arrayUnion(tenantRef.id),
        status: "active",
        createdAt: now,
        updatedAt: now,
      },
      { merge: true },
    );

    transaction.set(tenantRef, {
      name: tenantName,
      status: "active",
      primaryOwnerUserId: uid,
      subscriptionStatus: "trial",
      billingProvider: "none",
      includedSiteCount: 1,
      activeSiteCount: 0,
      enterpriseManaged: false,
      createdAt: now,
      updatedAt: now,
    });

    transaction.set(memberRef, {
      userId: uid,
      displayNameSnapshot: displayName,
      emailSnapshot: email,
      role: "tenant_owner",
      status: "active",
      joinedAt: now,
      createdAt: now,
      updatedAt: now,
    });
  });

  return { tenantId: tenantRef.id };
});

exports.createTenantInvite = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const email = cleanString(request.data?.email, "Email", 254).toLowerCase();
  const role = cleanString(request.data?.role, "Role", 40);

  if (!allowedMemberRoles.includes(role)) {
    throw new HttpsError("invalid-argument", "Unsupported invite role.");
  }

  await requireTenantRole(tenantId, auth.uid, inviteRoles);

  const now = admin.firestore.FieldValue.serverTimestamp();
  const inviteRef = db.collection(`tenants/${tenantId}/invites`).doc();
  await inviteRef.set({
    email,
    role,
    status: "pending",
    invitedBy: auth.uid,
    invitedAt: now,
    acceptedBy: null,
    acceptedAt: null,
    createdAt: now,
    updatedAt: now,
  });

  return { inviteId: inviteRef.id };
});

exports.searchMasterRestaurants = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const query = cleanString(request.data?.query, "Search text", 120);

  if (query.length < 2) {
    throw new HttpsError("invalid-argument", "Enter at least 2 characters.");
  }

  await requireTenantRole(tenantId, auth.uid, inviteRoles);

  const params = new URLSearchParams({
    q: query,
    page: "1",
    page_size: "10",
    has_inspections: "true",
  });
  const results = await callApi(`/app/master-restaurants?${params.toString()}`);

  return {
    restaurants: Array.isArray(results)
      ? results.map(restaurantSummaryPayload)
      : [],
  };
});

exports.linkMasterRestaurantSite = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const masterRestaurantId = cleanString(
    request.data?.masterRestaurantId,
    "Master restaurant ID",
    160,
  );
  const now = admin.firestore.FieldValue.serverTimestamp();

  await requireTenantRole(tenantId, auth.uid, inviteRoles);

  const detail = await callApi(`/app/master-restaurants/${masterRestaurantId}`);
  const restaurant = detail?.restaurant;
  const inspections = asArray(detail?.inspections);
  if (!restaurant) {
    throw new HttpsError("not-found", "Master restaurant was not found.");
  }

  const {
    latestInspection,
    importedFindingCount,
    openViolationCount,
    closedViolationCount,
  } = summarizeInspectionImport(inspections);

  const tenantRef = db.doc(`tenants/${tenantId}`);
  const siteRef = tenantRef.collection("sites").doc();
  const existing = await tenantRef
    .collection("sites")
    .where("masterRestaurantId", "==", masterRestaurantId)
    .limit(1)
    .get();

  if (!existing.empty) {
    throw new HttpsError(
      "already-exists",
      "This restaurant is already linked to the workspace.",
    );
  }

  await db.runTransaction(async (transaction) => {
    const tenantSnap = await transaction.get(tenantRef);
    if (!tenantSnap.exists || tenantSnap.data().status !== "active") {
      throw new HttpsError("failed-precondition", "Workspace is not active.");
    }

    transaction.set(siteRef, {
      masterRestaurantId,
      name: restaurant.display_name,
      addressLine1: restaurant.address_line1,
      city: restaurant.city,
      state: restaurant.state_code,
      postalCode: restaurant.zip_code || null,
      phone: null,
      siteType: "restaurant",
      status: "active",
      linkStatus: "linked",
      linkMethod: "owner_selected_master_restaurant",
      inspectionCountSnapshot: restaurant.inspection_count || 0,
      latestInspectionDateSnapshot: restaurant.latest_inspection_date || null,
      latestInspectionGradeSnapshot: latestInspection?.grade || null,
      latestInspectionScoreSnapshot: latestInspection?.score ?? null,
      importedInspectionCountSnapshot: inspections.length,
      importedFindingCountSnapshot: importedFindingCount,
      openViolationCountSnapshot: openViolationCount,
      closedViolationCountSnapshot: closedViolationCount,
      pendingReviewCountSnapshot: 0,
      lastMasterDataSyncAt: now,
      createdBy: auth.uid,
      createdAt: now,
      updatedAt: now,
    });

    transaction.update(tenantRef, {
      activeSiteCount: admin.firestore.FieldValue.increment(1),
      updatedAt: now,
    });
  });

  const importResult = await importMasterDataForSite({
    tenantId,
    siteRef,
    masterRestaurantId,
    detail,
    now,
    preserveExistingWorkflow: false,
  });

  return {
    siteId: siteRef.id,
    ...importResult,
  };
});

exports.syncLinkedSiteMasterData = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const siteId = cleanString(request.data?.siteId, "Site ID", 160);
  const now = admin.firestore.FieldValue.serverTimestamp();

  await requireTenantRole(tenantId, auth.uid, inviteRoles);

  const tenantRef = db.doc(`tenants/${tenantId}`);
  const siteRef = tenantRef.collection("sites").doc(siteId);
  const siteSnap = await siteRef.get();
  if (!siteSnap.exists || siteSnap.data().status !== "active") {
    throw new HttpsError("not-found", "Active site was not found.");
  }

  const site = siteSnap.data();
  const masterRestaurantId = safeText(site.masterRestaurantId);
  if (!masterRestaurantId) {
    throw new HttpsError(
      "failed-precondition",
      "This site is not linked to master restaurant data.",
    );
  }

  const detail = await callApi(`/app/master-restaurants/${masterRestaurantId}`);
  const result = await importMasterDataForSite({
    tenantId,
    siteRef,
    masterRestaurantId,
    detail,
    now,
    preserveExistingWorkflow: true,
  });

  return {
    siteId,
    ...result,
  };
});

exports.createSite = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const siteName = cleanString(request.data?.siteName, "Site name", 120);
  const addressLine1 = cleanString(request.data?.addressLine1, "Address", 160);
  const city = cleanString(request.data?.city, "City", 80);
  const state = cleanString(request.data?.state, "State", 40);
  const postalCode = cleanString(request.data?.postalCode, "ZIP code", 20);
  const siteType = cleanString(request.data?.siteType, "Site type", 40);
  const phone =
    typeof request.data?.phone === "string" ? request.data.phone.trim() : "";
  const now = admin.firestore.FieldValue.serverTimestamp();

  await requireTenantRole(tenantId, auth.uid, inviteRoles);

  const tenantRef = db.doc(`tenants/${tenantId}`);
  const siteRef = tenantRef.collection("sites").doc();

  await db.runTransaction(async (transaction) => {
    const tenantSnap = await transaction.get(tenantRef);
    if (!tenantSnap.exists || tenantSnap.data().status !== "active") {
      throw new HttpsError("failed-precondition", "Workspace is not active.");
    }

    transaction.set(siteRef, {
      name: siteName,
      addressLine1,
      city,
      state,
      postalCode,
      phone: phone || null,
      siteType,
      status: "active",
      createdBy: auth.uid,
      createdAt: now,
      updatedAt: now,
    });

    transaction.update(tenantRef, {
      activeSiteCount: admin.firestore.FieldValue.increment(1),
      updatedAt: now,
    });
  });

  return { siteId: siteRef.id };
});

exports.acceptTenantInvite = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const uid = auth.uid;
  const email = normalizedEmail(auth);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const inviteId = cleanString(request.data?.inviteId, "Invite ID", 160);
  const now = admin.firestore.FieldValue.serverTimestamp();
  const inviteRef = db.doc(`tenants/${tenantId}/invites/${inviteId}`);
  const memberRef = db.doc(`tenants/${tenantId}/members/${uid}`);
  const userRef = db.doc(`users/${uid}`);

  await db.runTransaction(async (transaction) => {
    const inviteSnap = await transaction.get(inviteRef);
    if (!inviteSnap.exists) {
      throw new HttpsError("not-found", "Invite not found.");
    }

    const invite = inviteSnap.data();
    if (invite.status !== "pending" || invite.email !== email) {
      throw new HttpsError("permission-denied", "Invite is not valid for this user.");
    }

    const displayName = auth.token.name || email.split("@")[0];
    transaction.set(
      userRef,
      {
        displayName,
        email,
        photoUrl: auth.token.picture || null,
        activeTenantId: tenantId,
        tenantIds: admin.firestore.FieldValue.arrayUnion(tenantId),
        status: "active",
        createdAt: now,
        updatedAt: now,
      },
      { merge: true },
    );
    transaction.set(memberRef, {
      userId: uid,
      displayNameSnapshot: displayName,
      emailSnapshot: email,
      role: invite.role,
      status: "active",
      invitedBy: invite.invitedBy,
      invitedAt: invite.invitedAt,
      joinedAt: now,
      createdAt: now,
      updatedAt: now,
    });
    transaction.update(inviteRef, {
      status: "accepted",
      acceptedBy: uid,
      acceptedAt: now,
      updatedAt: now,
    });
  });

  return { tenantId };
});

exports.deactivateTenantMember = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const userId = cleanString(request.data?.userId, "User ID", 160);
  const now = admin.firestore.FieldValue.serverTimestamp();

  await requireTenantRole(tenantId, auth.uid, ownerRoles);

  if (auth.uid === userId) {
    throw new HttpsError("failed-precondition", "You cannot deactivate yourself.");
  }

  await db.doc(`tenants/${tenantId}/members/${userId}`).update({
    status: "inactive",
    deactivatedBy: auth.uid,
    deactivatedAt: now,
    updatedAt: now,
  });

  return { tenantId, userId };
});

exports.processViolationAttachmentImage = onObjectFinalized(
  {
    region: storageRegion,
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  async (event) => {
    const objectPath = event.data.name;
    const contentType = event.data.contentType || "";
    if (!objectPath || !contentType.startsWith("image/")) {
      return;
    }

    const attachment = violationAttachmentFromPath(objectPath);
    if (!attachment) {
      return;
    }

    const { tenantId, siteId, violationId, attachmentId } = attachment;
    const attachmentRef = db
      .doc(`tenants/${tenantId}/sites/${siteId}/violations/${violationId}`)
      .collection("attachments")
      .doc(attachmentId);
    const now = admin.firestore.FieldValue.serverTimestamp();
    const basePath = objectPath.replace(/\/original\.[^/]+$/i, "");
    const compressedPath = `${basePath}/image.jpg`;
    const thumbnailPath = `${basePath}/thumb.jpg`;

    try {
      await attachmentRef.set(
        {
          status: "processing",
          processingStartedAt: now,
          updatedAt: now,
        },
        { merge: true },
      );

      const sharp = require("sharp");
      const [originalBuffer] = await bucket.file(objectPath).download();
      const image = sharp(originalBuffer, { failOn: "none" }).rotate();
      const metadata = await image.metadata();
      const compressedBuffer = await sharp(originalBuffer, { failOn: "none" })
        .rotate()
        .resize({
          width: 1600,
          height: 1600,
          fit: "inside",
          withoutEnlargement: true,
        })
        .jpeg({ quality: 76, mozjpeg: true })
        .toBuffer();
      const thumbnailBuffer = await sharp(originalBuffer, { failOn: "none" })
        .rotate()
        .resize({
          width: 360,
          height: 360,
          fit: "inside",
          withoutEnlargement: true,
        })
        .jpeg({ quality: 68, mozjpeg: true })
        .toBuffer();

      await bucket.file(compressedPath).save(compressedBuffer, {
        metadata: {
          contentType: "image/jpeg",
          metadata: {
            tenantId,
            siteId,
            violationId,
            attachmentId,
            source: "processed",
          },
        },
      });
      await bucket.file(thumbnailPath).save(thumbnailBuffer, {
        metadata: {
          contentType: "image/jpeg",
          metadata: {
            tenantId,
            siteId,
            violationId,
            attachmentId,
            source: "thumbnail",
          },
        },
      });

      await attachmentRef.set(
        {
          status: "ready",
          contentType: "image/jpeg",
          storagePath: compressedPath,
          compressedPath,
          thumbnailPath,
          sizeBytes: compressedBuffer.length,
          compressedSizeBytes: compressedBuffer.length,
          thumbnailSizeBytes: thumbnailBuffer.length,
          width: metadata.width || null,
          height: metadata.height || null,
          compression: {
            maxEdge: 1600,
            quality: 76,
            thumbnailMaxEdge: 360,
            thumbnailQuality: 68,
          },
          processedAt: now,
          updatedAt: now,
        },
        { merge: true },
      );

      await safeDeleteStorageFile(objectPath);
    } catch (error) {
      console.error("Failed to process violation attachment image", {
        objectPath,
        error,
      });
      await attachmentRef.set(
        {
          status: "failed",
          processingError: error.message || "Image processing failed.",
          updatedAt: now,
        },
        { merge: true },
      );
    }
  },
);
