import type { Timestamp } from 'firebase/firestore';

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
