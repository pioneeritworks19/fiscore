import type { Timestamp } from 'firebase/firestore';

export type Role = 'tenant_owner' | 'admin' | 'manager' | 'auditor' | 'staff';

export type UserProfile = {
  activeTenantId?: string;
  displayName?: string;
  email?: string;
  languagePreference?: 'en' | 'es';
  tenantIds?: string[];
};

export type Activity = {
  id: string;
  action?: string;
  actorDisplayName?: string;
  actorEmail?: string;
  targetDisplayName?: string;
  targetEmail?: string;
  createdAt?: Timestamp;
};
