import {
  collection,
  doc,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  updateDoc,
  where,
  type DocumentData,
  type QueryDocumentSnapshot,
} from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { getDownloadURL, ref } from 'firebase/storage';
import { db, functions, storage } from './firebase';
import type {
  Activity,
  Audit,
  AuditResponse,
  Invite,
  Member,
  PublicInspection,
  RestaurantSearchResult,
  Site,
  Tenant,
  TrainingAssignment,
  UserProfile,
  Violation,
  ViolationAttachment,
  ViolationThreadEntry,
} from './types';

export function documentTo<T>(snapshot: QueryDocumentSnapshot<DocumentData>): T {
  return { id: snapshot.id, ...snapshot.data() } as T;
}

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
    (snapshot) =>
      next(snapshot.exists() ? ({ id: snapshot.id, ...snapshot.data() } as Member) : null),
    (err) => error(err.message),
  );
}

export function subscribeSites(
  tenantId: string,
  next: (sites: Site[]) => void,
  error: (message: string) => void,
) {
  return onSnapshot(
    query(collection(db, 'tenants', tenantId, 'sites'), where('status', '==', 'active')),
    (snapshot) => next(snapshot.docs.map((docSnap) => documentTo<Site>(docSnap))),
    (err) => error(err.message),
  );
}

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

export function subscribeViolationsForSites(
  tenantId: string,
  sites: Site[],
  next: (violations: Violation[]) => void,
  error: (message: string) => void,
) {
  if (sites.length === 0) {
    next([]);
    return () => {};
  }

  const bySite = new Map<string, Violation[]>();
  const unsubs = sites.map((site) =>
    onSnapshot(
      query(collection(db, 'tenants', tenantId, 'sites', site.id, 'violations')),
      (snapshot) => {
        bySite.set(
          site.id,
          snapshot.docs.map((docSnap) => ({
            ...documentTo<Violation>(docSnap),
            siteId: site.id,
            siteName: site.name,
          })),
        );
        next(
          Array.from(bySite.values())
            .flat()
            .sort((a, b) => timestampMillis(b.updatedAt) - timestampMillis(a.updatedAt)),
        );
      },
      (err) => error(err.message),
    ),
  );
  return () => unsubs.forEach((unsubscribe) => unsubscribe());
}

export function subscribeAuditsForSites(
  tenantId: string,
  sites: Site[],
  next: (audits: Audit[]) => void,
  error: (message: string) => void,
) {
  if (sites.length === 0) {
    next([]);
    return () => {};
  }

  const bySite = new Map<string, Audit[]>();
  const unsubs = sites.map((site) =>
    onSnapshot(
      query(collection(db, 'tenants', tenantId, 'sites', site.id, 'audits')),
      (snapshot) => {
        bySite.set(
          site.id,
          snapshot.docs.map((docSnap) => ({
            ...documentTo<Audit>(docSnap),
            siteId: site.id,
            siteName: site.name,
          })),
        );
        next(
          Array.from(bySite.values())
            .flat()
            .sort((a, b) => timestampMillis(b.completedAt || b.startedAt || b.updatedAt) - timestampMillis(a.completedAt || a.startedAt || a.updatedAt)),
        );
      },
      (err) => error(err.message),
    ),
  );
  return () => unsubs.forEach((unsubscribe) => unsubscribe());
}

export function subscribePublicInspectionsForSites(
  tenantId: string,
  sites: Site[],
  next: (inspections: PublicInspection[]) => void,
  error: (message: string) => void,
) {
  if (sites.length === 0) {
    next([]);
    return () => {};
  }

  const bySite = new Map<string, PublicInspection[]>();
  const unsubs = sites.map((site) =>
    onSnapshot(
      query(collection(db, 'tenants', tenantId, 'sites', site.id, 'inspections')),
      (snapshot) => {
        bySite.set(
          site.id,
          snapshot.docs.map((docSnap) => ({
            ...documentTo<PublicInspection>(docSnap),
            siteId: site.id,
            siteName: site.name,
          })),
        );
        next(
          Array.from(bySite.values())
            .flat()
            .sort(
              (a, b) =>
                timestampMillis(b.inspectionDate || b.importedAt || b.updatedAt) -
                timestampMillis(a.inspectionDate || a.importedAt || a.updatedAt),
            ),
        );
      },
      (err) => error(err.message),
    ),
  );
  return () => unsubs.forEach((unsubscribe) => unsubscribe());
}

export function subscribeAuditResponses(
  tenantId: string,
  siteId: string,
  auditId: string,
  next: (responses: AuditResponse[]) => void,
  error: (message: string) => void,
) {
  return onSnapshot(
    collection(db, 'tenants', tenantId, 'sites', siteId, 'audits', auditId, 'responses'),
    (snapshot) => next(snapshot.docs.map((docSnap) => documentTo<AuditResponse>(docSnap))),
    (err) => error(err.message),
  );
}

export function subscribeViolationsForAudit(
  tenantId: string,
  siteId: string,
  auditId: string,
  next: (violations: Violation[]) => void,
  error: (message: string) => void,
) {
  return onSnapshot(
    query(
      collection(db, 'tenants', tenantId, 'sites', siteId, 'violations'),
      where('auditId', '==', auditId),
    ),
    (snapshot) =>
      next(
        snapshot.docs.map((docSnap) => ({
          ...documentTo<Violation>(docSnap),
          siteId,
        })),
      ),
    (err) => error(err.message),
  );
}

export function subscribeViolationsForInspection(
  tenantId: string,
  siteId: string,
  inspectionId: string,
  next: (violations: Violation[]) => void,
  error: (message: string) => void,
) {
  return onSnapshot(
    query(
      collection(db, 'tenants', tenantId, 'sites', siteId, 'violations'),
      where('masterInspectionId', '==', inspectionId),
    ),
    (snapshot) =>
      next(
        snapshot.docs.map((docSnap) => ({
          ...documentTo<Violation>(docSnap),
          siteId,
        })),
      ),
    (err) => error(err.message),
  );
}

export function subscribeTrainingAssignments(
  tenantId: string,
  sites: Site[],
  next: (assignments: TrainingAssignment[]) => void,
  error: (message: string) => void,
) {
  const siteNames = new Map(sites.map((site) => [site.id, site.name || '']));
  return onSnapshot(
    collection(db, 'tenants', tenantId, 'trainingAssignments'),
    (snapshot) =>
      next(
        snapshot.docs
          .map((docSnap) => {
            const assignment = documentTo<TrainingAssignment>(docSnap);
            return {
              ...assignment,
              siteName: assignment.siteId ? siteNames.get(assignment.siteId) || assignment.siteName : assignment.siteName,
            };
          })
          .sort((a, b) => trainingSortValue(a) - trainingSortValue(b)),
      ),
    (err) => error(err.message),
  );
}

export function subscribeViolationAttachments(
  tenantId: string,
  siteId: string,
  violationId: string,
  next: (attachments: ViolationAttachment[]) => void,
  error: (message: string) => void,
) {
  return onSnapshot(
    query(collection(db, 'tenants', tenantId, 'sites', siteId, 'violations', violationId, 'attachments')),
    (snapshot) => next(snapshot.docs.map((docSnap) => documentTo<ViolationAttachment>(docSnap))),
    (err) => error(err.message),
  );
}

export function subscribeViolationThread(
  tenantId: string,
  siteId: string,
  violationId: string,
  next: (entries: ViolationThreadEntry[]) => void,
  error: (message: string) => void,
) {
  return onSnapshot(
    query(
      collection(db, 'tenants', tenantId, 'sites', siteId, 'violations', violationId, 'threads'),
      orderBy('createdAt', 'desc'),
    ),
    (snapshot) => next(snapshot.docs.map((docSnap) => documentTo<ViolationThreadEntry>(docSnap))),
    (err) => error(err.message),
  );
}

export function subscribeViolationTrainingAssignments(
  tenantId: string,
  siteId: string,
  violationId: string,
  next: (assignments: TrainingAssignment[]) => void,
  error: (message: string) => void,
) {
  return onSnapshot(
    query(
      collection(db, 'tenants', tenantId, 'trainingAssignments'),
      where('siteId', '==', siteId),
      where('linkedViolationId', '==', violationId),
    ),
    (snapshot) => next(snapshot.docs.map((docSnap) => documentTo<TrainingAssignment>(docSnap))),
    (err) => error(err.message),
  );
}

function timestampMillis(value: unknown) {
  if (value && typeof value === 'object' && 'toMillis' in value && typeof value.toMillis === 'function') {
    return value.toMillis();
  }
  if (typeof value === 'string') {
    const time = new Date(value).getTime();
    return Number.isNaN(time) ? 0 : time;
  }
  return 0;
}

function trainingSortValue(assignment: TrainingAssignment) {
  const status = assignment.status || 'assigned';
  const statusValue = status === 'completed' ? 1 : status === 'cancelled' ? 2 : 0;
  const due = timestampMillis(assignment.dueDate || assignment.dueAt);
  const fallback = timestampMillis(assignment.createdAt || assignment.updatedAt);
  return statusValue * 2_000_000_000_000 + (due || fallback);
}

export async function callFunction<T>(
  name: string,
  data: Record<string, unknown>,
): Promise<T> {
  const callable = httpsCallable<Record<string, unknown>, T>(functions, name);
  const result = await callable(data);
  return result.data;
}

export async function getStorageDownloadUrl(storagePath: string) {
  return getDownloadURL(ref(storage, storagePath));
}

export async function createTenantAndOwner(tenantName: string, displayName?: string | null) {
  return callFunction<{ tenantId: string }>('createTenantAndOwner', {
    tenantName,
    displayName,
  });
}

export async function searchMasterRestaurants(tenantId: string, searchText: string) {
  return callFunction<{ restaurants: RestaurantSearchResult[] }>('searchMasterRestaurants', {
    tenantId,
    query: searchText,
  });
}

export async function linkMasterRestaurantSite(tenantId: string, masterRestaurantId: string) {
  return callFunction<{ siteId: string }>('linkMasterRestaurantSite', {
    tenantId,
    masterRestaurantId,
  });
}

export async function createSite(
  tenantId: string,
  site: {
    siteName: string;
    addressLine1: string;
    city: string;
    state: string;
    postalCode: string;
  },
) {
  return callFunction<{ siteId: string }>('createSite', {
    tenantId,
    ...site,
    siteType: 'restaurant',
  });
}

export async function updateManualSite(
  tenantId: string,
  siteId: string,
  site: {
    siteName: string;
    addressLine1: string;
    city: string;
    state: string;
    postalCode: string;
  },
) {
  return callFunction<{ siteId: string }>('updateManualSite', {
    tenantId,
    siteId,
    ...site,
    siteType: 'restaurant',
  });
}

export async function deleteSite(tenantId: string, siteId: string, confirmation: string) {
  return callFunction<{ tenantId: string; siteId: string }>('deleteSite', {
    tenantId,
    siteId,
    confirmation,
  });
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

export async function updateLanguagePreference(uid: string, languagePreference: 'en' | 'es') {
  await updateDoc(doc(db, 'users', uid), {
    languagePreference,
    updatedAt: serverTimestamp(),
  });
}
