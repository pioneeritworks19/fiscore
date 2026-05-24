const { onCall, HttpsError } = require("firebase-functions/v2/https");
const {
  admin,
  db,
  bucket,
  region,
  internalAuditRoles,
  requireAuth,
  cleanString,
  requireSiteRole,
  safeText,
} = require("./shared/runtime");

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
  const templateId = cleanString(request.data?.templateId, "Template ID", 120);
  const member = await requireSiteRole(
    tenantId,
    siteId,
    auth.uid,
    internalAuditRoles,
  );
  const siteRef = db.doc(`tenants/${tenantId}/sites/${siteId}`);
  const siteSnap = await siteRef.get();
  if (!siteSnap.exists || siteSnap.data().status !== "active") {
    throw new HttpsError("not-found", "Active site was not found.");
  }
  const templateSnap = await db
    .doc(`tenants/${tenantId}/checklistTemplates/${templateId}`)
    .get();
  if (!templateSnap.exists) {
    throw new HttpsError("not-found", "Checklist template was not found.");
  }
  const template = templateSnap.data();
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
  await auditRef.set({
    tenantId,
    siteId,
    type: "internal_audit",
    status: "in_progress",
    origin: "ad_hoc",
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
  return { auditId: auditRef.id };
});

const submitInternalAudit = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const siteId = cleanString(request.data?.siteId, "Site ID", 160);
  const auditId = cleanString(request.data?.auditId, "Audit ID", 160);
  await requireSiteRole(tenantId, siteId, auth.uid, internalAuditRoles);

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
  if (audit.startedBy !== auth.uid) {
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
  submitInternalAudit,
};
