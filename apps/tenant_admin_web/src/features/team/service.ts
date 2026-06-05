import { collection, onSnapshot, orderBy, query } from 'firebase/firestore';
import { db } from '../../shared/firebase/firebase';
import { documentTo } from '../../shared/firebase/firestore';
import { callFunction } from '../../shared/firebase/functions';
import type { Activity } from '../../shared/types/core';
import type { Invite, Member } from './types';

export function subscribeMembers(
  tenantId: string,
  next: (members: Member[]) => void,
  error: (message: string) => void,
) {
  return onSnapshot(
    query(collection(db, 'tenants', tenantId, 'members'), orderBy('emailSnapshot')),
    (snapshot) => next(snapshot.docs.map((docSnap) => documentTo<Member>(docSnap))),
    (err) => error(err.message),
  );
}

export function subscribeInvites(
  tenantId: string,
  next: (invites: Invite[]) => void,
  error: (message: string) => void,
) {
  return onSnapshot(
    query(collection(db, 'tenants', tenantId, 'invites'), orderBy('invitedAt', 'desc')),
    (snapshot) => next(snapshot.docs.map((docSnap) => documentTo<Invite>(docSnap))),
    (err) => error(err.message),
  );
}

export function subscribeActivity(
  tenantId: string,
  next: (activity: Activity[]) => void,
  error: (message: string) => void,
) {
  return onSnapshot(
    query(collection(db, 'tenants', tenantId, 'teamActivity'), orderBy('createdAt', 'desc')),
    (snapshot) => next(snapshot.docs.slice(0, 20).map((docSnap) => documentTo<Activity>(docSnap))),
    (err) => error(err.message),
  );
}

export async function createTenantInvite(data: {
  tenantId: string;
  email: string;
  role: string;
  siteAccessMode: string;
  siteIds: string[];
}) {
  return callFunction<{ inviteId: string }>('createTenantInvite', data);
}

export async function deactivateTenantMember(tenantId: string, userId: string) {
  return callFunction<{ tenantId: string; userId: string }>('deactivateTenantMember', {
    tenantId,
    userId,
  });
}

export async function updateTenantMemberAccess(data: {
  tenantId: string;
  userId: string;
  role: string;
  siteAccessMode: string;
  siteIds: string[];
}) {
  return callFunction<{ tenantId: string; userId: string }>('updateTenantMemberAccess', data);
}

export async function cancelTenantInvite(tenantId: string, inviteId: string) {
  return callFunction<{ tenantId: string; inviteId: string }>('cancelTenantInvite', {
    tenantId,
    inviteId,
  });
}
