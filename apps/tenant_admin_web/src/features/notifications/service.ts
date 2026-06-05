import { collection, limit, onSnapshot, orderBy, query, where } from 'firebase/firestore';
import { db } from '../../shared/firebase/firebase';
import { documentTo } from '../../shared/firebase/firestore';
import type { NotificationDeliveryAttempt, NotificationEvent } from './types';

export function subscribeNotificationEvents(
  tenantId: string,
  statusFilter: string,
  next: (events: NotificationEvent[]) => void,
  error: (message: string) => void,
) {
  const baseCollection = collection(db, 'tenants', tenantId, 'notificationEvents');
  const eventQuery =
    statusFilter === 'all'
      ? query(baseCollection, orderBy('createdAt', 'desc'), limit(100))
      : query(
          baseCollection,
          where('status', '==', statusFilter),
          orderBy('createdAt', 'desc'),
          limit(100),
        );

  return onSnapshot(
    eventQuery,
    (snapshot) => next(snapshot.docs.map((docSnap) => documentTo<NotificationEvent>(docSnap))),
    (err) => error(err.message),
  );
}

export function subscribeNotificationDeliveryAttempts(
  tenantId: string,
  eventId: string,
  next: (attempts: NotificationDeliveryAttempt[]) => void,
  error: (message: string) => void,
) {
  return onSnapshot(
    query(
      collection(db, 'tenants', tenantId, 'notificationEvents', eventId, 'deliveryAttempts'),
      orderBy('createdAt', 'desc'),
      limit(20),
    ),
    (snapshot) =>
      next(snapshot.docs.map((docSnap) => documentTo<NotificationDeliveryAttempt>(docSnap))),
    (err) => error(err.message),
  );
}
