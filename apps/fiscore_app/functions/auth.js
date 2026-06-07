const { onCall, HttpsError } = require("firebase-functions/v2/https");
const {
  admin,
  db,
  region,
  cleanString,
  safeText,
} = require("./shared/runtime");
const {
  emailSecrets,
  recordNotificationDecision,
  sendEmailForNotification,
} = require("./notifications");

const allowedContinueHosts = new Set([
  "localhost",
  "127.0.0.1",
  "fiscore-dev.web.app",
  "fiscore-dev.firebaseapp.com",
]);

function defaultContinueUrl() {
  return process.env.FISCORE_APP_URL || "https://fiscore-dev.web.app";
}

function cleanContinueUrl(value) {
  const fallback = defaultContinueUrl();
  const raw = safeText(value, fallback);
  let parsed;
  try {
    parsed = new URL(raw);
  } catch (_error) {
    throw new HttpsError("invalid-argument", "Continue URL is invalid.");
  }

  const isLocalhost = parsed.hostname === "localhost" ||
    parsed.hostname === "127.0.0.1";
  if (
    !allowedContinueHosts.has(parsed.hostname) ||
    (!isLocalhost && parsed.protocol !== "https:")
  ) {
    throw new HttpsError("invalid-argument", "Continue URL is not allowed.");
  }
  return parsed.toString();
}

async function resolveTenantContextForEmail(email) {
  const inviteSnap = await db.collectionGroup("invites")
    .where("email", "==", email)
    .limit(5)
    .get();
  const inviteDoc = inviteSnap.docs.find((doc) => doc.data()?.status === "pending");
  if (inviteDoc) {
    const inviteRef = inviteDoc.ref;
    const tenantRef = inviteRef.parent.parent;
    if (tenantRef) {
      const tenantSnap = await tenantRef.get();
      return {
        tenantId: tenantRef.id,
        tenantName: safeText(tenantSnap.data()?.name, "FiScore workspace"),
      };
    }
  }

  const memberSnap = await db.collectionGroup("members")
    .where("emailSnapshot", "==", email)
    .limit(5)
    .get();
  const memberDoc = memberSnap.docs.find((doc) => doc.data()?.status === "active");
  if (memberDoc) {
    const memberRef = memberDoc.ref;
    const tenantRef = memberRef.parent.parent;
    if (tenantRef) {
      const tenantSnap = await tenantRef.get();
      return {
        tenantId: tenantRef.id,
        tenantName: safeText(tenantSnap.data()?.name, "FiScore workspace"),
      };
    }
  }

  return { tenantId: null, tenantName: null };
}

const sendPasswordlessSignInLink = onCall(
  { region, secrets: emailSecrets },
  async (request) => {
    const email = cleanString(request.data?.email, "Email", 254).toLowerCase();
    const continueUrl = cleanContinueUrl(request.data?.continueUrl);
    const locale = safeText(request.data?.locale);

    const actionUrl = await admin.auth().generateSignInWithEmailLink(
      email,
      {
        url: continueUrl,
        handleCodeInApp: true,
        android: {
          packageName: "com.pioneeritworks.fiscore.dev",
          installApp: true,
        },
        iOS: {
          bundleId: "com.pioneeritworks.fiscore.dev",
        },
      },
    );
    const tenantContext = await resolveTenantContextForEmail(email);
    const decision = await recordNotificationDecision({
      eventType: "passwordless_sign_in_link",
      category: "account_access",
      tenantId: tenantContext.tenantId,
      targetType: "auth",
      targetId: email,
      targetPath: "auth/passwordless-sign-in",
      recipientEmail: email,
      channel: "email",
      tenantNameSnapshot: tenantContext.tenantName,
      templateId: "passwordless_sign_in_link",
      templateData: { actionUrl },
      locale,
      dedupeKey: `passwordless_sign_in_link:${email}:${Date.now()}`,
      reason: "passwordless_sign_in_link",
    });

    if (!decision.suppressed) {
      await sendEmailForNotification(decision.ref);
    }

    return { status: decision.status };
  },
);

module.exports = { sendPasswordlessSignInLink };
