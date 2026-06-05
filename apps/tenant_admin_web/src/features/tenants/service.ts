import { doc, onSnapshot, serverTimestamp, updateDoc } from 'firebase/firestore';
import { db } from '../../shared/firebase/firebase';
import { documentTo } from '../../shared/firebase/firestore';
import { callFunction } from '../../shared/firebase/functions';
import type { UserProfile } from '../../shared/types/core';
import type { Member } from '../team/types';
import type { Tenant } from './types';

export function subscribeUserProfile(
  uid: string,
  next: (profile: UserProfile | null) => void,
  error: (message: string) => void,
) {
  return onSnapshot(
    doc(db, 'users', uid),
    (snapshot) => next(snapshot.exists() ? (snapshot.data() as UserProfile) : null),
    (err) => error(err.message),
  );
}

export function subscribeTenant(
  tenantId: string,
  next: (tenant: Tenant | null) => void,
  error: (message: string) => void,
) {
  return onSnapshot(
    doc(db, 'tenants', tenantId),
    (snapshot) =>
      next(snapshot.exists() ? ({ id: snapshot.id, ...snapshot.data() } as Tenant) : null),
    (err) => error(err.message),
  );
}

export function subscribeMember(
  tenantId: string,
  uid: string,
  next: (member: Member | null) => void,
  error: (message: string) => void,
) {
  return onSnapshot(
    doc(db, 'tenants', tenantId, 'members', uid),
    (snapshot) => next(snapshot.exists() ? documentTo<Member>(snapshot) : null),
    (err) => error(err.message),
  );
}

export async function createTenantAndOwner(tenantName: string, displayName?: string | null) {
  return callFunction<{ tenantId: string }>('createTenantAndOwner', {
    tenantName,
    displayName,
  });
}

export async function updateLanguagePreference(uid: string, languagePreference: 'en' | 'es') {
  await updateDoc(doc(db, 'users', uid), {
    languagePreference,
    updatedAt: serverTimestamp(),
  });
}
