const { onCall, HttpsError } = require("firebase-functions/v2/https");
const {
  admin,
  db,
  storageBucket,
  region,
  internalAuditRoles,
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
  createAuditAction,
} = require("./actions");

const auditParticipantRoles = [
  "tenant_owner",
  "admin",
  "manager",
  "auditor",
  "staff",
];

function templateQuestions(template) {
  return template.sections.flatMap((section) =>
    section.questions.map((question, index) => ({
      ...question,
      sectionId: section.id,
      sectionTitle: section.title,
      displayOrder: index,
    })),
  );
}

const createInternalAudit = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const siteId = cleanString(request.data?.siteId, "Site ID", 160);
  const assignmentId = safeText(request.data?.assignmentId);
  const templateId = assignmentId
    ? null
    : cleanString(request.data?.templateId, "Template ID", 120);
  const member = await requireSiteRole(
    tenantId,
    siteId,
    auth.uid,
    assignmentId ? auditParticipantRoles : internalAuditRoles,
  );
  const siteRef = db.doc(`tenants/${tenantId}/sites/${siteId}`);
  const siteSnap = await siteRef.get();
  if (!siteSnap.exists || siteSnap.data().status !== "active") {
    throw new HttpsError("not-found", "Active site was not found.");
  }
  let template;
  let assignmentRef = null;
  let assignment = null;
  if (assignmentId) {
    assignmentRef = siteRef.collection("auditAssignments").doc(assignmentId);
    const assignmentSnap = await assignmentRef.get();
    if (!assignmentSnap.exists) {
      throw new HttpsError("not-found", "Assigned check was not found.");
    }
    assignment = assignmentSnap.data();
    if (assignment.assignedTo !== auth.uid) {
      throw new HttpsError(
        "permission-denied",
        "Only the assigned teammate can start this check.",
      );
    }
    if (assignment.status === "cancelled" || assignment.status === "completed") {
      throw new HttpsError(
        "failed-precondition",
        "This assigned check is already finished.",
      );
    }
    if (assignment.status === "in_progress" && safeText(assignment.auditId)) {
      return { auditId: assignment.auditId };
    }
    template = assignment.templateSnapshot;
  } else {
    const templateSnap = await db
      .doc(`tenants/${tenantId}/checklistTemplates/${templateId}`)
      .get();
    if (!templateSnap.exists) {
      throw new HttpsError("not-found", "Checklist template was not found.");
    }
    template = templateSnap.data();
  }
  if (
    template.status !== "active" ||
    template.isActive === false ||
    !Array.isArray(template.sections)
  ) {
    throw new HttpsError(
      "failed-precondition",
      "This checklist is not available to start.",
    );
  }
  const now = admin.firestore.FieldValue.serverTimestamp();
  const auditRef = siteRef.collection("audits").doc();
  if (!assignmentId) {
    assignmentRef = siteRef.collection("auditAssignments").doc();
    assignment = {
      tenantId,
      siteId,
      templateId,
      templateVersion: template.version,
      templateNameSnapshot: template.name,
      templateSnapshot: template,
      assignedTo: auth.uid,
      assignedToNameSnapshot: safeText(
        member.displayNameSnapshot,
        safeText(auth.token.name, "Team member"),
      ),
      assignedBy: auth.uid,
      assignedByNameSnapshot: safeText(
        member.displayNameSnapshot,
        safeText(auth.token.name, "Team member"),
      ),
      assignmentSource: "self_started",
      dueDate: null,
      assignmentNote: "",
      status: "in_progress",
      auditId: auditRef.id,
      startedAt: now,
      createdAt: now,
      updatedAt: now,
    };
  }
  const batch = db.batch();
  batch.set(auditRef, {
    tenantId,
    siteId,
    type: "internal_audit",
    status: "in_progress",
    origin: assignmentId ? "assigned" : "self_started",
    auditAssignmentId: assignmentRef?.id || null,
    assignedTo: assignment?.assignedTo || null,
    assignedToNameSnapshot: assignment?.assignedToNameSnapshot || null,
    templateId: template.id,
    templateVersion: template.version,
    templateNameSnapshot: template.name,
    templateSnapshot: template,
    totalQuestionCount: templateQuestions(template).length,
    answeredQuestionCount: 0,
    violationCount: 0,
    createdViolationIds: [],
    startedAt: now,
    startedBy: auth.uid,
    startedByDisplayNameSnapshot:
      member.displayNameSnapshot || auth.token.name || null,
    createdAt: now,
    updatedAt: now,
  });
  if (assignmentId && assignmentRef) {
    batch.set(assignmentRef, {
      status: "in_progress",
      auditId: auditRef.id,
      startedAt: now,
      updatedAt: now,
    }, { merge: true });
    batch.set(
      actionReference(tenantId, "audit_completion", assignmentId, auth.uid),
      {
        title: "Continue check",
        updatedAt: now,
      },
      { merge: true },
    );
  } else if (assignmentRef && assignment) {
    batch.set(assignmentRef, assignment);
    await createAuditAction(batch, {
      tenantId,
      assignmentId: assignmentRef.id,
      assignment,
    });
  }
  await batch.commit();
  return { auditId: auditRef.id };
});

const assignInternalAudit = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const siteId = cleanString(request.data?.siteId, "Site ID", 160);
  const templateId = cleanString(request.data?.templateId, "Template ID", 120);
  const assignedTo = cleanString(request.data?.assignedTo, "Assignee", 180);
  const actor = await requireSiteRole(tenantId, siteId, auth.uid, siteActionRoles);
  const templateSnap = await db.doc(
    `tenants/${tenantId}/checklistTemplates/${templateId}`,
  ).get();
  if (!templateSnap.exists || templateSnap.data().status !== "active") {
    throw new HttpsError("not-found", "Checklist template was not found.");
  }
  const memberSnap = await db.doc(`tenants/${tenantId}/members/${assignedTo}`).get();
  if (!memberSnap.exists) {
    throw new HttpsError("not-found", "Team member was not found.");
  }
  const assignee = memberSnap.data();
  if (assignee.status !== "active" || !memberHasSiteAccess(assignee, siteId)) {
    throw new HttpsError(
      "failed-precondition",
      "Choose an active teammate with access to this site.",
    );
  }
  const dueDateValue = request.data?.dueDate;
  const dueDate = dueDateValue && typeof dueDateValue === "string"
    ? admin.firestore.Timestamp.fromDate(new Date(dueDateValue))
    : null;
  if (!dueDate || Number.isNaN(dueDate.toDate().valueOf())) {
    throw new HttpsError("invalid-argument", "Choose a valid due date.");
  }
  const template = templateSnap.data();
  const now = admin.firestore.FieldValue.serverTimestamp();
  const assignmentRef = db
    .doc(`tenants/${tenantId}/sites/${siteId}`)
    .collection("auditAssignments")
    .doc();
  const assignment = {
    tenantId,
    siteId,
    templateId,
    templateVersion: template.version,
    templateNameSnapshot: template.name,
    templateSnapshot: template,
    assignedTo,
    assignedToNameSnapshot: safeText(
      assignee.displayNameSnapshot,
      safeText(assignee.emailSnapshot, "Team member"),
    ),
    assignedBy: auth.uid,
    assignedByNameSnapshot: safeText(
      actor.displayNameSnapshot,
      safeText(auth.token.name, "FiScore manager"),
    ),
    assignmentSource: "assigned",
    dueDate,
    assignmentNote: safeText(request.data?.note, ""),
    status: "assigned",
    auditId: null,
    createdAt: now,
    updatedAt: now,
  };
  const batch = db.batch();
  batch.set(assignmentRef, assignment);
  await createAuditAction(batch, {
    tenantId,
    assignmentId: assignmentRef.id,
    assignment,
  });
  await batch.commit();
  return { assignmentId: assignmentRef.id };
});

const reassignInternalAudit = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const siteId = cleanString(request.data?.siteId, "Site ID", 160);
  const assignmentId = cleanString(request.data?.assignmentId, "Assignment ID", 180);
  const assignedTo = cleanString(request.data?.assignedTo, "Assignee", 180);
  await requireSiteRole(tenantId, siteId, auth.uid, siteActionRoles);
  const assignmentRef = db.doc(
    `tenants/${tenantId}/sites/${siteId}/auditAssignments/${assignmentId}`,
  );
  const assignmentSnap = await assignmentRef.get();
  if (!assignmentSnap.exists) {
    throw new HttpsError("not-found", "Assigned check was not found.");
  }
  const assignment = assignmentSnap.data();
  if (assignment.status === "completed" || assignment.status === "cancelled") {
    throw new HttpsError("failed-precondition", "This check is already finished.");
  }
  const memberSnap = await db.doc(`tenants/${tenantId}/members/${assignedTo}`).get();
  const member = memberSnap.data();
  if (!memberSnap.exists || member.status !== "active" ||
      !memberHasSiteAccess(member, siteId)) {
    throw new HttpsError(
      "failed-precondition",
      "Choose an active teammate with access to this site.",
    );
  }
  const oldAssignee = assignment.assignedTo;
  const assignedToNameSnapshot = safeText(
    member.displayNameSnapshot,
    safeText(member.emailSnapshot, "Team member"),
  );
  const now = admin.firestore.FieldValue.serverTimestamp();
  const updatedAssignment = {
    ...assignment,
    assignedTo,
    assignedToNameSnapshot,
    assignmentSource: "assigned",
  };
  const batch = db.batch();
  batch.set(assignmentRef, {
    assignedTo,
    assignedToNameSnapshot,
    assignmentSource: "assigned",
    reassignedAt: now,
    reassignedBy: auth.uid,
    updatedAt: now,
  }, { merge: true });
  if (safeText(assignment.auditId)) {
    batch.set(
      db.doc(`tenants/${tenantId}/sites/${siteId}/audits/${assignment.auditId}`),
      {
        assignedTo,
        assignedToNameSnapshot,
        updatedAt: now,
      },
      { merge: true },
    );
  }
  completeAction(
    batch,
    actionReference(tenantId, "audit_completion", assignmentId, oldAssignee),
    "reassigned",
  );
  await createAuditAction(batch, {
    tenantId,
    assignmentId,
    assignment: updatedAssignment,
  });
  await batch.commit();
  return { assignedTo };
});

const cancelInternalAuditAssignment = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const siteId = cleanString(request.data?.siteId, "Site ID", 160);
  const assignmentId = cleanString(request.data?.assignmentId, "Assignment ID", 180);
  const assignmentRef = db.doc(
    `tenants/${tenantId}/sites/${siteId}/auditAssignments/${assignmentId}`,
  );
  const assignmentSnap = await assignmentRef.get();
  if (!assignmentSnap.exists) {
    throw new HttpsError("not-found", "Assigned check was not found.");
  }
  const assignment = assignmentSnap.data();
  const isOwnSelfStartedCheck =
    assignment.assignmentSource === "self_started" &&
    assignment.assignedTo === auth.uid;
  if (!isOwnSelfStartedCheck) {
    await requireSiteRole(tenantId, siteId, auth.uid, siteActionRoles);
  } else {
    await requireSiteRole(tenantId, siteId, auth.uid, auditParticipantRoles);
  }
  if (assignment.status === "completed" || assignment.status === "cancelled") {
    throw new HttpsError("failed-precondition", "This check is already finished.");
  }
  const batch = db.batch();
  batch.set(assignmentRef, {
    status: "cancelled",
    cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
    cancelledBy: auth.uid,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  if (safeText(assignment.auditId)) {
    batch.set(
      db.doc(`tenants/${tenantId}/sites/${siteId}/audits/${assignment.auditId}`),
      {
        status: "cancelled",
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        cancelledBy: auth.uid,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
  completeAction(
    batch,
    actionReference(tenantId, "audit_completion", assignmentId, assignment.assignedTo),
    "cancelled",
  );
  await batch.commit();
  return { status: "cancelled" };
});

const submitInternalAudit = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const siteId = cleanString(request.data?.siteId, "Site ID", 160);
  const auditId = cleanString(request.data?.auditId, "Audit ID", 160);
  await requireSiteRole(tenantId, siteId, auth.uid, auditParticipantRoles);

  const auditRef = db.doc(`tenants/${tenantId}/sites/${siteId}/audits/${auditId}`);
  const auditSnap = await auditRef.get();
  if (!auditSnap.exists) {
    throw new HttpsError("not-found", "Audit was not found.");
  }
  const audit = auditSnap.data();
  if (audit.status !== "in_progress") {
    throw new HttpsError(
      "failed-precondition",
      "Only an in-progress audit can be submitted.",
    );
  }
  if (
    (audit.auditAssignmentId && audit.assignedTo !== auth.uid) ||
    (!audit.auditAssignmentId && audit.startedBy !== auth.uid)
  ) {
    throw new HttpsError(
      "permission-denied",
      "Only the person who started this audit can submit it.",
    );
  }
  const template = audit.templateSnapshot;
  if (!template || !Array.isArray(template.sections)) {
    throw new HttpsError(
      "failed-precondition",
      "This audit is missing its checklist snapshot.",
    );
  }
  const questions = templateQuestions(template);
  const responseSnap = await auditRef.collection("responses").get();
  const responses = new Map(responseSnap.docs.map((doc) => [doc.id, doc.data()]));
  const unanswered = questions.filter((question) => {
    const answer = responses.get(question.id)?.answer;
    return !["pass", "needs_attention", "not_applicable"].includes(answer);
  });
  if (unanswered.length > 0) {
    throw new HttpsError(
      "failed-precondition",
      "Answer all checklist items before submitting.",
    );
  }
  const missingNotes = questions.filter((question) => {
    const response = responses.get(question.id);
    return response?.answer === "needs_attention" &&
      question.requiresNoteOnFail &&
      !safeText(response.note);
  });
  if (missingNotes.length > 0) {
    throw new HttpsError(
      "failed-precondition",
      "Add an observation for each item needing attention.",
    );
  }

  const applicable = questions.filter(
    (question) => responses.get(question.id).answer !== "not_applicable",
  );
  const passing = applicable.filter(
    (question) => responses.get(question.id).answer === "pass",
  );
  const findings = questions.filter((question) => {
    const response = responses.get(question.id);
    return response.answer === "needs_attention" && question.createsViolation;
  });
  const scorePercentage = applicable.length === 0
    ? 100
    : Math.round((passing.length / applicable.length) * 100);
  const hasCritical = findings.some(
    (question) => question.failSeverity === "critical",
  );
  const resultLabel = hasCritical
    ? "Critical violation"
    : scorePercentage >= 90
      ? "Good"
      : "Needs attention";
  const now = admin.firestore.FieldValue.serverTimestamp();
  const bucket = storageBucket();
  const batch = db.batch();
  const createdViolationIds = [];
  for (const question of findings) {
    const response = responses.get(question.id);
    const violationRef = db.doc(
      `tenants/${tenantId}/sites/${siteId}/violations/audit_${auditId}_${question.id}`,
    );
    createdViolationIds.push(violationRef.id);
    batch.set(violationRef, {
      tenantId,
      siteId,
      sourceType: "internal_audit",
      sourceReferenceId: auditId,
      sourceQuestionResponseId: question.id,
      auditId,
      sourceTitleSnapshot: audit.templateNameSnapshot,
      sourceOccurredAt: now,
      checklistTemplateId: template.id,
      checklistVersion: template.version,
      sectionLabel: question.sectionTitle,
      questionLabel: question.prompt,
      responseLabel: "Needs attention",
      title: question.prompt,
      summaryText: response.note,
      description: response.note,
      displayText: question.prompt,
      severity: question.failSeverity,
      priority: question.failSeverity,
      violationType: "internal_audit_finding",
      status: "open",
      lifecycleStage: "open",
      reviewStatus: "not_submitted",
      requiresReview: false,
      currentResponseType: null,
      identifiedAt: now,
      identifiedBy: auth.uid,
      auditorComments: response.note,
      createdAt: now,
      updatedAt: now,
    }, { merge: true });

    const evidenceSnap = await auditRef
      .collection("attachments")
      .where("responseId", "==", question.id)
      .get();
    for (const attachmentDoc of evidenceSnap.docs) {
      const evidence = attachmentDoc.data();
      const sourcePath = safeText(evidence.storagePath);
      if (!sourcePath) {
        continue;
      }
      const destinationPath =
        `tenants/${tenantId}/sites/${siteId}/violations/${violationRef.id}` +
        `/attachments/${attachmentDoc.id}/image.jpg`;
      try {
        await bucket.file(sourcePath).copy(bucket.file(destinationPath));
        batch.set(violationRef.collection("attachments").doc(attachmentDoc.id), {
          ...evidence,
          tenantId,
          siteId,
          violationId: violationRef.id,
          ownerType: "violation",
          linkedContext: "fix",
          sourceAuditId: auditId,
          sourceAuditResponseId: question.id,
          storagePath: destinationPath,
          originalPath: destinationPath,
          compressedPath: destinationPath,
          thumbnailPath: destinationPath,
          status: "ready",
          createdAt: now,
          updatedAt: now,
        }, { merge: true });
      } catch (error) {
        console.warn("Could not copy internal audit evidence to violation", {
          tenantId,
          siteId,
          auditId,
          violationId: violationRef.id,
          attachmentId: attachmentDoc.id,
          error,
        });
      }
    }
  }
  batch.set(auditRef, {
    status: "completed",
    submittedAt: now,
    submittedBy: auth.uid,
    completedAt: now,
    completedBy: auth.uid,
    scorePercentage,
    resultLabel,
    violationCount: findings.length,
    answeredQuestionCount: questions.length,
    createdViolationIds,
    updatedAt: now,
  }, { merge: true });
  if (safeText(audit.auditAssignmentId)) {
    const assignmentRef = db.doc(
      `tenants/${tenantId}/sites/${siteId}/auditAssignments/${audit.auditAssignmentId}`,
    );
    batch.set(assignmentRef, {
      status: "completed",
      auditId,
      completedAt: now,
      completedBy: auth.uid,
      updatedAt: now,
    }, { merge: true });
    completeAction(
      batch,
      actionReference(
        tenantId,
        "audit_completion",
        audit.auditAssignmentId,
        audit.assignedTo,
      ),
      "completed",
    );
  }
  batch.set(db.doc(`tenants/${tenantId}/sites/${siteId}`), {
    internalAuditCountSnapshot: admin.firestore.FieldValue.increment(1),
    openViolationCountSnapshot:
      admin.firestore.FieldValue.increment(findings.length),
    updatedAt: now,
  }, { merge: true });
  await batch.commit();

  return {
    auditId,
    scorePercentage,
    resultLabel,
    violationCount: findings.length,
    createdViolationIds,
  };
});

module.exports = {
  createInternalAudit,
  assignInternalAudit,
  reassignInternalAudit,
  cancelInternalAuditAssignment,
  submitInternalAudit,
};
