const { onCall, HttpsError } = require("firebase-functions/v2/https");
const {
  admin,
  db,
  region,
  requireAuth,
  normalizedEmail,
  cleanString,
} = require("./shared/runtime");
const {
  emailSecrets,
  recordNotificationDecision,
  sendEmailForNotification,
} = require("./notifications");

function appUrl() {
  return process.env.FISCORE_APP_URL || "https://fiscore-dev.web.app";
}

function websiteUrl() {
  return process.env.FISCORE_WEBSITE_URL || "https://fiscore.app";
}

function adminUrl() {
  return process.env.FISCORE_ADMIN_URL || appUrl();
}

const createTenantAndOwner = onCall(
  { region, secrets: emailSecrets },
  async (request) => {
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
      siteAccessMode: "all",
      siteIds: [],
      joinedAt: now,
      createdAt: now,
      updatedAt: now,
    });
  });

  const decision = await recordNotificationDecision({
    eventType: "workspace_created",
    category: "onboarding",
    tenantId: tenantRef.id,
    targetType: "tenant",
    targetId: tenantRef.id,
    targetPath: `tenants/${tenantRef.id}`,
    recipientUserId: uid,
    recipientEmail: email,
    recipientRoleSnapshot: "tenant_owner",
    tenantNameSnapshot: tenantName,
    channel: "email",
    templateId: "workspace_created",
    templateData: {
      tenantName,
      appUrl: appUrl(),
      websiteUrl: websiteUrl(),
      adminUrl: adminUrl(),
    },
    reason: "workspace_created_orientation",
  });
  if (!decision.suppressed) {
    await sendEmailForNotification(decision.ref);
  }

  return { tenantId: tenantRef.id, notificationStatus: decision.status };
  },
);

module.exports = { createTenantAndOwner };
