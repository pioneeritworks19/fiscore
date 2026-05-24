const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const bucket = admin.storage().bucket();
const region = "us-central1";
const storageRegion = "us-east1";
const tenantAdminRoles = ["tenant_owner", "admin"];
const siteActionRoles = ["tenant_owner", "admin", "manager"];
const internalAuditRoles = ["tenant_owner", "admin", "manager", "auditor"];
const allowedMemberRoles = ["admin", "manager", "auditor", "staff"];
const allSiteAccessRoles = ["tenant_owner", "admin"];

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

function cleanStringArray(value, fieldName, maxItems, maxLength) {
  if (!Array.isArray(value)) {
    return [];
  }
  if (value.length > maxItems) {
    throw new HttpsError("invalid-argument", `${fieldName} has too many items.`);
  }
  return value.map((item) => cleanString(item, fieldName, maxLength));
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

async function requireSiteRole(tenantId, siteId, uid, roles) {
  const member = await requireTenantRole(tenantId, uid, roles);
  const hasSiteAccess = allSiteAccessRoles.includes(member.role) ||
    member.siteAccessMode !== "selected" ||
    (Array.isArray(member.siteIds) && member.siteIds.includes(siteId));
  if (!hasSiteAccess) {
    throw new HttpsError("permission-denied", "Access to this site is required.");
  }
  return member;
}

function managedAccess(role, requestedMode, requestedSiteIds) {
  if (!allowedMemberRoles.includes(role)) {
    throw new HttpsError("invalid-argument", "Unsupported team role.");
  }
  if (allSiteAccessRoles.includes(role)) {
    return { siteAccessMode: "all", siteIds: [] };
  }
  const siteAccessMode = requestedMode === "selected" ? "selected" : "all";
  const siteIds = siteAccessMode === "selected"
    ? cleanStringArray(requestedSiteIds, "Site access", 50, 160)
    : [];
  if (siteAccessMode === "selected" && siteIds.length === 0) {
    throw new HttpsError("invalid-argument", "Choose at least one site.");
  }
  return { siteAccessMode, siteIds };
}

function ensureCanAssignRole(actor, role) {
  if (role === "admin" && actor.role !== "tenant_owner") {
    throw new HttpsError(
      "permission-denied",
      "Only the tenant owner can assign the admin role.",
    );
  }
}

function teamAccessSnapshot(data) {
  return {
    role: typeof data?.role === "string" ? data.role : null,
    siteAccessMode: data?.siteAccessMode === "selected" ? "selected" : "all",
    siteIds: Array.isArray(data?.siteIds) ? data.siteIds : [],
  };
}

function teamActivityData({
  action,
  actorId,
  actor,
  targetUserId = null,
  targetDisplayName = null,
  targetEmail = null,
  before = null,
  after = null,
}) {
  return {
    action,
    actorId,
    actorDisplayName: actor?.displayNameSnapshot || null,
    actorEmail: actor?.emailSnapshot || null,
    targetUserId,
    targetDisplayName,
    targetEmail,
    before,
    after,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

function safeText(value, fallback = null) {
  return typeof value === "string" && value.trim() ? value.trim() : fallback;
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

module.exports = {
  admin,
  db,
  bucket,
  region,
  storageRegion,
  tenantAdminRoles,
  siteActionRoles,
  internalAuditRoles,
  allSiteAccessRoles,
  requireAuth,
  normalizedEmail,
  cleanString,
  requireTenantRole,
  requireSiteRole,
  managedAccess,
  ensureCanAssignRole,
  teamAccessSnapshot,
  teamActivityData,
  safeText,
  safeDeleteStorageFile,
};
