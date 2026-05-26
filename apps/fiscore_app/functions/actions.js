const { onSchedule } = require("firebase-functions/v2/scheduler");
const {
  admin,
  db,
  region,
  safeText,
} = require("./shared/runtime");

const reviewerRoles = new Set(["tenant_owner", "admin", "manager"]);

function memberHasSiteAccess(member, siteId) {
  return member.role === "tenant_owner" ||
    member.role === "admin" ||
    member.siteAccessMode !== "selected" ||
    (Array.isArray(member.siteIds) && member.siteIds.includes(siteId));
}

async function reviewersForSite(tenantId, siteId) {
  const members = await db.collection(`tenants/${tenantId}/members`).get();
  return members.docs
    .filter((doc) => {
      const member = doc.data();
      return member.status === "active" &&
        reviewerRoles.has(member.role) &&
        memberHasSiteAccess(member, siteId);
    })
    .map((doc) => ({ id: doc.id, ...doc.data() }));
}

async function siteName(tenantId, siteId) {
  const siteSnap = await db.doc(`tenants/${tenantId}/sites/${siteId}`).get();
  return safeText(siteSnap.data()?.name, "Restaurant site");
}

function actionId(type, targetId, recipientUserId) {
  return `${type}_${targetId}_${recipientUserId}`;
}

function actionReference(tenantId, type, targetId, recipientUserId) {
  return db.doc(
    `tenants/${tenantId}/actionItems/${actionId(type, targetId, recipientUserId)}`,
  );
}

function violationActionDisplay(violation) {
  const sourceType = safeText(violation.sourceType);
  const sourceLabel = sourceType === "internal_audit"
    ? "Internal check"
    : sourceType === "health_department_inspection"
      ? "Public inspection"
      : null;
  return {
    sourceLabelSnapshot: sourceLabel,
    sourceTitleSnapshot: safeText(violation.sourceTitleSnapshot) || null,
    sourceOccurredAtSnapshot: violation.sourceOccurredAt || null,
    severitySnapshot: safeText(violation.severity) || null,
  };
}

function setOpenAction(batch, {
  tenantId,
  type,
  priority,
  recipientUserId,
  recipientRoleSnapshot = null,
  siteId,
  siteNameSnapshot,
  targetType,
  targetId,
  targetPath,
  title,
  detail,
  sourceLabelSnapshot = null,
  sourceTitleSnapshot = null,
  sourceOccurredAtSnapshot = null,
  severitySnapshot = null,
  dueAt = null,
  dueState = null,
  assignmentSourceSnapshot = null,
  managerVisible = false,
}) {
  const now = admin.firestore.FieldValue.serverTimestamp();
  const ref = actionReference(tenantId, type, targetId, recipientUserId);
  batch.set(ref, {
    tenantId,
    type,
    status: "open",
    priority,
    recipientUserId,
    recipientRoleSnapshot,
    siteId,
    siteNameSnapshot,
    targetType,
    targetId,
    targetPath,
    title,
    detail,
    sourceLabelSnapshot,
    sourceTitleSnapshot,
    sourceOccurredAtSnapshot,
    severitySnapshot,
    dueAt,
    dueState,
    assignmentSourceSnapshot,
    managerVisible,
    dedupeKey: `${type}:${targetId}:${recipientUserId}`,
    readAt: null,
    completedAt: null,
    createdAt: now,
    updatedAt: now,
  }, { merge: true });
  return ref;
}

function completeAction(batch, ref, completionReason) {
  batch.set(ref, {
    status: "completed",
    completionReason,
    completedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

async function completeActionsForTarget(batch, tenantId, targetType, targetId, reason) {
  const snapshot = await db
    .collection(`tenants/${tenantId}/actionItems`)
    .where("targetKey", "==", `${targetType}:${targetId}`)
    .get();
  for (const doc of snapshot.docs) {
    if (doc.data().status === "open") {
      completeAction(batch, doc.ref, reason);
    }
  }
}

function setTargetKey(batch, ref, targetType, targetId) {
  batch.set(ref, {
    targetKey: `${targetType}:${targetId}`,
  }, { merge: true });
}

async function createReviewActions(batch, {
  tenantId,
  siteId,
  violationId,
  violation,
}) {
  const reviewers = await reviewersForSite(tenantId, siteId);
  const currentSiteName = await siteName(tenantId, siteId);
  const display = violationActionDisplay(violation);
  for (const reviewer of reviewers) {
    const ref = setOpenAction(batch, {
      tenantId,
      type: "violation_review",
      priority: "high",
      recipientUserId: reviewer.id,
      recipientRoleSnapshot: reviewer.role,
      siteId,
      siteNameSnapshot: currentSiteName,
      targetType: "violation",
      targetId: violationId,
      targetPath: `tenants/${tenantId}/sites/${siteId}/violations/${violationId}`,
      title: "Review completed fix",
      detail: safeText(violation.title, safeText(violation.displayText, "Violation")),
      ...display,
      managerVisible: true,
    });
    setTargetKey(batch, ref, "violation", violationId);
  }
}

async function createReturnedFixAction(batch, {
  tenantId,
  siteId,
  violationId,
  violation,
  recipientUserId,
}) {
  if (!safeText(recipientUserId)) {
    return;
  }
  const currentSiteName = await siteName(tenantId, siteId);
  const display = violationActionDisplay(violation);
  const ref = setOpenAction(batch, {
    tenantId,
    type: "violation_sent_back",
    priority: "high",
    recipientUserId,
    siteId,
    siteNameSnapshot: currentSiteName,
    targetType: "violation",
    targetId: violationId,
    targetPath: `tenants/${tenantId}/sites/${siteId}/violations/${violationId}`,
    title: "Fix needs an update",
    detail: safeText(violation.title, safeText(violation.displayText, "Violation")),
    ...display,
  });
  setTargetKey(batch, ref, "violation", violationId);
}

async function createResolutionAction(batch, {
  tenantId,
  siteId,
  violationId,
  violation,
  recipientUserId,
}) {
  if (!safeText(recipientUserId)) {
    return;
  }
  const currentSiteName = await siteName(tenantId, siteId);
  const display = violationActionDisplay(violation);
  const ref = setOpenAction(batch, {
    tenantId,
    type: "violation_resolution",
    priority: "high",
    recipientUserId,
    siteId,
    siteNameSnapshot: currentSiteName,
    targetType: "violation",
    targetId: violationId,
    targetPath: `tenants/${tenantId}/sites/${siteId}/violations/${violationId}`,
    title: "Resolve violation",
    detail: safeText(violation.title, safeText(violation.displayText, "Violation")),
    ...display,
  });
  setTargetKey(batch, ref, "violation", violationId);
}

async function createTrainingAction(batch, {
  tenantId,
  assignmentId,
  assignment,
}) {
  const currentSiteName = await siteName(tenantId, assignment.siteId);
  const ref = setOpenAction(batch, {
    tenantId,
    type: "training_completion",
    priority: "normal",
    recipientUserId: assignment.assignedTo,
    siteId: assignment.siteId,
    siteNameSnapshot: currentSiteName,
    targetType: "training_assignment",
    targetId: assignmentId,
    targetPath: `tenants/${tenantId}/trainingAssignments/${assignmentId}`,
    title: "Complete assigned training",
    detail: safeText(assignment.trainingTitleSnapshot, "Training"),
    dueAt: assignment.dueDate,
    managerVisible: true,
  });
  setTargetKey(batch, ref, "training_assignment", assignmentId);
}

async function createAuditAction(batch, {
  tenantId,
  assignmentId,
  assignment,
}) {
  const currentSiteName = await siteName(tenantId, assignment.siteId);
  const isStartedByUser = assignment.assignmentSource === "self_started";
  const isInProgress = assignment.status === "in_progress";
  const ref = setOpenAction(batch, {
    tenantId,
    type: "audit_completion",
    priority: "normal",
    recipientUserId: assignment.assignedTo,
    siteId: assignment.siteId,
    siteNameSnapshot: currentSiteName,
    targetType: "audit_assignment",
    targetId: assignmentId,
    targetPath:
      `tenants/${tenantId}/sites/${assignment.siteId}/auditAssignments/${assignmentId}`,
    title: isInProgress ? "Continue check" : "Complete assigned check",
    detail: safeText(assignment.templateNameSnapshot, "Internal check"),
    dueAt: assignment.dueDate,
    assignmentSourceSnapshot: isStartedByUser ? "self_started" : "assigned",
    managerVisible: true,
  });
  setTargetKey(batch, ref, "audit_assignment", assignmentId);
}

const markOverdueTrainingActions = onSchedule(
  { region, schedule: "every day 06:00", timeZone: "America/New_York" },
  async () => {
    const now = admin.firestore.Timestamp.now();
    const assignments = await db
      .collectionGroup("trainingAssignments")
      .where("dueDate", "<=", now)
      .limit(500)
      .get();
    const batch = db.batch();
    let updated = 0;
    for (const doc of assignments.docs) {
      const assignment = doc.data();
      if (
        assignment.status === "completed" ||
        assignment.status === "cancelled" ||
        !safeText(assignment.assignedTo)
      ) {
        continue;
      }
      const tenantRef = doc.ref.parent.parent;
      if (!tenantRef) {
        continue;
      }
      const ref = actionReference(
        tenantRef.id,
        "training_completion",
        doc.id,
        assignment.assignedTo,
      );
      batch.set(ref, {
        status: "open",
        priority: "high",
        dueState: "overdue",
        title: "Training overdue",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      updated += 1;
    }
    if (updated > 0) {
      await batch.commit();
    }
    console.log(`Marked ${updated} training actions overdue.`);
  },
);

const markOverdueAuditActions = onSchedule(
  { region, schedule: "every day 06:05", timeZone: "America/New_York" },
  async () => {
    const now = admin.firestore.Timestamp.now();
    const assignments = await db
      .collectionGroup("auditAssignments")
      .where("dueDate", "<=", now)
      .limit(500)
      .get();
    const batch = db.batch();
    let updated = 0;
    for (const doc of assignments.docs) {
      const assignment = doc.data();
      if (
        assignment.status === "completed" ||
        assignment.status === "cancelled" ||
        !safeText(assignment.assignedTo)
      ) {
        continue;
      }
      const siteRef = doc.ref.parent.parent;
      const tenantRef = siteRef?.parent.parent;
      if (!siteRef || !tenantRef) {
        continue;
      }
      const ref = actionReference(
        tenantRef.id,
        "audit_completion",
        doc.id,
        assignment.assignedTo,
      );
      batch.set(ref, {
        status: "open",
        priority: "high",
        dueState: "overdue",
        title: assignment.status === "in_progress"
          ? "Finish overdue check"
          : "Complete overdue check",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      updated += 1;
    }
    if (updated > 0) {
      await batch.commit();
    }
    console.log(`Marked ${updated} audit actions overdue.`);
  },
);

module.exports = {
  memberHasSiteAccess,
  reviewersForSite,
  actionReference,
  setOpenAction,
  completeAction,
  completeActionsForTarget,
  createReviewActions,
  createReturnedFixAction,
  createResolutionAction,
  createTrainingAction,
  createAuditAction,
  markOverdueTrainingActions,
  markOverdueAuditActions,
};
