import { collection, onSnapshot, query } from 'firebase/firestore';
import { db } from '../../shared/firebase/firebase';
import { documentTo, timestampMillis } from '../../shared/firebase/firestore';
import type { Site } from '../sites/types';
import type { Audit, AuditResponse, PublicInspection } from './types';

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
            .sort(
              (a, b) =>
                timestampMillis(b.completedAt || b.startedAt || b.updatedAt) -
                timestampMillis(a.completedAt || a.startedAt || a.updatedAt),
            ),
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
