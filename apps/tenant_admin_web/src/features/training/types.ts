import type { Timestamp } from 'firebase/firestore';

export type TrainingAssignment = {
  id: string;
  siteId?: string;
  siteName?: string;
  linkedViolationId?: string;
  linkedViolationTitleSnapshot?: string;
  trainingTitleSnapshot?: string;
  trainingDescriptionSnapshot?: string;
  assignedToNameSnapshot?: string;
  assignedToEmailSnapshot?: string;
  assignedByNameSnapshot?: string;
  status?: string;
  dueDate?: Timestamp;
  dueAt?: Timestamp;
  completedAt?: Timestamp;
  createdAt?: Timestamp;
  updatedAt?: Timestamp;
  progressPercent?: number;
};
