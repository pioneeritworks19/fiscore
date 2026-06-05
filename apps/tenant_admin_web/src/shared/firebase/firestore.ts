import type { DocumentData, QueryDocumentSnapshot } from 'firebase/firestore';

export function documentTo<T>(snapshot: QueryDocumentSnapshot<DocumentData>): T {
  return { id: snapshot.id, ...snapshot.data() } as T;
}

export function timestampMillis(value: unknown) {
  if (
    value &&
    typeof value === 'object' &&
    'toMillis' in value &&
    typeof value.toMillis === 'function'
  ) {
    return value.toMillis();
  }
  if (typeof value === 'string') {
    const time = new Date(value).getTime();
    return Number.isNaN(time) ? 0 : time;
  }
  return 0;
}
