import type { Timestamp } from 'firebase/firestore';

export type Role = 'tenant_owner' | 'admin' | 'manager' | 'auditor' | 'staff';

export type UserProfile = {
  activeTenantId?: string;
  displayName?: string;
  email?: string;
  languagePreference?: 'en' | 'es';
  tenantIds?: string[];
};

export type Tenant = {
  id: string;
  name?: string;
  status?: string;
  primaryOwnerUserId?: string;
  subscriptionStatus?: string;
  billingProvider?: string;
  includedSiteCount?: number;
  activeSiteCount?: number;
};

export type Member = {
  id: string;
  userId?: string;
  displayNameSnapshot?: string;
  emailSnapshot?: string;
  role?: Role;
  status?: string;
  siteAccessMode?: 'all' | 'selected';
  siteIds?: string[];
};

export type Invite = {
  id: string;
  email?: string;
  role?: Role;
  status?: string;
  siteAccessMode?: 'all' | 'selected';
  siteIds?: string[];
};

export type Site = {
  id: string;
  name?: string;
  addressLine1?: string;
  city?: string;
  state?: string;
  stateCode?: string;
  postalCode?: string;
  zipCode?: string;
  phone?: string;
  siteType?: string;
  status?: string;
  linkStatus?: string;
  linkMethod?: string;
  masterRestaurantId?: string | null;
  manuallyCreated?: boolean;
  inspectionCountSnapshot?: number;
  latestInspectionDateSnapshot?: string;
  latestInspectionGradeSnapshot?: string;
  latestInspectionScoreSnapshot?: number;
  openViolationCountSnapshot?: number;
  pendingReviewCountSnapshot?: number;
  unassignedActiveViolationCountSnapshot?: number;
};

export type RestaurantSearchResult = {
  masterRestaurantId: string;
  displayName?: string;
  addressLine1?: string;
  city?: string;
  stateCode?: string;
  zipCode?: string;
  inspectionCount?: number;
  latestInspectionDate?: string;
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

export type NotificationEvent = {
  id: string;
  eventType?: string;
  channel?: string;
  status?: string;
  reason?: string;
  recipientEmail?: string;
  recipientUserId?: string;
  targetType?: string;
  targetId?: string;
  templateId?: string;
  locale?: string;
  provider?: string;
  providerMessageId?: string;
  dedupeHash?: string;
  renderedSubject?: string;
  renderedText?: string;
  renderedHtml?: string;
  createdAt?: Timestamp;
  queuedAt?: Timestamp;
  sentAt?: Timestamp;
  skippedAt?: Timestamp;
  suppressedAt?: Timestamp;
  failedAt?: Timestamp;
};

export type NotificationDeliveryAttempt = {
  id: string;
  channel?: string;
  provider?: string;
  status?: string;
  providerMessageId?: string;
  errorCode?: string;
  errorMessage?: string;
  renderedSubject?: string;
  renderedText?: string;
  renderedHtml?: string;
  createdAt?: Timestamp;
  attemptedAt?: Timestamp;
  completedAt?: Timestamp;
  sentAt?: Timestamp;
  failedAt?: Timestamp;
};

export type Violation = {
  id: string;
  siteId?: string;
  siteName?: string;
  title?: string;
  summaryText?: string;
  description?: string;
  displayText?: string;
  officialText?: string;
  officialCode?: string;
  officialClauseReference?: string;
  clauseReference?: string;
  sectionLabel?: string;
  normalizedCategory?: string;
  severity?: string;
  status?: string;
  lifecycleStage?: string;
  reviewStatus?: string;
  sourceType?: string;
  sourceTitleSnapshot?: string;
  sourceReferenceId?: string;
  masterInspectionId?: string;
  inspectionDate?: string;
  inspectionType?: string;
  inspectionScore?: number | string | null;
  inspectionGrade?: string | null;
  officialStatus?: string | null;
  auditorComments?: string;
  creatorComments?: string;
  comments?: string;
  questionLabel?: string;
  responseLabel?: string;
  correctedDuringInspection?: boolean | null;
  isRepeatViolation?: boolean | null;
  assignmentStatus?: string;
  assignedTo?: string | null;
  assignedToNameSnapshot?: string | null;
  responseGeneral?: string;
  responseContainment?: string;
  responseRootCause?: string;
  responseCorrectiveAction?: string;
  responsePreventiveAction?: string;
  latestThreadEntrySummary?: string;
  updatedAt?: Timestamp;
  submittedForReviewAt?: Timestamp;
  closedAt?: Timestamp;
};

export type ViolationAttachment = {
  id: string;
  displayName?: string;
  type?: string;
  attachmentType?: string;
  linkedContext?: string;
  status?: string;
  storagePath?: string;
  compressedPath?: string;
  thumbnailPath?: string;
  originalPath?: string;
  downloadUrl?: string;
  createdAt?: Timestamp;
};

export type ViolationThreadEntry = {
  id: string;
  body?: string;
  createdBy?: string;
  createdByDisplayNameSnapshot?: string;
  attachmentIds?: string[];
  createdAt?: Timestamp;
};

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

export type Audit = {
  id: string;
  siteId?: string;
  siteName?: string;
  type?: string;
  status?: string;
  templateId?: string;
  templateNameSnapshot?: string;
  templateSnapshot?: {
    id?: string;
    name?: string;
    sections?: Array<{
      id?: string;
      title?: string;
      questions?: Array<Record<string, unknown>>;
    }>;
  };
  startedAt?: Timestamp;
  startedBy?: string;
  startedByDisplayNameSnapshot?: string;
  assignedTo?: string;
  assignedToNameSnapshot?: string;
  submittedAt?: Timestamp;
  submittedBy?: string;
  completedAt?: Timestamp;
  completedBy?: string;
  scorePercentage?: number;
  resultLabel?: string;
  violationCount?: number;
  findingCount?: number;
  answeredQuestionCount?: number;
  createdViolationIds?: string[];
  auditAssignmentId?: string | null;
  updatedAt?: Timestamp;
};

export type AuditResponse = {
  id: string;
  sectionId?: string;
  sectionTitleSnapshot?: string;
  questionId?: string;
  questionPromptSnapshot?: string;
  answer?: 'pass' | 'needs_attention' | 'not_applicable' | string | null;
  note?: string;
  severity?: string | null;
  createsViolation?: boolean;
  answeredAt?: Timestamp;
  answeredBy?: string;
  updatedAt?: Timestamp;
};

export type PublicInspection = {
  id: string;
  siteId?: string;
  siteName?: string;
  tenantId?: string;
  masterRestaurantId?: string;
  masterInspectionId?: string;
  sourceId?: string;
  sourceSlug?: string;
  sourceName?: string;
  sourceInspectionKey?: string;
  inspectionDate?: string;
  inspectionType?: string;
  score?: number | string | null;
  grade?: string | null;
  officialStatus?: string | null;
  reportUrl?: string | null;
  reportAvailabilityStatus?: string | null;
  reportFormat?: string | null;
  masterReportStoragePath?: string | null;
  tenantReportAttachmentId?: string | null;
  tenantReportStoragePath?: string | null;
  tenantReportStatus?: string | null;
  findingCount?: number;
  importState?: string;
  importedAt?: Timestamp;
  updatedAt?: Timestamp;
};
