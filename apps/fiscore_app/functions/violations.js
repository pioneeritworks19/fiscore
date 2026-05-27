const { onCall, HttpsError } = require("firebase-functions/v2/https");
const {
  admin,
  db,
  region,
  siteActionRoles,
  requireAuth,
  cleanString,
  requireSiteRole,
  safeText,
} = require("./shared/runtime");
const {
  memberHasSiteAccess,
  completeActionsForTarget,
  createReviewActions,
  createReturnedFixAction,
  createResolutionAction,
} = require("./actions");

const resolutionRoles = ["tenant_owner", "admin", "manager", "auditor", "staff"];

async function violationForAction(tenantId, siteId, violationId) {
  const ref = db.doc(`tenants/${tenantId}/sites/${siteId}/violations/${violationId}`);
  const snapshot = await ref.get();
  if (!snapshot.exists) {
    throw new HttpsError("not-found", "Violation was not found.");
  }
  return { ref, data: snapshot.data() };
}

const submitViolationForReview = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const siteId = cleanString(request.data?.siteId, "Site ID", 160);
  const violationId = cleanString(request.data?.violationId, "Violation ID", 180);
  const actor = await requireSiteRole(tenantId, siteId, auth.uid, resolutionRoles);
  const { ref, data: violation } = await violationForAction(
    tenantId,
    siteId,
    violationId,
  );
  if (!safeText(violation.responseCorrectiveAction)) {
    throw new HttpsError(
      "failed-precondition",
      "Enter what was fixed before submitting for review.",
    );
  }
  if (violation.status === "closed") {
    throw new HttpsError("failed-precondition", "A closed violation cannot be submitted.");
  }
  const assignedTo = safeText(violation.assignedTo);
  if (
    assignedTo &&
    assignedTo !== auth.uid &&
    !siteActionRoles.includes(actor.role)
  ) {
    throw new HttpsError(
      "permission-denied",
      "This resolution is assigned to another teammate.",
    );
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  const batch = db.batch();
  batch.set(ref, {
    status: "pending_review",
    lifecycleStage: "pending_review",
    reviewStatus: "submitted",
    requiresReview: true,
    submittedForReviewAt: now,
    submittedBy: auth.uid,
    submittedByDisplayNameSnapshot: request.auth.token.name || null,
    updatedAt: now,
  }, { merge: true });
  if (violation.status !== "pending_review") {
    const siteUpdate = {
      pendingReviewCountSnapshot: admin.firestore.FieldValue.increment(1),
      updatedAt: now,
    };
    if (!safeText(violation.assignedTo)) {
      siteUpdate.unassignedActiveViolationCountSnapshot =
        admin.firestore.FieldValue.increment(-1);
    }
    batch.set(db.doc(`tenants/${tenantId}/sites/${siteId}`), siteUpdate, { merge: true });
  }
  await completeActionsForTarget(batch, tenantId, "violation", violationId, "resubmitted");
  await createReviewActions(batch, { tenantId, siteId, violationId, violation });
  await batch.commit();
  return { status: "pending_review" };
});

const sendViolationBack = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const siteId = cleanString(request.data?.siteId, "Site ID", 160);
  const violationId = cleanString(request.data?.violationId, "Violation ID", 180);
  const feedback = cleanString(request.data?.feedback, "Feedback", 1000);
  await requireSiteRole(tenantId, siteId, auth.uid, siteActionRoles);
  const { ref, data: violation } = await violationForAction(
    tenantId,
    siteId,
    violationId,
  );
  if (violation.status !== "pending_review") {
    throw new HttpsError("failed-precondition", "Only submitted work can be sent back.");
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  const batch = db.batch();
  batch.set(ref, {
    status: "in_progress",
    lifecycleStage: "in_progress",
    reviewStatus: "needs_work",
    requiresReview: false,
    updatedAt: now,
  }, { merge: true });
  batch.set(ref.collection("threads").doc(), {
    entryType: "comment",
    body: `Review feedback: ${feedback}`,
    mentionedUserIds: [],
    attachmentIds: [],
    statusSnapshot: "in_progress",
    assignmentSnapshot: null,
    createdAt: now,
    createdBy: auth.uid,
    createdByDisplayNameSnapshot: request.auth.token.name || "FiScore reviewer",
    updatedAt: now,
  });
  const siteUpdate = {
    pendingReviewCountSnapshot: admin.firestore.FieldValue.increment(-1),
    updatedAt: now,
  };
  if (!safeText(violation.assignedTo)) {
    siteUpdate.unassignedActiveViolationCountSnapshot =
      admin.firestore.FieldValue.increment(1);
  }
  batch.set(db.doc(`tenants/${tenantId}/sites/${siteId}`), siteUpdate, { merge: true });
  await completeActionsForTarget(batch, tenantId, "violation", violationId, "sent_back");
  await createReturnedFixAction(batch, {
    tenantId,
    siteId,
    violationId,
    violation,
    recipientUserId: safeText(violation.assignedTo, violation.submittedBy),
  });
  await batch.commit();
  return { status: "in_progress" };
});

const closeViolation = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const siteId = cleanString(request.data?.siteId, "Site ID", 160);
  const violationId = cleanString(request.data?.violationId, "Violation ID", 180);
  const closureReason = safeText(
    request.data?.closureReason,
    "Closed after manager review.",
  );
  await requireSiteRole(tenantId, siteId, auth.uid, siteActionRoles);
  const { ref, data: violation } = await violationForAction(
    tenantId,
    siteId,
    violationId,
  );
  if (violation.status !== "pending_review") {
    throw new HttpsError("failed-precondition", "Only submitted work can be closed.");
  }
  const now = admin.firestore.FieldValue.serverTimestamp();
  const batch = db.batch();
  batch.set(ref, {
    status: "closed",
    lifecycleStage: "closed",
    reviewStatus: "closed",
    requiresReview: false,
    closedAt: now,
    closedBy: auth.uid,
    closureReason,
    updatedAt: now,
  }, { merge: true });
  batch.set(db.doc(`tenants/${tenantId}/sites/${siteId}`), {
    openViolationCountSnapshot: admin.firestore.FieldValue.increment(-1),
    pendingReviewCountSnapshot: admin.firestore.FieldValue.increment(-1),
    closedViolationCountSnapshot: admin.firestore.FieldValue.increment(1),
    updatedAt: now,
  }, { merge: true });
  await completeActionsForTarget(batch, tenantId, "violation", violationId, "closed");
  await batch.commit();
  return { status: "closed" };
});

const reopenViolation = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const siteId = cleanString(request.data?.siteId, "Site ID", 160);
  const violationId = cleanString(request.data?.violationId, "Violation ID", 180);
  await requireSiteRole(tenantId, siteId, auth.uid, siteActionRoles);
  const { ref, data: violation } = await violationForAction(
    tenantId,
    siteId,
    violationId,
  );
  if (violation.status !== "closed") {
    throw new HttpsError("failed-precondition", "Only a closed violation can be reopened.");
  }
  const now = admin.firestore.FieldValue.serverTimestamp();
  const batch = db.batch();
  batch.set(ref, {
      status: "open",
      lifecycleStage: "open",
      reviewStatus: "reopened",
      requiresReview: false,
      closedAt: null,
      closedBy: null,
      updatedAt: now,
  }, { merge: true });
  const siteUpdate = {
      openViolationCountSnapshot: admin.firestore.FieldValue.increment(1),
      closedViolationCountSnapshot: admin.firestore.FieldValue.increment(-1),
      updatedAt: now,
  };
  if (!safeText(violation.assignedTo)) {
    siteUpdate.unassignedActiveViolationCountSnapshot =
      admin.firestore.FieldValue.increment(1);
  }
  batch.set(db.doc(`tenants/${tenantId}/sites/${siteId}`), siteUpdate, { merge: true });
  if (safeText(violation.assignedTo)) {
    await createResolutionAction(batch, {
      tenantId,
      siteId,
      violationId,
      violation,
      recipientUserId: violation.assignedTo,
    });
  }
  await batch.commit();
  return { status: "open" };
});

const assignViolation = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const siteId = cleanString(request.data?.siteId, "Site ID", 160);
  const violationId = cleanString(request.data?.violationId, "Violation ID", 180);
  const assignedTo = cleanString(request.data?.assignedTo, "Assignee", 180);
  const actor = await requireSiteRole(tenantId, siteId, auth.uid, siteActionRoles);
  const { ref, data: violation } = await violationForAction(
    tenantId,
    siteId,
    violationId,
  );
  if (violation.status === "closed" || violation.status === "pending_review") {
    throw new HttpsError(
      "failed-precondition",
      "Only open work can be assigned.",
    );
  }
  const memberSnap = await db.doc(`tenants/${tenantId}/members/${assignedTo}`).get();
  if (!memberSnap.exists) {
    throw new HttpsError("not-found", "Team member was not found.");
  }
  const member = memberSnap.data();
  if (member.status !== "active" || !memberHasSiteAccess(member, siteId)) {
    throw new HttpsError(
      "failed-precondition",
      "Choose an active teammate with access to this site.",
    );
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  const previousAssignedTo = safeText(violation.assignedTo);
  const batch = db.batch();
  batch.set(ref, {
    assignedTo,
    assignedToNameSnapshot: safeText(
      member.displayNameSnapshot,
      safeText(member.emailSnapshot, "Team member"),
    ),
    assignedAt: now,
    assignedBy: auth.uid,
    assignedByNameSnapshot: safeText(
      actor.displayNameSnapshot,
      safeText(request.auth.token.name, "FiScore manager"),
    ),
    assignmentStatus: "assigned",
    updatedAt: now,
  }, { merge: true });
  if (!previousAssignedTo) {
    batch.set(db.doc(`tenants/${tenantId}/sites/${siteId}`), {
      unassignedActiveViolationCountSnapshot: admin.firestore.FieldValue.increment(-1),
      updatedAt: now,
    }, { merge: true });
  }
  if (previousAssignedTo) {
    await completeActionsForTarget(
      batch,
      tenantId,
      "violation",
      violationId,
      "reassigned",
    );
  }
  await createResolutionAction(batch, {
    tenantId,
    siteId,
    violationId,
    violation,
    recipientUserId: assignedTo,
  });
  await batch.commit();
  return { assignedTo };
});

const unassignViolation = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const siteId = cleanString(request.data?.siteId, "Site ID", 160);
  const violationId = cleanString(request.data?.violationId, "Violation ID", 180);
  await requireSiteRole(tenantId, siteId, auth.uid, siteActionRoles);
  const { ref, data: violation } = await violationForAction(
    tenantId,
    siteId,
    violationId,
  );
  if (violation.status === "closed" || violation.status === "pending_review") {
    throw new HttpsError(
      "failed-precondition",
      "Only open work can be unassigned.",
    );
  }
  const previousAssignedTo = safeText(violation.assignedTo);
  const now = admin.firestore.FieldValue.serverTimestamp();
  const batch = db.batch();
  batch.set(ref, {
    assignedTo: null,
    assignedToNameSnapshot: null,
    assignmentStatus: "unassigned",
    unassignedAt: now,
    unassignedBy: auth.uid,
    updatedAt: now,
  }, { merge: true });
  if (previousAssignedTo) {
    batch.set(db.doc(`tenants/${tenantId}/sites/${siteId}`), {
      unassignedActiveViolationCountSnapshot: admin.firestore.FieldValue.increment(1),
      updatedAt: now,
    }, { merge: true });
    await completeActionsForTarget(
      batch,
      tenantId,
      "violation",
      violationId,
      "unassigned",
    );
  }
  await batch.commit();
  return { assignedTo: null };
});

module.exports = {
  submitViolationForReview,
  sendViolationBack,
  closeViolation,
  reopenViolation,
  assignViolation,
  unassignViolation,
};
