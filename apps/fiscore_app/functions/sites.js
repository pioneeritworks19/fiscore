const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleAuth } = require("google-auth-library");
const {
  admin,
  db,
  bucket,
  region,
  siteActionRoles,
  requireAuth,
  cleanString,
  requireTenantRole,
  safeText,
} = require("./shared/runtime");

const apiBaseUrl = "https://fiscore-app-api-558552038453.us-central1.run.app";
const googleAuth = new GoogleAuth();

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

function parseStoragePath(value) {
  const text = safeText(value);
  if (!text) {
    return null;
  }
  if (text.startsWith("gs://")) {
    const withoutScheme = text.slice(5);
    const slashIndex = withoutScheme.indexOf("/");
    if (slashIndex <= 0) {
      return null;
    }
    return {
      bucketName: withoutScheme.slice(0, slashIndex),
      filePath: withoutScheme.slice(slashIndex + 1),
    };
  }
  return {
    bucketName: bucket.name,
    filePath: text,
  };
}

function extensionForReport(format, filePath) {
  const normalizedFormat = safeText(format, "").toLowerCase();
  if (["pdf", "html", "htm", "png", "jpg", "jpeg"].includes(normalizedFormat)) {
    return normalizedFormat === "htm" ? "html" : normalizedFormat;
  }
  const pathExtension = safeText(filePath, "").split(".").pop().toLowerCase();
  if (["pdf", "html", "htm", "png", "jpg", "jpeg"].includes(pathExtension)) {
    return pathExtension === "htm" ? "html" : pathExtension;
  }
  return "pdf";
}

function contentTypeForReport(extension) {
  switch (extension) {
    case "html":
      return "text/html";
    case "png":
      return "image/png";
    case "jpg":
    case "jpeg":
      return "image/jpeg";
    default:
      return "application/pdf";
  }
}

async function copyMasterReportToTenant({
  tenantId,
  siteId,
  masterInspectionId,
  inspection,
  now,
}) {
  // TODO: De-emphasize imported public reports until ingestion can create a
  // clean customer-facing artifact. Many public sites only expose HTML reports
  // with fragile relative assets, so the app should eventually prefer PDFs or
  // generated mobile-friendly snapshots stored in tenant-owned storage.
  const source = parseStoragePath(inspection.report_storage_path);
  if (!source) {
    return null;
  }

  const extension = extensionForReport(inspection.report_format, source.filePath);
  const attachmentId = "master_report";
  const destinationPath =
    `tenants/${tenantId}/sites/${siteId}/inspections/${masterInspectionId}` +
    `/attachments/${attachmentId}/report.${extension}`;

  try {
    const sourceFile = admin.storage().bucket(source.bucketName).file(source.filePath);
    const destinationFile = bucket.file(destinationPath);
    await sourceFile.copy(destinationFile);
    const [metadata] = await destinationFile.getMetadata();
    return {
      attachmentId,
      storagePath: destinationPath,
      originalPath: destinationPath,
      viewablePath: destinationPath,
      contentType: metadata.contentType || contentTypeForReport(extension),
      viewableContentType: metadata.contentType || contentTypeForReport(extension),
      sizeBytes: Number(metadata.size || 0),
      sourceStoragePath: inspection.report_storage_path,
      createdAt: now,
      updatedAt: now,
    };
  } catch (error) {
    console.warn("Could not copy master inspection report", {
      tenantId,
      siteId,
      masterInspectionId,
      source: inspection.report_storage_path,
      error,
    });
    return null;
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
    const reportCopy = await copyMasterReportToTenant({
      tenantId,
      siteId: siteRef.id,
      masterInspectionId,
      inspection,
      now,
    });
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
        masterReportStoragePath: inspection.report_storage_path || null,
        ...(reportCopy
          ? {
              tenantReportAttachmentId: reportCopy.attachmentId,
              tenantReportStoragePath: reportCopy.storagePath,
              tenantReportStatus: "available",
            }
          : {}),
        findingCount: asArray(inspection.findings).length,
        importState: isLatestInspection ? "latest" : "historical",
        importedAt: now,
        updatedAt: now,
      },
      options: { merge: true },
    });

    if (reportCopy) {
      writes.push({
        ref: inspectionRef.collection("attachments").doc(reportCopy.attachmentId),
        data: {
          tenantId,
          siteId: siteRef.id,
          inspectionId: masterInspectionId,
          masterInspectionId,
          ownerType: "inspection",
          type: "inspection_report",
          attachmentType: "document",
          displayName: `Inspection report ${inspection.inspection_date || ""}`.trim(),
          contentType: reportCopy.contentType,
          storagePath: reportCopy.storagePath,
          originalPath: reportCopy.originalPath,
          viewablePath: reportCopy.viewablePath,
          viewableContentType: reportCopy.viewableContentType,
          sizeBytes: reportCopy.sizeBytes,
          source: "master_copy",
          sourceStoragePath: reportCopy.sourceStoragePath,
          status: "ready",
          createdAt: now,
          updatedAt: now,
        },
        options: { merge: true },
      });
    }

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

const searchMasterRestaurants = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const query = cleanString(request.data?.query, "Search text", 120);

  if (query.length < 2) {
    throw new HttpsError("invalid-argument", "Enter at least 2 characters.");
  }

  await requireTenantRole(tenantId, auth.uid, siteActionRoles);

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

const linkMasterRestaurantSite = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const masterRestaurantId = cleanString(
    request.data?.masterRestaurantId,
    "Master restaurant ID",
    160,
  );
  const now = admin.firestore.FieldValue.serverTimestamp();

  await requireTenantRole(tenantId, auth.uid, siteActionRoles);

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

const syncLinkedSiteMasterData = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const siteId = cleanString(request.data?.siteId, "Site ID", 160);
  const now = admin.firestore.FieldValue.serverTimestamp();

  await requireTenantRole(tenantId, auth.uid, siteActionRoles);

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

const createSite = onCall({ region }, async (request) => {
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

  await requireTenantRole(tenantId, auth.uid, siteActionRoles);

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

module.exports = {
  searchMasterRestaurants,
  linkMasterRestaurantSite,
  syncLinkedSiteMasterData,
  createSite,
};
