import { collection, onSnapshot, orderBy, query, where } from 'firebase/firestore';
import { db } from '../../shared/firebase/firebase';
import { documentTo, timestampMillis } from '../../shared/firebase/firestore';
import type { Site } from '../sites/types';
import type { TrainingAssignment } from '../training/types';
import type { Violation, ViolationAttachment, ViolationThreadEntry } from './types';

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
