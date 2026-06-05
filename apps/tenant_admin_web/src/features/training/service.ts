import { collection, onSnapshot } from 'firebase/firestore';
import { db } from '../../shared/firebase/firebase';
import { documentTo, timestampMillis } from '../../shared/firebase/firestore';
import type { Site } from '../sites/types';
import type { TrainingAssignment } from './types';

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
              siteName: assignment.siteId
                ? siteNames.get(assignment.siteId) || assignment.siteName
                : assignment.siteName,
            };
          })
          .sort((a, b) => trainingSortValue(a) - trainingSortValue(b)),
      ),
    (err) => error(err.message),
  );
}

function trainingSortValue(assignment: TrainingAssignment) {
  const status = assignment.status || 'assigned';
  const statusValue = status === 'completed' ? 1 : status === 'cancelled' ? 2 : 0;
  const due = timestampMillis(assignment.dueDate || assignment.dueAt);
  const fallback = timestampMillis(assignment.createdAt || assignment.updatedAt);
  return statusValue * 2_000_000_000_000 + (due || fallback);
}
