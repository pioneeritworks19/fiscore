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
  actionReference,
  completeAction,
  createTrainingAction,
} = require("./actions");

function trainingAssignmentData({
  tenantId,
  siteId,
  training,
  assignedTo,
  assignedToName,
  actor,
  dueDate,
  note,
  linkedViolationId,
  linkedViolationTitle,
}) {
  const now = admin.firestore.FieldValue.serverTimestamp();
  return {
    tenantId,
    siteId,
    trainingId: training.id || training.libraryItemId,
    trainingVersion: training.version || training.libraryVersion,
    trainingTitleSnapshot: training.title,
    trainingDescriptionSnapshot: training.description,
    trainingType: training.trainingType || null,
    durationMinutes: training.durationMinutes || null,
    trainingTopicsSnapshot: Array.isArray(training.topicSummaries)
      ? training.topicSummaries
      : [],
    trainingSectionsSnapshot: Array.isArray(training.sections) ? training.sections : [],
    trainingMediaAssetsSnapshot: training.mediaAssets || {},
    quickCheckQuestionsSnapshot: Array.isArray(training.quickCheckQuestions)
      ? training.quickCheckQuestions
      : [],
    hasQuickCheckSnapshot: training.hasQuickCheck === true,
    linkedRiskArea: training.riskArea || null,
    assignedTo,
    assignedToNameSnapshot: assignedToName,
    assignedBy: actor.uid,
    assignedByNameSnapshot: actor.name,
    dueDate,
    assignmentNote: note || "",
    linkedViolationId: linkedViolationId || null,
    linkedViolationTitleSnapshot: linkedViolationTitle || null,
    status: "assigned",
    progressPercent: 0,
    createdAt: now,
    updatedAt: now,
  };
}

const assignTraining = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const siteId = cleanString(request.data?.siteId, "Site ID", 160);
  const trainingId = cleanString(request.data?.trainingId, "Training ID", 160);
  const assignees = request.data?.assignees;
  if (!assignees || typeof assignees !== "object" || Array.isArray(assignees)) {
    throw new HttpsError("invalid-argument", "Choose at least one teammate.");
  }
  const assigneeEntries = Object.entries(assignees);
  if (assigneeEntries.length === 0 || assigneeEntries.length > 50) {
    throw new HttpsError("invalid-argument", "Choose at least one teammate.");
  }
  const actorMember = await requireSiteRole(tenantId, siteId, auth.uid, siteActionRoles);
  const trainingSnap = await db.doc(`tenants/${tenantId}/trainings/${trainingId}`).get();
  if (!trainingSnap.exists || trainingSnap.data().status !== "active") {
    throw new HttpsError("not-found", "Training item was not found.");
  }
  const training = { id: trainingSnap.id, ...trainingSnap.data() };
  const dueDateValue = request.data?.dueDate;
  const dueDate = dueDateValue && typeof dueDateValue === "string"
    ? admin.firestore.Timestamp.fromDate(new Date(dueDateValue))
    : null;
  if (!dueDate || Number.isNaN(dueDate.toDate().valueOf())) {
    throw new HttpsError("invalid-argument", "Choose a valid due date.");
  }
  const batch = db.batch();
  const assignmentIds = [];
  for (const [userId, displayNameValue] of assigneeEntries) {
    const memberSnap = await db.doc(`tenants/${tenantId}/members/${userId}`).get();
    const member = memberSnap.data();
    if (!memberSnap.exists || member.status !== "active" || !memberHasSiteAccess(member, siteId)) {
      throw new HttpsError(
        "failed-precondition",
        "Every assigned teammate must have access to this site.",
      );
    }
    const assignmentRef = db.collection(`tenants/${tenantId}/trainingAssignments`).doc();
    const assignment = trainingAssignmentData({
      tenantId,
      siteId,
      training,
      assignedTo: userId,
      assignedToName: safeText(displayNameValue, member.displayNameSnapshot || "Team member"),
      actor: {
        uid: auth.uid,
        name: actorMember.displayNameSnapshot || auth.token.name || "FiScore manager",
      },
      dueDate,
      note: safeText(request.data?.note, ""),
      linkedViolationId: safeText(request.data?.linkedViolationId),
      linkedViolationTitle: safeText(request.data?.linkedViolationTitle),
    });
    batch.set(assignmentRef, assignment);
    await createTrainingAction(batch, {
      tenantId,
      assignmentId: assignmentRef.id,
      assignment,
    });
    assignmentIds.push(assignmentRef.id);
  }
  await batch.commit();
  return { assignmentIds };
});

const cancelTrainingAssignment = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const assignmentId = cleanString(request.data?.assignmentId, "Assignment ID", 180);
  const assignmentRef = db.doc(`tenants/${tenantId}/trainingAssignments/${assignmentId}`);
  const snapshot = await assignmentRef.get();
  if (!snapshot.exists) {
    throw new HttpsError("not-found", "Training assignment was not found.");
  }
  const assignment = snapshot.data();
  await requireSiteRole(tenantId, assignment.siteId, auth.uid, siteActionRoles);
  if (assignment.status === "completed" || assignment.status === "cancelled") {
    throw new HttpsError("failed-precondition", "This assignment is already finished.");
  }
  const batch = db.batch();
  batch.set(assignmentRef, {
    status: "cancelled",
    cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
    cancelledBy: auth.uid,
    cancelledByNameSnapshot: auth.token.name || "FiScore manager",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  completeAction(
    batch,
    actionReference(tenantId, "training_completion", assignmentId, assignment.assignedTo),
    "cancelled",
  );
  await batch.commit();
  return { status: "cancelled" };
});

const completeTrainingAssignment = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const assignmentId = cleanString(request.data?.assignmentId, "Assignment ID", 180);
  const assignmentRef = db.doc(`tenants/${tenantId}/trainingAssignments/${assignmentId}`);
  const snapshot = await assignmentRef.get();
  if (!snapshot.exists) {
    throw new HttpsError("not-found", "Training assignment was not found.");
  }
  const assignment = snapshot.data();
  if (assignment.assignedTo !== auth.uid) {
    throw new HttpsError("permission-denied", "Only the assigned teammate can complete training.");
  }
  if (assignment.status === "cancelled") {
    throw new HttpsError("failed-precondition", "This assignment was cancelled.");
  }
  const completionSummary = request.data?.completionSummary;
  if (!completionSummary || typeof completionSummary !== "object") {
    throw new HttpsError("invalid-argument", "Training completion summary is required.");
  }
  const batch = db.batch();
  batch.set(assignmentRef, {
    status: "completed",
    progressPercent: 100,
    incorrectAnswerCount: Number(request.data?.incorrectAnswerCount || 0),
    quickCheckCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
    completedTopicCount: Number(request.data?.completedTopicCount || 0),
    completionSummarySnapshot: completionSummary,
    completedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  completeAction(
    batch,
    actionReference(tenantId, "training_completion", assignmentId, auth.uid),
    "completed",
  );
  await batch.commit();
  return { status: "completed" };
});

module.exports = {
  assignTraining,
  cancelTrainingAssignment,
  completeTrainingAssignment,
};
