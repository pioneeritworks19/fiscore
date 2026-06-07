const { onCall, HttpsError } = require("firebase-functions/v2/https");
const {
  admin,
  db,
  region,
  tenantAdminRoles,
  allSiteAccessRoles,
  requireAuth,
  normalizedEmail,
  cleanString,
  requireTenantRole,
  managedAccess,
  ensureCanAssignRole,
  teamAccessSnapshot,
  teamActivityData,
} = require("./shared/runtime");
const {
  emailSecrets,
  recordNotificationDecision,
  sendEmailForNotification,
} = require("./notifications");

function appUrl() {
  return process.env.FISCORE_APP_URL || "https://fiscore-dev.web.app";
}

function roleLabel(role) {
  return {
    tenant_owner: "Tenant owner",
    admin: "Admin",
    manager: "Manager",
    auditor: "Auditor",
    staff: "Staff",
  }[role] || "Team member";
}

function siteContext(siteAccessMode, siteIds) {
  if (siteAccessMode !== "selected") {
    return "Access: all restaurant sites.";
  }
  const count = Array.isArray(siteIds) ? siteIds.length : 0;
  if (count === 1) {
    return "Access: 1 selected restaurant site.";
  }
  return `Access: ${count} selected restaurant sites.`;
}

async function tenantName(tenantId) {
  const tenantSnap = await db.doc(`tenants/${tenantId}`).get();
  return tenantSnap.data()?.name || "FiScore workspace";
}

async function recordAndSendInviteEmail({
  eventType,
  tenantId,
  inviteId,
  email,
  role,
  siteAccessMode,
  siteIds,
  actor,
}) {
  const currentTenantName = await tenantName(tenantId);
  const decision = await recordNotificationDecision({
    eventType,
    category: "account_access",
    tenantId,
    targetType: "invite",
    targetId: inviteId,
    targetPath: `tenants/${tenantId}/invites/${inviteId}`,
    recipientEmail: email,
    channel: "email",
    tenantNameSnapshot: currentTenantName,
    templateId: eventType,
    templateData: {
      tenantName: currentTenantName,
      inviterName: actor?.displayNameSnapshot || actor?.emailSnapshot || "A FiScore admin",
      roleLabel: roleLabel(role),
      siteContext: siteContext(siteAccessMode, siteIds),
      actionUrl: appUrl(),
    },
    reason: "team_invite_email",
  });
  if (!decision.suppressed) {
    await sendEmailForNotification(decision.ref);
  }
  return decision;
}

const createTenantInvite = onCall(
  { region, secrets: emailSecrets },
  async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const email = cleanString(request.data?.email, "Email", 254).toLowerCase();
  const role = cleanString(request.data?.role, "Role", 40);
  const actor = await requireTenantRole(tenantId, auth.uid, tenantAdminRoles);
  ensureCanAssignRole(actor, role);
  const { siteAccessMode, siteIds } = managedAccess(
    role,
    request.data?.siteAccessMode,
    request.data?.siteIds,
  );

  const now = admin.firestore.FieldValue.serverTimestamp();
  const inviteRef = db.collection(`tenants/${tenantId}/invites`).doc();
  const activityRef = db.collection(`tenants/${tenantId}/teamActivity`).doc();
  const batch = db.batch();
  batch.set(inviteRef, {
    email,
    role,
    status: "pending",
    siteAccessMode,
    siteIds,
    invitedBy: auth.uid,
    invitedAt: now,
    acceptedBy: null,
    acceptedAt: null,
    createdAt: now,
    updatedAt: now,
  });
  batch.set(activityRef, teamActivityData({
    action: "invite_created",
    actorId: auth.uid,
    actor,
    targetEmail: email,
    after: { role, siteAccessMode, siteIds },
  }));
  await batch.commit();

  await recordAndSendInviteEmail({
    eventType: "team_invite_created",
    tenantId,
    inviteId: inviteRef.id,
    email,
    role,
    siteAccessMode,
    siteIds,
    actor,
  });

  return { inviteId: inviteRef.id };
  },
);

const listMyPendingInvites = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const email = normalizedEmail(auth);
  const inviteSnap = await db
    .collectionGroup("invites")
    .where("email", "==", email)
    .limit(20)
    .get();

  const invites = [];
  for (const inviteDoc of inviteSnap.docs) {
    const tenantRef = inviteDoc.ref.parent.parent;
    if (!tenantRef) {
      continue;
    }
    const invite = inviteDoc.data();
    if (invite.status !== "pending") {
      continue;
    }
    const tenantSnap = await tenantRef.get();
    const tenant = tenantSnap.data() || {};
    invites.push({
      tenantId: tenantRef.id,
      tenantName: tenant.name || "FiScore workspace",
      inviteId: inviteDoc.id,
      ...invite,
    });
  }

  return { invites };
});

const acceptTenantInvite = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const uid = auth.uid;
  const email = normalizedEmail(auth);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const inviteId = cleanString(request.data?.inviteId, "Invite ID", 160);
  const now = admin.firestore.FieldValue.serverTimestamp();
  const inviteRef = db.doc(`tenants/${tenantId}/invites/${inviteId}`);
  const memberRef = db.doc(`tenants/${tenantId}/members/${uid}`);
  const userRef = db.doc(`users/${uid}`);
  const activityRef = db.collection(`tenants/${tenantId}/teamActivity`).doc();

  await db.runTransaction(async (transaction) => {
    const inviteSnap = await transaction.get(inviteRef);
    if (!inviteSnap.exists) {
      throw new HttpsError("not-found", "Invite not found.");
    }

    const invite = inviteSnap.data();
    if (invite.status !== "pending" || invite.email !== email) {
      throw new HttpsError("permission-denied", "Invite is not valid for this user.");
    }

    const existingMemberSnap = await transaction.get(memberRef);
    const existingMember = existingMemberSnap.exists
      ? existingMemberSnap.data()
      : null;
    const displayName = auth.token.name || email.split("@")[0];
    const siteAccessMode = allSiteAccessRoles.includes(invite.role)
      ? "all"
      : invite.siteAccessMode || "all";
    const siteIds = allSiteAccessRoles.includes(invite.role)
      ? []
      : Array.isArray(invite.siteIds)
        ? invite.siteIds
        : [];
    transaction.set(
      userRef,
      {
        displayName,
        email,
        photoUrl: auth.token.picture || null,
        activeTenantId: tenantId,
        tenantIds: admin.firestore.FieldValue.arrayUnion(tenantId),
        status: "active",
        createdAt: now,
        updatedAt: now,
      },
      { merge: true },
    );
    transaction.set(memberRef, {
      userId: uid,
      displayNameSnapshot: displayName,
      emailSnapshot: email,
      role: invite.role,
      status: "active",
      siteAccessMode,
      siteIds,
      invitedBy: invite.invitedBy,
      invitedAt: invite.invitedAt,
      joinedAt: now,
      createdAt: now,
      updatedAt: now,
    });
    transaction.update(inviteRef, {
      status: "accepted",
      acceptedBy: uid,
      acceptedAt: now,
      updatedAt: now,
    });
    transaction.set(activityRef, teamActivityData({
      action: existingMember?.status === "inactive"
        ? "member_reactivated"
        : "invite_accepted",
      actorId: uid,
      actor: {
        displayNameSnapshot: displayName,
        emailSnapshot: email,
      },
      targetUserId: uid,
      targetDisplayName: displayName,
      targetEmail: email,
      before: existingMember ? teamAccessSnapshot(existingMember) : null,
      after: { role: invite.role, siteAccessMode, siteIds },
    }));
  });

  return { tenantId };
});

const cancelTenantInvite = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const inviteId = cleanString(request.data?.inviteId, "Invite ID", 160);
  const now = admin.firestore.FieldValue.serverTimestamp();
  const inviteRef = db.doc(`tenants/${tenantId}/invites/${inviteId}`);
  const activityRef = db.collection(`tenants/${tenantId}/teamActivity`).doc();

  const actor = await requireTenantRole(tenantId, auth.uid, tenantAdminRoles);

  await db.runTransaction(async (transaction) => {
    const inviteSnap = await transaction.get(inviteRef);
    if (!inviteSnap.exists) {
      throw new HttpsError("not-found", "Invite not found.");
    }
    const invite = inviteSnap.data();
    if (invite.status !== "pending") {
      throw new HttpsError(
        "failed-precondition",
        "Only pending invitations can be canceled.",
      );
    }
    if (invite.role === "admin" && actor.role !== "tenant_owner") {
      throw new HttpsError(
        "permission-denied",
        "Only the tenant owner can cancel an admin invitation.",
      );
    }
    transaction.update(inviteRef, {
      status: "canceled",
      canceledBy: auth.uid,
      canceledAt: now,
      updatedAt: now,
    });
    transaction.set(activityRef, teamActivityData({
      action: "invite_canceled",
      actorId: auth.uid,
      actor,
      targetEmail: invite.email || null,
      before: teamAccessSnapshot(invite),
    }));
  });

  return { tenantId, inviteId };
});

const resendTenantInvite = onCall(
  { region, secrets: emailSecrets },
  async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const inviteId = cleanString(request.data?.inviteId, "Invite ID", 160);
  const inviteRef = db.doc(`tenants/${tenantId}/invites/${inviteId}`);
  const actor = await requireTenantRole(tenantId, auth.uid, tenantAdminRoles);
  const inviteSnap = await inviteRef.get();
  if (!inviteSnap.exists) {
    throw new HttpsError("not-found", "Invite not found.");
  }
  const invite = inviteSnap.data();
  if (invite.status !== "pending") {
    throw new HttpsError(
      "failed-precondition",
      "Only pending invitations can be resent.",
    );
  }
  if (invite.role === "admin" && actor.role !== "tenant_owner") {
    throw new HttpsError(
      "permission-denied",
      "Only the tenant owner can resend an admin invitation.",
    );
  }

  const decision = await recordAndSendInviteEmail({
    eventType: "team_invite_resent",
    tenantId,
    inviteId,
    email: invite.email,
    role: invite.role,
    siteAccessMode: invite.siteAccessMode,
    siteIds: invite.siteIds,
    actor,
  });

  await inviteRef.set({
    lastResentBy: auth.uid,
    lastResentAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  return { inviteId, notificationStatus: decision.status };
  },
);

const updateTenantInviteAccess = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const inviteId = cleanString(request.data?.inviteId, "Invite ID", 160);
  const role = cleanString(request.data?.role, "Role", 40);
  const now = admin.firestore.FieldValue.serverTimestamp();
  const inviteRef = db.doc(`tenants/${tenantId}/invites/${inviteId}`);
  const activityRef = db.collection(`tenants/${tenantId}/teamActivity`).doc();
  const actor = await requireTenantRole(tenantId, auth.uid, tenantAdminRoles);

  ensureCanAssignRole(actor, role);
  const { siteAccessMode, siteIds } = managedAccess(
    role,
    request.data?.siteAccessMode,
    request.data?.siteIds,
  );

  await db.runTransaction(async (transaction) => {
    const inviteSnap = await transaction.get(inviteRef);
    if (!inviteSnap.exists) {
      throw new HttpsError("not-found", "Invite not found.");
    }
    const invite = inviteSnap.data();
    if (invite.status !== "pending") {
      throw new HttpsError(
        "failed-precondition",
        "Only pending invitations can be changed.",
      );
    }
    if (invite.role === "admin" && actor.role !== "tenant_owner") {
      throw new HttpsError(
        "permission-denied",
        "Only the tenant owner can change an admin invitation.",
      );
    }
    transaction.update(inviteRef, {
      role,
      siteAccessMode,
      siteIds,
      updatedBy: auth.uid,
      updatedAt: now,
    });
    transaction.set(activityRef, teamActivityData({
      action: "invite_access_updated",
      actorId: auth.uid,
      actor,
      targetEmail: invite.email || null,
      before: teamAccessSnapshot(invite),
      after: { role, siteAccessMode, siteIds },
    }));
  });

  return { tenantId, inviteId };
});

const updateTenantMemberAccess = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const userId = cleanString(request.data?.userId, "User ID", 160);
  const role = cleanString(request.data?.role, "Role", 40);
  const now = admin.firestore.FieldValue.serverTimestamp();
  const memberRef = db.doc(`tenants/${tenantId}/members/${userId}`);
  const activityRef = db.collection(`tenants/${tenantId}/teamActivity`).doc();
  const actor = await requireTenantRole(tenantId, auth.uid, tenantAdminRoles);

  if (auth.uid === userId) {
    throw new HttpsError(
      "failed-precondition",
      "You cannot change your own access.",
    );
  }
  ensureCanAssignRole(actor, role);
  const { siteAccessMode, siteIds } = managedAccess(
    role,
    request.data?.siteAccessMode,
    request.data?.siteIds,
  );

  await db.runTransaction(async (transaction) => {
    const memberSnap = await transaction.get(memberRef);
    if (!memberSnap.exists) {
      throw new HttpsError("not-found", "Team member not found.");
    }
    const member = memberSnap.data();
    if (member.status !== "active") {
      throw new HttpsError(
        "failed-precondition",
        "Only active members can be edited.",
      );
    }
    if (member.role === "tenant_owner") {
      throw new HttpsError(
        "failed-precondition",
        "The tenant owner cannot be changed.",
      );
    }
    if (member.role === "admin" && actor.role !== "tenant_owner") {
      throw new HttpsError(
        "permission-denied",
        "Only the tenant owner can change an admin.",
      );
    }
    transaction.update(memberRef, {
      role,
      siteAccessMode,
      siteIds,
      updatedBy: auth.uid,
      updatedAt: now,
    });
    transaction.set(activityRef, teamActivityData({
      action: "member_access_updated",
      actorId: auth.uid,
      actor,
      targetUserId: userId,
      targetDisplayName: member.displayNameSnapshot || null,
      targetEmail: member.emailSnapshot || null,
      before: teamAccessSnapshot(member),
      after: { role, siteAccessMode, siteIds },
    }));
  });

  return { tenantId, userId };
});

const deactivateTenantMember = onCall({ region }, async (request) => {
  const auth = requireAuth(request);
  const tenantId = cleanString(request.data?.tenantId, "Tenant ID", 160);
  const userId = cleanString(request.data?.userId, "User ID", 160);
  const now = admin.firestore.FieldValue.serverTimestamp();
  const memberRef = db.doc(`tenants/${tenantId}/members/${userId}`);
  const activityRef = db.collection(`tenants/${tenantId}/teamActivity`).doc();

  const actor = await requireTenantRole(tenantId, auth.uid, tenantAdminRoles);

  if (auth.uid === userId) {
    throw new HttpsError("failed-precondition", "You cannot deactivate yourself.");
  }

  await db.runTransaction(async (transaction) => {
    const memberSnap = await transaction.get(memberRef);
    if (!memberSnap.exists) {
      throw new HttpsError("not-found", "Team member not found.");
    }
    const member = memberSnap.data();
    if (member.role === "tenant_owner") {
      throw new HttpsError(
        "failed-precondition",
        "The tenant owner cannot be deactivated.",
      );
    }
    if (member.role === "admin" && actor.role !== "tenant_owner") {
      throw new HttpsError(
        "permission-denied",
        "Only the tenant owner can deactivate an admin.",
      );
    }

    transaction.update(memberRef, {
      status: "inactive",
      deactivatedBy: auth.uid,
      deactivatedAt: now,
      updatedAt: now,
    });
    transaction.set(activityRef, teamActivityData({
      action: "member_deactivated",
      actorId: auth.uid,
      actor,
      targetUserId: userId,
      targetDisplayName: member.displayNameSnapshot || null,
      targetEmail: member.emailSnapshot || null,
      before: teamAccessSnapshot(member),
    }));
  });

  return { tenantId, userId };
});

module.exports = {
  createTenantInvite,
  listMyPendingInvites,
  acceptTenantInvite,
  cancelTenantInvite,
  resendTenantInvite,
  updateTenantInviteAccess,
  updateTenantMemberAccess,
  deactivateTenantMember,
};
