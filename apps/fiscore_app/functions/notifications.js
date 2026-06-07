const crypto = require("crypto");
const { HttpsError, onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const {
  admin,
  db,
  region,
  safeText,
} = require("./shared/runtime");

const resendApiKey = defineSecret("RESEND_API_KEY");
const resendWebhookSecret = defineSecret("RESEND_WEBHOOK_SECRET");
const emailSecrets = [resendApiKey];
const resendWebhookSecrets = [resendWebhookSecret];

const supportedLocales = new Set(["en", "es"]);
const requiredEmailEvents = new Set([
  "passwordless_sign_in_link",
  "team_invite_created",
  "team_invite_resent",
  "workspace_created",
  "signed_in_no_workspace",
  "workspace_has_no_site",
]);
const emailEnabledEvents = new Set(requiredEmailEvents);

const templates = {
  team_invite_created: {
    en: {
      subject: "You are invited to FiScore",
      text: [
        "FiScore on behalf of {{tenantName}}",
        "",
        "{{inviterName}} invited you to join {{tenantName}} as {{roleLabel}}.",
        "{{siteContext}}",
        "",
        "Join workspace: {{actionUrl}}",
      ].join("\n"),
      html: [
        "<p><strong>FiScore</strong> on behalf of <strong>{{tenantName}}</strong></p>",
        "<p>{{inviterName}} invited you to join {{tenantName}} as {{roleLabel}}.</p>",
        "<p>{{siteContext}}</p>",
        "<p><a href=\"{{actionUrl}}\">Join workspace</a></p>",
      ].join(""),
    },
    es: {
      subject: "Te invitaron a FiScore",
      text: [
        "FiScore en nombre de {{tenantName}}",
        "",
        "{{inviterName}} te invito a unirte a {{tenantName}} como {{roleLabel}}.",
        "{{siteContext}}",
        "",
        "Unirse al espacio: {{actionUrl}}",
      ].join("\n"),
      html: [
        "<p><strong>FiScore</strong> en nombre de <strong>{{tenantName}}</strong></p>",
        "<p>{{inviterName}} te invito a unirte a {{tenantName}} como {{roleLabel}}.</p>",
        "<p>{{siteContext}}</p>",
        "<p><a href=\"{{actionUrl}}\">Unirse al espacio</a></p>",
      ].join(""),
    },
  },
  team_invite_resent: {
    en: {
      subject: "Your FiScore invitation link",
      text: [
        "FiScore on behalf of {{tenantName}}",
        "",
        "Here is a fresh link to join {{tenantName}} as {{roleLabel}}.",
        "{{siteContext}}",
        "",
        "Join workspace: {{actionUrl}}",
      ].join("\n"),
      html: [
        "<p><strong>FiScore</strong> on behalf of <strong>{{tenantName}}</strong></p>",
        "<p>Here is a fresh link to join {{tenantName}} as {{roleLabel}}.</p>",
        "<p>{{siteContext}}</p>",
        "<p><a href=\"{{actionUrl}}\">Join workspace</a></p>",
      ].join(""),
    },
    es: {
      subject: "Tu enlace de invitacion de FiScore",
      text: [
        "FiScore en nombre de {{tenantName}}",
        "",
        "Aqui tienes un nuevo enlace para unirte a {{tenantName}} como {{roleLabel}}.",
        "{{siteContext}}",
        "",
        "Unirse al espacio: {{actionUrl}}",
      ].join("\n"),
      html: [
        "<p><strong>FiScore</strong> en nombre de <strong>{{tenantName}}</strong></p>",
        "<p>Aqui tienes un nuevo enlace para unirte a {{tenantName}} como {{roleLabel}}.</p>",
        "<p>{{siteContext}}</p>",
        "<p><a href=\"{{actionUrl}}\">Unirse al espacio</a></p>",
      ].join(""),
    },
  },
  workspace_created: {
    en: {
      subject: "Your FiScore workspace is ready",
      text: [
        "Your FiScore workspace {{tenantName}} is ready.",
        "",
        "Next, add or link your first restaurant so FiScore can help you review inspections, run checks, and manage corrective work.",
        "",
        "Open FiScore: {{appUrl}}",
        "Help and product resources: {{websiteUrl}}",
        "Admin console: {{adminUrl}}",
      ].join("\n"),
      html: [
        "<p>Your FiScore workspace <strong>{{tenantName}}</strong> is ready.</p>",
        "<p>Next, add or link your first restaurant so FiScore can help you review inspections, run checks, and manage corrective work.</p>",
        "<p><a href=\"{{appUrl}}\">Open FiScore</a></p>",
        "<p>Help and product resources: <a href=\"{{websiteUrl}}\">FiScore website</a></p>",
        "<p>Admin console: <a href=\"{{adminUrl}}\">Open admin console</a></p>",
      ].join(""),
    },
    es: {
      subject: "Tu espacio de FiScore esta listo",
      text: [
        "Tu espacio de FiScore {{tenantName}} esta listo.",
        "",
        "Luego, agrega o vincula tu primer restaurante para que FiScore te ayude a revisar inspecciones, hacer controles y manejar trabajos correctivos.",
        "",
        "Abrir FiScore: {{appUrl}}",
        "Ayuda y recursos: {{websiteUrl}}",
        "Consola de administracion: {{adminUrl}}",
      ].join("\n"),
      html: [
        "<p>Tu espacio de FiScore <strong>{{tenantName}}</strong> esta listo.</p>",
        "<p>Luego, agrega o vincula tu primer restaurante para que FiScore te ayude a revisar inspecciones, hacer controles y manejar trabajos correctivos.</p>",
        "<p><a href=\"{{appUrl}}\">Abrir FiScore</a></p>",
        "<p>Ayuda y recursos: <a href=\"{{websiteUrl}}\">Sitio web de FiScore</a></p>",
        "<p>Consola de administracion: <a href=\"{{adminUrl}}\">Abrir consola</a></p>",
      ].join(""),
    },
  },
  signed_in_no_workspace: {
    en: {
      subject: "Finish setting up FiScore",
      text: "Create your FiScore workspace to start managing restaurant food safety work: {{appUrl}}",
      html: "<p>Create your FiScore workspace to start managing restaurant food safety work.</p><p><a href=\"{{appUrl}}\">Continue setup</a></p>",
    },
    es: {
      subject: "Termina de configurar FiScore",
      text: "Crea tu espacio de FiScore para empezar a manejar el trabajo de seguridad alimentaria: {{appUrl}}",
      html: "<p>Crea tu espacio de FiScore para empezar a manejar el trabajo de seguridad alimentaria.</p><p><a href=\"{{appUrl}}\">Continuar configuracion</a></p>",
    },
  },
  workspace_has_no_site: {
    en: {
      subject: "Add your first restaurant in FiScore",
      text: "FiScore on behalf of {{tenantName}}\n\nAdd or link your first restaurant so your workspace can start showing useful work: {{appUrl}}",
      html: "<p><strong>FiScore</strong> on behalf of <strong>{{tenantName}}</strong></p><p>Add or link your first restaurant so your workspace can start showing useful work.</p><p><a href=\"{{appUrl}}\">Add restaurant</a></p>",
    },
    es: {
      subject: "Agrega tu primer restaurante en FiScore",
      text: "FiScore en nombre de {{tenantName}}\n\nAgrega o vincula tu primer restaurante para que tu espacio empiece a mostrar trabajo util: {{appUrl}}",
      html: "<p><strong>FiScore</strong> en nombre de <strong>{{tenantName}}</strong></p><p>Agrega o vincula tu primer restaurante para que tu espacio empiece a mostrar trabajo util.</p><p><a href=\"{{appUrl}}\">Agregar restaurante</a></p>",
    },
  },
  passwordless_sign_in_link: {
    en: {
      subject: "Your FiScore sign-in link",
      text: [
        "Use this secure link to sign in to FiScore:",
        "",
        "{{actionUrl}}",
        "",
        "If you did not request this link, you can ignore this email.",
      ].join("\n"),
      html: [
        "<p>Use this secure link to sign in to FiScore:</p>",
        "<p><a href=\"{{actionUrl}}\">Sign in to FiScore</a></p>",
        "<p>If you did not request this link, you can ignore this email.</p>",
      ].join(""),
    },
    es: {
      subject: "Tu enlace de acceso a FiScore",
      text: [
        "Usa este enlace seguro para acceder a FiScore:",
        "",
        "{{actionUrl}}",
        "",
        "Si no solicitaste este enlace, puedes ignorar este email.",
      ].join("\n"),
      html: [
        "<p>Usa este enlace seguro para acceder a FiScore:</p>",
        "<p><a href=\"{{actionUrl}}\">Acceder a FiScore</a></p>",
        "<p>Si no solicitaste este enlace, puedes ignorar este email.</p>",
      ].join(""),
    },
  },
};

function appUrl() {
  return process.env.FISCORE_APP_URL || "https://fiscore-dev.web.app";
}

function emailProvider() {
  return safeText(process.env.FISCORE_EMAIL_PROVIDER, "noop").toLowerCase();
}

function emailFrom() {
  return safeText(
    process.env.FISCORE_EMAIL_FROM,
    "FiScore <notifications@fiscore.app>",
  );
}

function emailReplyTo() {
  return safeText(process.env.FISCORE_EMAIL_REPLY_TO);
}

function headerValue(headers, name) {
  const value = headers[name] || headers[name.toLowerCase()];
  return Array.isArray(value) ? value[0] : safeText(value);
}

function reminderDelayDays() {
  const parsed = Number.parseInt(
    process.env.FISCORE_ONBOARDING_REMINDER_DAYS || "3",
    10,
  );
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 3;
}

function reminderCutoffDate() {
  return new Date(Date.now() - reminderDelayDays() * 24 * 60 * 60 * 1000);
}

function isBeforeCutoff(timestampOrDate, cutoffDate) {
  if (!timestampOrDate) {
    return false;
  }
  const date = typeof timestampOrDate.toDate === "function"
    ? timestampOrDate.toDate()
    : new Date(timestampOrDate);
  return !Number.isNaN(date.getTime()) && date <= cutoffDate;
}

function normalizeLocale(locale) {
  const normalized = safeText(locale, "en").toLowerCase().split("-")[0];
  return supportedLocales.has(normalized) ? normalized : "en";
}

function notificationCollection({ tenantId, recipientUserId }) {
  if (safeText(tenantId)) {
    return db.collection(`tenants/${tenantId}/notificationEvents`);
  }
  if (safeText(recipientUserId)) {
    return db.collection(`users/${recipientUserId}/notificationEvents`);
  }
  return db.collection("notificationEvents");
}

function hashText(value) {
  return crypto.createHash("sha1").update(value).digest("hex");
}

function verifySvixWebhook(rawBody, headers, secret) {
  const webhookId = headerValue(headers, "svix-id");
  const timestamp = headerValue(headers, "svix-timestamp");
  const signature = headerValue(headers, "svix-signature");
  if (!webhookId || !timestamp || !signature) {
    throw new Error("Missing webhook signature headers.");
  }
  const timestampSeconds = Number.parseInt(timestamp, 10);
  const nowSeconds = Math.floor(Date.now() / 1000);
  if (
    !Number.isFinite(timestampSeconds) ||
    Math.abs(nowSeconds - timestampSeconds) > 5 * 60
  ) {
    throw new Error("Webhook timestamp is outside the allowed window.");
  }

  const secretValue = secret.startsWith("whsec_") ? secret.slice(6) : secret;
  const secretBytes = Buffer.from(secretValue, "base64");
  const signedPayload = `${webhookId}.${timestamp}.${rawBody}`;
  const expected = crypto
    .createHmac("sha256", secretBytes)
    .update(signedPayload)
    .digest("base64");
  const expectedBytes = Buffer.from(expected);
  const suppliedSignatures = signature
    .split(" ")
    .map((part) => part.trim())
    .filter(Boolean)
    .map((part) => part.split(","))
    .filter(([version, value]) => version === "v1" && value)
    .map(([, value]) => Buffer.from(value));

  const matched = suppliedSignatures.some((candidate) =>
    candidate.length === expectedBytes.length &&
    crypto.timingSafeEqual(candidate, expectedBytes),
  );
  if (!matched) {
    throw new Error("Webhook signature verification failed.");
  }
  return webhookId;
}

function generateDedupeKey({
  eventType,
  targetType = "none",
  targetId = "none",
  recipientUserId = null,
  recipientEmail = null,
  channel = "skip",
}) {
  const recipient = safeText(recipientUserId) ||
    safeText(recipientEmail, "unknown").toLowerCase();
  return [
    eventType,
    targetType || "none",
    targetId || "none",
    recipient,
    channel,
  ].join(":");
}

function statusForChannel(channel) {
  return channel === "skip" ? "skipped" : "pending";
}

function assertEmailEventIsEnabled(eventType, channel) {
  if (channel !== "email" || emailEnabledEvents.has(eventType)) {
    return;
  }
  throw new HttpsError(
    "failed-precondition",
    `Email is not enabled for notification event ${eventType}.`,
  );
}

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function renderString(template, data, { html = false } = {}) {
  return template.replace(/\{\{([a-zA-Z0-9_]+)\}\}/g, (_match, key) => {
    const value = data[key] ?? "";
    return html ? escapeHtml(value) : String(value);
  });
}

function renderEmailTemplate(eventType, locale, templateData = {}) {
  const resolvedLocale = normalizeLocale(locale);
  const localizedTemplates = templates[eventType];
  if (!localizedTemplates) {
    throw new HttpsError(
      "failed-precondition",
      `No email template found for ${eventType}.`,
    );
  }
  const template = localizedTemplates[resolvedLocale] || localizedTemplates.en;
  return {
    locale: resolvedLocale,
    subject: renderString(template.subject, templateData),
    text: renderString(template.text, templateData),
    html: renderString(template.html, templateData, { html: true }),
  };
}

async function findExistingDedupe(collectionRef, dedupeKey) {
  const snapshot = await collectionRef
    .where("dedupeKey", "==", dedupeKey)
    .where("status", "in", ["pending", "sent"])
    .limit(1)
    .get();
  return snapshot.empty ? null : snapshot.docs[0];
}

async function recordNotificationDecision(input) {
  const eventType = safeText(input?.eventType);
  const category = safeText(input?.category);
  const channel = safeText(input?.channel, "skip");
  const recipientEmail = safeText(input?.recipientEmail);
  const recipientUserId = safeText(input?.recipientUserId);
  if (!eventType || !category) {
    throw new HttpsError(
      "invalid-argument",
      "Notification event type and category are required.",
    );
  }
  if (channel === "email" && !recipientEmail && !recipientUserId) {
    throw new HttpsError(
      "invalid-argument",
      "Email notifications require a recipient.",
    );
  }
  assertEmailEventIsEnabled(eventType, channel);

  const collectionRef = notificationCollection({
    tenantId: safeText(input?.tenantId),
    recipientUserId,
  });
  const locale = normalizeLocale(input?.locale);
  const templateId = safeText(input?.templateId, eventType);
  const renderedEmail = channel === "email" && templates[templateId]
    ? renderEmailTemplate(
      templateId,
      locale,
      input?.templateData || {},
    )
    : null;
  const dedupeKey = safeText(input?.dedupeKey) || generateDedupeKey(input);
  const existing = await findExistingDedupe(collectionRef, dedupeKey);
  const now = admin.firestore.FieldValue.serverTimestamp();
  const eventRef = collectionRef.doc();
  const status = existing ? "suppressed" : statusForChannel(channel);
  const eventData = {
    eventType,
    category,
    tenantId: safeText(input?.tenantId),
    siteId: safeText(input?.siteId),
    targetType: safeText(input?.targetType),
    targetId: safeText(input?.targetId),
    targetPath: safeText(input?.targetPath),
    recipientUserId,
    recipientEmail,
    recipientRoleSnapshot: safeText(input?.recipientRoleSnapshot),
    tenantNameSnapshot: safeText(input?.tenantNameSnapshot),
    channel,
    status,
    dedupeKey,
    dedupeHash: hashText(dedupeKey),
    reason: safeText(input?.reason, existing ? "dedupe_suppressed" : "queued"),
    templateId,
    templateData: input?.templateData || {},
    locale,
    renderedSubject: renderedEmail?.subject || "",
    renderedText: renderedEmail?.text || "",
    renderedHtml: renderedEmail?.html || "",
    required: requiredEmailEvents.has(eventType),
    suppressedByEventId: existing?.id || null,
    createdAt: now,
    updatedAt: now,
    sentAt: null,
    failedAt: null,
    suppressedAt: existing ? now : null,
  };
  await eventRef.set(eventData);
  return { eventId: eventRef.id, ref: eventRef, status, suppressed: !!existing };
}

async function recordAndSendSetupReminder(input) {
  const decision = await recordNotificationDecision({
    category: "onboarding",
    channel: "email",
    ...input,
  });
  if (!decision.suppressed) {
    await sendEmailForNotification(decision.ref);
  }
  return decision;
}

async function scanNoWorkspaceUsers({ cutoffDate = reminderCutoffDate() } = {}) {
  let pageToken;
  let scanned = 0;
  let queued = 0;
  let skipped = 0;

  do {
    const result = await admin.auth().listUsers(1000, pageToken);
    pageToken = result.pageToken;
    for (const user of result.users) {
      scanned += 1;
      const email = safeText(user.email);
      if (
        !email ||
        user.disabled ||
        !isBeforeCutoff(user.metadata?.lastSignInTime, cutoffDate)
      ) {
        skipped += 1;
        continue;
      }

      const userRef = db.doc(`users/${user.uid}`);
      const userSnap = await userRef.get();
      const userData = userSnap.data() || {};
      if (safeText(userData.activeTenantId)) {
        skipped += 1;
        continue;
      }

      await recordAndSendSetupReminder({
        eventType: "signed_in_no_workspace",
        targetType: "user",
        targetId: user.uid,
        targetPath: `users/${user.uid}`,
        recipientUserId: user.uid,
        recipientEmail: email.toLowerCase(),
        templateId: "signed_in_no_workspace",
        templateData: {
          appUrl: appUrl(),
        },
        locale: userData.languagePreference,
        reason: "signed_in_no_workspace_reminder",
      });
      queued += 1;
    }
  } while (pageToken);

  return { scanned, queued, skipped };
}

async function scanNoSiteWorkspaces({ cutoffDate = reminderCutoffDate() } = {}) {
  const cutoffTimestamp = admin.firestore.Timestamp.fromDate(cutoffDate);
  const tenants = await db.collection("tenants")
    .where("status", "==", "active")
    .where("activeSiteCount", "==", 0)
    .where("createdAt", "<=", cutoffTimestamp)
    .limit(500)
    .get();
  let scanned = 0;
  let queued = 0;
  let skipped = 0;

  for (const tenantDoc of tenants.docs) {
    scanned += 1;
    const tenant = tenantDoc.data();
    if (!isBeforeCutoff(tenant.createdAt, cutoffDate)) {
      skipped += 1;
      continue;
    }

    const freshTenantSnap = await tenantDoc.ref.get();
    const freshTenant = freshTenantSnap.data() || {};
    if (
      freshTenant.status !== "active" ||
      Number(freshTenant.activeSiteCount || 0) > 0
    ) {
      skipped += 1;
      continue;
    }

    const ownerId = safeText(freshTenant.primaryOwnerUserId);
    if (!ownerId) {
      skipped += 1;
      continue;
    }
    const ownerSnap = await db.doc(`users/${ownerId}`).get();
    const owner = ownerSnap.data() || {};
    const email = safeText(owner.email);
    if (!email) {
      skipped += 1;
      continue;
    }

    await recordAndSendSetupReminder({
      eventType: "workspace_has_no_site",
      tenantId: tenantDoc.id,
      targetType: "tenant",
      targetId: tenantDoc.id,
      targetPath: `tenants/${tenantDoc.id}`,
      recipientUserId: ownerId,
      recipientEmail: email.toLowerCase(),
      recipientRoleSnapshot: "tenant_owner",
      tenantNameSnapshot: safeText(freshTenant.name, "FiScore workspace"),
      templateId: "workspace_has_no_site",
      templateData: {
        tenantName: safeText(freshTenant.name, "FiScore workspace"),
        appUrl: appUrl(),
      },
      locale: owner.languagePreference,
      reason: "workspace_has_no_site_reminder",
    });
    queued += 1;
  }

  return { scanned, queued, skipped };
}

const sendNoWorkspaceSetupReminders = onSchedule(
  {
    region,
    schedule: "every day 07:10",
    timeZone: "America/New_York",
    secrets: emailSecrets,
  },
  async () => {
    const result = await scanNoWorkspaceUsers();
    console.log("No-workspace setup reminders", result);
  },
);

const sendNoSiteSetupReminders = onSchedule(
  {
    region,
    schedule: "every day 07:20",
    timeZone: "America/New_York",
    secrets: emailSecrets,
  },
  async () => {
    const result = await scanNoSiteWorkspaces();
    console.log("No-site setup reminders", result);
  },
);

async function deliverNoopEmail(eventRef, rendered) {
  return {
    provider: "noop",
    providerMessageId: `noop_${eventRef.id}`,
    status: "accepted",
    rendered,
  };
}

async function deliverResendEmail(event, rendered) {
  const apiKey = safeText(resendApiKey.value());
  if (!apiKey) {
    throw new HttpsError(
      "failed-precondition",
      "RESEND_API_KEY is required when FISCORE_EMAIL_PROVIDER=resend.",
    );
  }
  if (typeof fetch !== "function") {
    throw new HttpsError(
      "failed-precondition",
      "Node fetch is required for Resend email delivery.",
    );
  }
  const recipientEmail = safeText(event.recipientEmail);
  if (!recipientEmail) {
    throw new HttpsError(
      "invalid-argument",
      "Notification email delivery requires recipientEmail.",
    );
  }

  const payload = {
    from: emailFrom(),
    to: [recipientEmail],
    subject: rendered.subject,
    text: rendered.text,
    html: rendered.html,
  };
  const replyTo = emailReplyTo();
  if (replyTo) {
    payload.reply_to = replyTo;
  }

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });
  const text = await response.text();
  let body = {};
  if (text) {
    try {
      body = JSON.parse(text);
    } catch (_error) {
      body = { raw: text };
    }
  }

  if (!response.ok) {
    const message = safeText(
      body.message || body.error || body.raw,
      `Resend email delivery failed with HTTP ${response.status}.`,
    );
    throw new HttpsError("internal", message);
  }

  return {
    provider: "resend",
    providerMessageId: safeText(body.id),
    status: "accepted",
  };
}

async function deliverEmail(eventRef, event, rendered) {
  const provider = emailProvider();
  if (provider === "noop") {
    return deliverNoopEmail(eventRef, rendered);
  }
  if (provider === "resend") {
    return deliverResendEmail(event, rendered);
  }
  throw new HttpsError(
    "failed-precondition",
    `Unsupported email provider ${provider}.`,
  );
}

async function sendEmailForNotification(eventRefOrPath) {
  const eventRef = typeof eventRefOrPath === "string"
    ? db.doc(eventRefOrPath)
    : eventRefOrPath;
  const eventSnap = await eventRef.get();
  if (!eventSnap.exists) {
    throw new HttpsError("not-found", "Notification event not found.");
  }
  const event = eventSnap.data();
  if (event.channel !== "email") {
    return { status: "skipped", reason: "not_email_channel" };
  }
  if (event.status === "suppressed") {
    return { status: "suppressed", reason: "dedupe_suppressed" };
  }

  const rendered = renderEmailTemplate(
    event.templateId || event.eventType,
    event.locale,
    event.templateData || {},
  );
  await eventRef.set({
    renderedSubject: rendered.subject,
    renderedText: rendered.text,
    renderedHtml: rendered.html,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  const provider = emailProvider();
  const attemptRef = eventRef.collection("deliveryAttempts").doc();
  const startedAt = admin.firestore.FieldValue.serverTimestamp();
  await attemptRef.set({
    channel: "email",
    provider,
    providerMessageId: null,
    status: "pending",
    recipientEmail: event.recipientEmail || null,
    renderedSubject: rendered.subject,
    renderedText: rendered.text,
    renderedHtml: rendered.html,
    attemptedAt: startedAt,
    completedAt: null,
    errorCode: null,
    errorMessage: null,
  });

  try {
    const result = await deliverEmail(eventRef, event, rendered);
    await attemptRef.set({
      provider: result.provider,
      providerMessageId: result.providerMessageId,
      status: result.status,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    await eventRef.set({
      status: "sent",
      provider: result.provider,
      providerMessageId: result.providerMessageId,
      renderedSubject: rendered.subject,
      renderedText: rendered.text,
      renderedHtml: rendered.html,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return {
      status: "sent",
      provider: result.provider,
      providerMessageId: result.providerMessageId,
    };
  } catch (error) {
    await attemptRef.set({
      status: "failed",
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      errorCode: error.code || "internal",
      errorMessage: safeText(error.message, "Email delivery failed."),
    }, { merge: true });
    await eventRef.set({
      status: "failed",
      failedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    throw error;
  }
}

function providerDeliveryStatusForResend(eventType) {
  switch (eventType) {
    case "email.sent":
      return "sent";
    case "email.delivered":
      return "delivered";
    case "email.delivery_delayed":
      return "delayed";
    case "email.bounced":
      return "bounced";
    case "email.complained":
      return "complained";
    case "email.failed":
      return "failed";
    case "email.suppressed":
      return "suppressed";
    case "email.opened":
      return "opened";
    case "email.clicked":
      return "clicked";
    default:
      return "received";
  }
}

function eventStatusForProviderDelivery(providerDeliveryStatus, currentStatus) {
  switch (providerDeliveryStatus) {
    case "bounced":
    case "complained":
    case "failed":
    case "suppressed":
      return "failed";
    default:
      return currentStatus || "sent";
  }
}

async function updateNotificationFromResendWebhook({
  webhookId,
  eventType,
  providerDeliveryStatus,
  payload,
}) {
  const emailId = safeText(payload?.data?.email_id || payload?.data?.id);
  const providerEventAt = safeText(payload?.created_at || payload?.data?.created_at);
  if (!emailId) {
    return { matched: 0, reason: "missing_email_id" };
  }

  const attempts = await db.collectionGroup("deliveryAttempts")
    .where("providerMessageId", "==", emailId)
    .limit(10)
    .get();
  if (attempts.empty) {
    return { matched: 0, reason: "no_matching_delivery_attempt" };
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  const parsedEventAt = providerEventAt ? new Date(providerEventAt) : null;
  const eventAtValue = parsedEventAt && !Number.isNaN(parsedEventAt.getTime())
    ? admin.firestore.Timestamp.fromDate(parsedEventAt)
    : now;
  let matched = 0;
  const batch = db.batch();
  for (const attemptDoc of attempts.docs) {
    const attempt = attemptDoc.data() || {};
    if (safeText(attempt.provider) !== "resend") {
      continue;
    }
    matched += 1;
    const notificationRef = attemptDoc.ref.parent.parent;
    const attemptUpdate = {
      providerDeliveryStatus,
      providerEventType: eventType,
      providerEventAt: eventAtValue,
      lastProviderEventAt: now,
      lastWebhookEventId: webhookId,
      webhookPayload: {
        type: eventType,
        createdAt: safeText(payload?.created_at),
        emailId,
        to: payload?.data?.to || [],
        from: safeText(payload?.data?.from),
        subject: safeText(payload?.data?.subject),
      },
      updatedAt: now,
    };
    batch.set(attemptDoc.ref, attemptUpdate, { merge: true });
    if (notificationRef) {
      const notificationSnap = await notificationRef.get();
      const notification = notificationSnap.data() || {};
      batch.set(notificationRef, {
        status: eventStatusForProviderDelivery(
          providerDeliveryStatus,
          notification.status,
        ),
        providerDeliveryStatus,
        providerEventType: eventType,
        providerEventAt: eventAtValue,
        lastProviderEventAt: now,
        lastWebhookEventId: webhookId,
        updatedAt: now,
      }, { merge: true });
    }
  }
  if (matched === 0) {
    return { matched: 0, reason: "no_resend_delivery_attempt" };
  }
  await batch.commit();
  return { matched, reason: "updated" };
}

const receiveResendWebhook = onRequest(
  {
    region,
    secrets: resendWebhookSecrets,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method not allowed");
      return;
    }

    const secret = safeText(resendWebhookSecret.value());
    if (!secret) {
      res.status(503).send("Webhook secret is not configured");
      return;
    }

    const rawBody = Buffer.isBuffer(req.rawBody)
      ? req.rawBody.toString("utf8")
      : JSON.stringify(req.body || {});
    let webhookId;
    try {
      webhookId = verifySvixWebhook(rawBody, req.headers, secret);
    } catch (error) {
      console.warn("Rejected Resend webhook", {
        error: safeText(error.message),
      });
      res.status(401).send("Invalid signature");
      return;
    }

    const webhookEventRef = db.collection("providerWebhookEvents").doc(webhookId);
    const existing = await webhookEventRef.get();
    if (existing.exists) {
      res.status(200).json({ ok: true, duplicate: true });
      return;
    }

    let payload;
    try {
      payload = JSON.parse(rawBody);
    } catch (_error) {
      res.status(400).send("Invalid JSON");
      return;
    }

    const eventType = safeText(payload?.type);
    const providerDeliveryStatus = providerDeliveryStatusForResend(eventType);
    const updateResult = await updateNotificationFromResendWebhook({
      webhookId,
      eventType,
      providerDeliveryStatus,
      payload,
    });
    await webhookEventRef.create({
      provider: "resend",
      eventType,
      providerDeliveryStatus,
      providerMessageId: safeText(payload?.data?.email_id || payload?.data?.id),
      matchedNotificationCount: updateResult.matched,
      matchReason: updateResult.reason,
      payloadSummary: {
        createdAt: safeText(payload?.created_at),
        emailId: safeText(payload?.data?.email_id || payload?.data?.id),
        from: safeText(payload?.data?.from),
        to: payload?.data?.to || [],
        subject: safeText(payload?.data?.subject),
      },
      receivedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(200).json({ ok: true, ...updateResult });
  },
);

module.exports = {
  emailSecrets,
  resendWebhookSecrets,
  templates,
  normalizeLocale,
  generateDedupeKey,
  renderEmailTemplate,
  assertEmailEventIsEnabled,
  recordNotificationDecision,
  sendEmailForNotification,
  scanNoWorkspaceUsers,
  scanNoSiteWorkspaces,
  sendNoWorkspaceSetupReminders,
  sendNoSiteSetupReminders,
  receiveResendWebhook,
};
