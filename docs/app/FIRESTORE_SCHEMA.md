# FiScore Firestore Schema

## Purpose

This document defines the recommended Cloud Firestore schema for the tenant-facing FiScore application.

This schema is designed for:

- tenant-scoped restaurant operations
- mobile-first app usage
- offline-first workflows
- scheduled and recurring audits
- audit execution
- checklist scoring and grading
- violation lifecycle management
- CAPA response workflows
- lightweight synchronization support

This document is intentionally different from `MASTER_DATA_SCHEMA.md`.

- `MASTER_DATA_SCHEMA.md` describes the relational schema for the ingestion and master data platform
- `FIRESTORE_SCHEMA.md` describes the NoSQL document schema for the tenant-facing application

## Firestore Design Principles

### 1. Tenant Isolation

All app data should be clearly scoped to a tenant. Tenant users should only access the data for sites and workflows that belong to their tenant.

### 2. Document-Oriented Read Models

Documents should be shaped around app screens and common reads rather than normalized like SQL tables.

### 3. Denormalize for Read Efficiency

Firestore works best when important display and filter fields are duplicated intentionally rather than rebuilt through joins.

### 4. Preserve Snapshots for History

Checklist names, question text, scores, grades, and public source references should be snapshotted where historical accuracy matters.

### 5. Offline-First Support

Documents should be structured so mobile clients can:

- cache needed records locally
- save work offline
- show sync status clearly
- avoid depending on complex join-like reads

### 6. Keep Hot Documents Small

Avoid unbounded growth in single documents. Use subcollections for history, attachments, responses, and event streams when records can grow over time.

## Top-Level Strategy

The Firestore schema should center around tenants and their sites.

Recommended top-level collections:

- `users`
- `tenants`

Most tenant-owned operational data should live under:

- `tenants/{tenantId}/...`

This keeps authorization boundaries and query patterns clearer.

## 1. Users Collection

### Collection

`users/{userId}`

### Purpose

Stores user profile data used across tenants.

### Suggested fields

- `displayName`
- `email`
- `phoneNumber`
- `photoUrl`
- `authProviders`
- `status`
- `lastActiveAt`
- `createdAt`
- `updatedAt`

### Notes

- Authentication itself is handled by Firebase Authentication
- This collection stores app profile metadata, not credentials
- email should be treated as the primary invitation identifier in version 1
- `phoneNumber` is profile/contact information and should not be the primary tenant invite key in version 1

## 2. Tenants Collection

### Collection

`tenants/{tenantId}`

### Purpose

Represents a restaurant organization or customer account.

### Suggested fields

- `name`
- `status`
- `primaryOwnerUserId`
- `settings`
- `createdAt`
- `updatedAt`

### Example subcollections

- `members`
- `sites`
- `audits`
- `violations`
- `publicInspections`
- `activity`

## 3. Tenant Members

### Collection

`tenants/{tenantId}/members/{userId}`

### Purpose

Stores tenant-level access and role information for a user.

### Suggested fields

- `userId`
- `displayNameSnapshot`
- `emailSnapshot`
- `role`
- `status`
- `invitedBy`
- `invitedAt`
- `joinedAt`
- `createdAt`
- `updatedAt`

### Suggested `role` values

- `tenant_owner`
- `admin`
- `manager`
- `auditor`
- `staff`

## 4. Tenant Sites

### Collection

`tenants/{tenantId}/sites/{siteId}`

### Purpose

Represents a tenant site inside the tenant app context.

This is the tenant-owned site record used by the app. It may be linked to the master data platform or may exist as a manual unlinked site.

### Suggested fields

- `tenantId`
- `siteName`
- `normalizedSiteName`
- `addressLine1`
- `addressLine2`
- `city`
- `state`
- `zipCode`
- `countryCode`
- `timezone`
- `status`
- `masterRestaurantId`
- `locationFingerprint`
- `masterLinkStatus`
- `masterLinkMethod`
- `manuallyCreated`
- `manualEntrySource`
- `publicInspectionAvailability`
- `matchConfidence`
- `pendingMatchReview`
- `linkedAt`
- `linkedBy`
- `latestInspectionDate`
- `latestInspectionScore`
- `latestInspectionGrade`
- `openViolationCount`
- `pendingReviewViolationCount`
- `createdAt`
- `updatedAt`

### Notes

- duplicate a few summary fields here to power site list screens efficiently
- do not force the app to query many collections just to build the site dashboard
- this collection is also the foundation for a tenant-level sites overview screen
- this collection should support both linked and manual sites

### Suggested `masterLinkStatus` values

- `linked_to_master`
- `manual_unlinked`
- `pending_match_review`
- `archived`

### Suggested `publicInspectionAvailability` values

- `available`
- `unavailable_until_linked`
- `not_supported_for_source`

### Recommended Summary Fields for Portfolio View

These fields are especially useful for a cross-restaurant landing page:

- `siteName`
- `city`
- `state`
- `latestInspectionDate`
- `latestInspectionScore`
- `latestInspectionGrade`
- `openViolationCount`
- `pendingReviewViolationCount`
- `lastAuditDate` if available later
- `draftAuditCount` if tracked later

## 5A. Future Site Modules

FiScore should leave room under each tenant site for future operational modules beyond inspections and violations.

Potential future collections may include:

- `tenants/{tenantId}/sites/{siteId}/assets/{assetId}`
- `tenants/{tenantId}/sites/{siteId}/complaints/{complaintId}`

These do not need to be implemented in version 1, but the site-centered data model should leave clear space for them.

## 5. Site Team Membership

If restaurant-level permissions become distinct from tenant-level permissions:

### Collection

`tenants/{tenantId}/sites/{siteId}/members/{userId}`

### Suggested fields

- `userId`
- `role`
- `status`
- `assignedAt`
- `assignedBy`
- `createdAt`
- `updatedAt`

This can be deferred if tenant membership is enough for version 1.

## 6. Public Inspection Projections

### Collection

`tenants/{tenantId}/sites/{siteId}/publicInspections/{publicInspectionId}`

### Purpose

Stores tenant-readable projections of public inspection data for linked sites.

These are derived from the master data platform and should be treated as read-only from the tenant app perspective.

### Suggested fields

- `masterInspectionId`
- `sourceId`
- `agencyId`
- `agencyName`
- `jurisdictionName`
- `inspectionDate`
- `inspectionType`
- `score`
- `grade`
- `officialStatus`
- `reportUrl`
- `reportPdfUrl`
- `reportAvailability`
- `officialReportAvailable`
- `tenantOnsiteReportAvailable`
- `sourceVersionId`
- `importedAt`
- `createdAt`
- `updatedAt`

### Notes

- tenant users should not edit official public inspection content
- tenant workflows should link back to this projected record where relevant
- these records should only exist for sites that are linked to a master restaurant and have public data coverage

### Suggested `reportAvailability` values

- `official_available`
- `official_unavailable`
- `tenant_uploaded_only`
- `both`

## 6A. Public Inspection Report Attachments

### Collection

`tenants/{tenantId}/sites/{siteId}/publicInspections/{publicInspectionId}/reports/{reportId}`

### Purpose

Stores report metadata for both official public-source reports and tenant-uploaded onsite copies.

### Suggested fields

- `reportSourceType`
- `displayLabel`
- `storagePath`
- `downloadUrl`
- `fileName`
- `mimeType`
- `fileSizeBytes`
- `uploadStatus`
- `uploadedBy`
- `uploadedByDisplayNameSnapshot`
- `uploadedAt`
- `notes`
- `createdAt`
- `updatedAt`

### Suggested `reportSourceType` values

- `official_public_source`
- `tenant_uploaded_onsite_copy`

### Notes

- tenant-uploaded onsite copies should never replace official public-source report metadata
- if both exist, both should be visible in the inspection detail experience
- `official_public_source` records may be system-created and read-only
- `tenant_uploaded_onsite_copy` records are tenant-managed according to role permissions

## 7. Public Inspection Findings

### Collection

`tenants/{tenantId}/sites/{siteId}/publicInspections/{publicInspectionId}/findings/{findingId}`

### Purpose

Stores tenant-readable copies of public inspection findings for historical source visibility.

### Suggested fields

- `masterInspectionFindingId`
- `sourceFindingKey`
- `officialCode`
- `officialClauseReference`
- `officialText`
- `normalizedTitle`
- `normalizedCategory`
- `severity`
- `riskLevel`
- `sourceVersionId`
- `tenantViolationId`
- `wasImportedToTenantViolation`
- `createdAt`
- `updatedAt`

### Notes

- these records should remain read-only historical source records
- tenant-owned workflow records live separately in the tenant violation model
- the tenant app should treat violations, not public findings, as the actionable operational records

## 8. Audit Checklist Templates

If tenant-visible checklist templates are stored in Firestore:

### Collection

`tenants/{tenantId}/checklistTemplates/{checklistTemplateId}`

### Purpose

Stores tenant-usable checklist templates and versions for internal audits.

### Suggested fields

- `name`
- `description`
- `category`
- `templateSource`
- `templateScope`
- `sourceTemplateId`
- `ownerUserId`
- `ownerDisplayNameSnapshot`
- `tagIds`
- `tagLabels`
- `assignedSiteIds`
- `status`
- `version`
- `stableTemplateId`
- `scoringConfig`
- `gradeThresholds`
- `criticalRules`
- `sectionCount`
- `questionCount`
- `isActive`
- `publishedAt`
- `createdAt`
- `updatedAt`

### Notes

- some teams keep templates in Firestore
- some teams keep template definitions elsewhere and project read models into Firestore
- this doc assumes Firestore-hosted tenant-facing templates are acceptable for version 1
- `assignedSiteIds` should be treated as a tenant-side availability control
- if `assignedSiteIds` is empty or omitted, the template is available to all sites in that tenant
- if `assignedSiteIds` is populated, the template is restricted to those sites
- FiScore-owned system templates should be represented either through tenant-adopted copies or tenant-side enablement records before site assignment is applied

### Suggested `templateSource` values

- `fiscore_prebuilt`
- `tenant_custom`
- `tenant_cloned_from_prebuilt`

### Suggested `templateScope` values

- `system`
- `tenant`

## 9. Checklist Sections

### Collection

`tenants/{tenantId}/checklistTemplates/{checklistTemplateId}/sections/{sectionId}`

### Suggested fields

- `title`
- `description`
- `stableSectionId`
- `displayOrder`
- `weight`
- `isScored`
- `allowsSectionNotApplicable`
- `requiresNoteWhenSectionNotApplicable`
- `createdAt`
- `updatedAt`

## 10. Checklist Questions

### Collection

`tenants/{tenantId}/checklistTemplates/{checklistTemplateId}/sections/{sectionId}/questions/{questionId}`

### Suggested fields

- `stableQuestionId`
- `prompt`
- `helpText`
- `answerType`
- `displayOrder`
- `isRequired`
- `isScored`
- `maxPoints`
- `weight`
- `criticality`
- `allowsNotes`
- `allowsMedia`
- `allowsDocuments`
- `requiresSignature`
- `allowsBarcodeScan`
- `allowsQrScan`
- `capturesLocation`
- `measurementUnit`
- `minValue`
- `maxValue`
- `defaultValue`
- `predefinedNotes`
- `allowsManualViolation`
- `responseOptions`
- `triggerRules`
- `createdAt`
- `updatedAt`

### Notes

- embedding response options and trigger rules in the question document is often reasonable if they are not huge
- if they become very large or frequently edited, they can move to subcollections later
- `stableQuestionId` should remain consistent across checklist versions when the logical question is the same

## 10A. Question Rules

### Collection

`tenants/{tenantId}/checklistTemplates/{checklistTemplateId}/sections/{sectionId}/questions/{questionId}/rules/{ruleId}`

### Purpose

Stores conditional logic, required evidence rules, and auto-follow-up behavior for a question.

### Suggested fields

- `ruleType`
- `conditionOperator`
- `conditionValue`
- `conditionValues`
- `targetQuestionId`
- `targetStableQuestionId`
- `effectType`
- `effectPayload`
- `displayOrder`
- `isActive`
- `createdAt`
- `updatedAt`

### Suggested `ruleType` values

- `show_follow_up_question`
- `hide_question`
- `require_comment`
- `require_photo`
- `require_signature`
- `create_violation_on_submit`
- `flag_critical_response`
- `suggest_training`
- `flag_repeat_issue`

### Notes

- this collection is optional if rule objects remain small enough to embed in the question document
- use a dedicated collection if rules become numerous, reusable, or frequently edited

## 11. Audit Sessions

### Collection

`tenants/{tenantId}/audits/{auditId}`

### Purpose

Represents a specific audit execution for a site.

### Suggested fields

- `tenantId`
- `siteId`
- `siteNameSnapshot`
- `scheduleId`
- `scheduleInstanceId`
- `auditOrigin`
- `checklistTemplateId`
- `checklistTemplateNameSnapshot`
- `checklistVersion`
- `scoringConfigVersion`
- `status`
- `startedAt`
- `startedBy`
- `completedAt`
- `completedBy`
- `submittedAt`
- `submittedBy`
- `offlineStarted`
- `offlineCompleted`
- `scorePercentage`
- `defaultGrade`
- `finalGrade`
- `gradeWasAdjusted`
- `gradeAdjustmentSummary`
- `criticalRuleSummary`
- `openViolationCount`
- `sectionCount`
- `completedSectionCount`
- `notApplicableSectionCount`
- `unansweredQuestionCount`
- `flaggedQuestionCount`
- `syncStatus`
- `createdAt`
- `updatedAt`

### Suggested `status` values

- `draft`
- `in_progress`
- `submitted`
- `completed`
- `archived`

### Suggested `auditOrigin` values

- `ad_hoc`
- `scheduled`
- `recurring_schedule_instance`

## 11A. Audit Schedules

### Collection

`tenants/{tenantId}/auditSchedules/{scheduleId}`

### Purpose

Stores one-time and recurring audit schedule definitions for sites.

### Suggested fields

- `tenantId`
- `siteId`
- `siteNameSnapshot`
- `checklistTemplateId`
- `checklistTemplateNameSnapshot`
- `scheduleType`
- `title`
- `description`
- `assignedTo`
- `startsOn`
- `endsOn`
- `dueAt`
- `timezone`
- `recurrenceRule`
- `graceWindowDays`
- `status`
- `lastGeneratedAt`
- `lastCompletedAt`
- `nextDueAt`
- `createdBy`
- `createdAt`
- `updatedAt`

### Suggested `scheduleType` values

- `one_time`
- `recurring`

### Suggested `status` values

- `active`
- `paused`
- `completed`
- `cancelled`

### Notes

- one-time schedules can use `scheduleType = one_time` with `dueAt`
- recurring schedules can store a recurrence definition and generate child instances
- schedules should be site-scoped in version 1

## 11B. Audit Schedule Instances

### Collection

`tenants/{tenantId}/auditSchedules/{scheduleId}/instances/{instanceId}`

### Purpose

Stores generated scheduled audit occurrences and their operational state.

### Suggested fields

- `scheduleId`
- `tenantId`
- `siteId`
- `siteNameSnapshot`
- `checklistTemplateId`
- `checklistTemplateNameSnapshot`
- `scheduledFor`
- `dueAt`
- `status`
- `auditId`
- `startedAt`
- `startedBy`
- `completedAt`
- `completedBy`
- `missedAt`
- `overdueAt`
- `createdAt`
- `updatedAt`

### Suggested `status` values

- `scheduled`
- `in_progress`
- `completed`
- `overdue`
- `missed`
- `cancelled`

### Notes

- schedule instances give FiScore a durable record for expected versus completed audits
- `auditId` links the scheduled occurrence to the actual audit execution record when started
- overdue and missed should remain reportable even after later operational recovery

## 12. Audit Responses

### Collection

`tenants/{tenantId}/audits/{auditId}/responses/{responseId}`

### Purpose

Stores per-question audit responses.

### Suggested fields

- `sectionId`
- `sectionTitleSnapshot`
- `questionId`
- `stableQuestionId`
- `questionPromptSnapshot`
- `questionDisplayOrder`
- `responseType`
- `selectedOptionIds`
- `selectedOptionLabels`
- `numericValue`
- `textValue`
- `dateValue`
- `timeValue`
- `dateTimeValue`
- `note`
- `commentRequired`
- `photoRequired`
- `signatureValue`
- `signatureCapturedAt`
- `barcodeValue`
- `qrValue`
- `locationCapture`
- `measurementValue`
- `measurementUnit`
- `scoreEarned`
- `scorePossible`
- `isNotApplicable`
- `isPassing`
- `isCriticalResponse`
- `prefilledFromAuditId`
- `prefilledFromResponseId`
- `prefillSuggestedValue`
- `previousAuditId`
- `previousResponseId`
- `previousResponseSummary`
- `triggeredRuleIds`
- `triggeredViolationIds`
- `respondedAt`
- `respondedBy`
- `syncStatus`
- `createdAt`
- `updatedAt`

### Notes

- snapshot question text for historical accuracy
- avoid trying to reconstruct historical results from mutable templates later
- `stableQuestionId` supports prior-response lookup and cross-version reporting when question wording changes but the logical question remains the same

## 12A. Audit Section States

### Collection

`tenants/{tenantId}/audits/{auditId}/sections/{sectionStateId}`

### Purpose

Stores section-level execution state for long audits and section-based navigation.

### Suggested fields

- `sectionId`
- `stableSectionId`
- `sectionTitleSnapshot`
- `displayOrder`
- `status`
- `isNotApplicable`
- `notApplicableReason`
- `answeredQuestionCount`
- `unansweredQuestionCount`
- `flaggedQuestionCount`
- `scoreEarned`
- `scorePossible`
- `startedAt`
- `completedAt`
- `updatedAt`

### Suggested `status` values

- `not_started`
- `in_progress`
- `completed`
- `not_applicable`

## 13. Audit Attachments

### Collection

`tenants/{tenantId}/audits/{auditId}/responses/{responseId}/attachments/{attachmentId}`

### Purpose

Stores metadata for images, videos, or documents attached to an audit response.

### Suggested fields

- `attachmentType`
- `storagePath`
- `downloadUrl`
- `thumbnailUrl`
- `fileName`
- `mimeType`
- `fileSizeBytes`
- `durationSeconds`
- `captureSource`
- `uploadStatus`
- `localOnly`
- `createdAt`
- `createdBy`
- `updatedAt`

### Suggested `attachmentType` values

- `image`
- `video`
- `document`

## 14. Audit Result Snapshot

### Collection

`tenants/{tenantId}/audits/{auditId}/result/resultSnapshot`

### Purpose

Stores the final scoring and grading output for the audit.

### Suggested fields

- `totalEarnedPoints`
- `totalPossiblePoints`
- `scorePercentage`
- `defaultGrade`
- `finalGrade`
- `triggeredCriticalRules`
- `scoreSummary`
- `gradeSummary`
- `calculatedAt`
- `calculationVersion`

### Notes

- a single-document subcollection or embedded object both work
- if the result is modest in size, embedding inside the audit document is also acceptable

## 14A. Audit Reports

### Collection

`tenants/{tenantId}/audits/{auditId}/reports/{reportId}`

### Purpose

Stores metadata for both lightweight on-site audit summaries and final server-generated audit reports.

### Suggested fields

- `reportType`
- `storagePath`
- `downloadUrl`
- `fileName`
- `mimeType`
- `fileSizeBytes`
- `generationStatus`
- `generatedAt`
- `generatedBy`
- `createdAt`
- `updatedAt`

### Suggested `reportType` values

- `lightweight_summary_pdf`
- `final_server_report_pdf`

### Suggested `generationStatus` values

- `queued`
- `generated`
- `failed`

### Notes

- lightweight summary reports are intended for immediate operational use or on-site sharing
- final server-generated reports are the canonical audit report artifacts for the audit record

## 15. Violations

### Collection

`tenants/{tenantId}/violations/{violationId}`

### Purpose

Stores tenant-owned violation workflow records regardless of source.

### Suggested fields

- `tenantId`
- `siteId`
- `siteNameSnapshot`
- `sourceType`
- `sourceReferenceId`
- `sourceInspectionId`
- `sourceFindingId`
- `sourceQuestionResponseId`
- `violationType`
- `title`
- `summaryText`
- `displayText`
- `creatorComments`
- `clauseReference`
- `sectionLabel`
- `questionLabel`
- `responseLabel`
- `severity`
- `priority`
- `status`
- `identifiedAt`
- `identifiedBy`
- `assignedTo`
- `dueDate`
- `requiresReview`
- `reviewStatus`
- `reviewedAt`
- `reviewedBy`
- `closedAt`
- `closedBy`
- `reopenedAt`
- `reopenedBy`
- `currentResponseType`
- `latestResponseSummary`
- `latestEvidenceCount`
- `syncStatus`
- `createdAt`
- `updatedAt`

### Suggested `sourceType` values

- `health_department_inspection`
- `internal_audit`
- `audit_auto_trigger`
- `manual`

### Suggested `status` values

- `open`
- `in_progress`
- `pending_review`
- `closed`
- `reopened`

### Notes

- this collection is top-level under the tenant because cross-site filtering is important
- duplicate site display fields here to support list and dashboard screens efficiently
- the violation document should support a simple issue-summary read model for list and header screens
- richer source-context fields should remain available so the detail screen can explain why the violation was created
- manually created violations should support lightweight issue capture at creation time, including creator comments and optional evidence

## 16. Violation Responses

### Collection

`tenants/{tenantId}/violations/{violationId}/responses/{responseId}`

### Purpose

Stores the structured record of how a violation was addressed over its life cycle.

### Suggested fields

- `status`
- `responseGeneral`
- `responseContainment`
- `responseRootCause`
- `responseCorrectiveAction`
- `responsePreventiveAction`
- `verificationNotes`
- `submittedForReviewAt`
- `submittedForReviewBy`
- `approvedAt`
- `approvedBy`
- `rejectedAt`
- `rejectedBy`
- `rejectionReason`
- `latestThreadEntryId`
- `createdAt`
- `createdBy`
- `updatedAt`

## 16A. Violation Threads

### Collection

`tenants/{tenantId}/violations/{violationId}/threads/{threadEntryId}`

### Purpose

Stores discussion entries, status notes, assignment updates, and other operational thread history for a violation.

### Suggested fields

- `entryType`
- `body`
- `mentionedUserIds`
- `attachmentIds`
- `statusSnapshot`
- `assignmentSnapshot`
- `createdAt`
- `createdBy`
- `updatedAt`

### Suggested `entryType` values

- `comment`
- `status_update`
- `assignment_update`
- `photo_update`
- `system_note`

## 17. Violation Attachments

### Collection

`tenants/{tenantId}/violations/{violationId}/responses/{responseId}/attachments/{attachmentId}`

### Purpose

Stores metadata for evidence attached to violation responses.

### Suggested fields

- `attachmentType`
- `storagePath`
- `downloadUrl`
- `thumbnailUrl`
- `fileName`
- `mimeType`
- `fileSizeBytes`
- `durationSeconds`
- `uploadStatus`
- `localOnly`
- `createdAt`
- `createdBy`
- `updatedAt`

## 18. Violation Review Decisions

### Collection

`tenants/{tenantId}/violations/{violationId}/reviewDecisions/{decisionId}`

### Purpose

Stores manager or owner review outcomes for submitted responses.

### Suggested fields

- `responseId`
- `decision`
- `notes`
- `reviewedAt`
- `reviewedBy`
- `createdAt`

### Suggested `decision` values

- `approved`
- `rejected`
- `needs_more_work`
- `closed`
- `reopened`

## 19. Violation History

### Collection

`tenants/{tenantId}/violations/{violationId}/history/{historyId}`

### Purpose

Stores status transitions and important lifecycle events.

### Suggested fields

- `fromStatus`
- `toStatus`
- `eventType`
- `reason`
- `summary`
- `changedAt`
- `changedBy`
- `responseId`
- `reviewDecisionId`
- `createdAt`

### Suggested `eventType` values

- `created`
- `assigned`
- `status_changed`
- `submitted_for_review`
- `closed`
- `reopened`
- `rejected`
- `needs_more_work`

### Notes

- keep the current working status on the main violation document for fast reads
- keep the full lifecycle history in this subcollection for auditability and reporting
- important lifecycle events may also appear as `system_note` thread entries for user readability

## 20. Activity Feed

### Collection

`tenants/{tenantId}/activity/{activityId}`

### Purpose

Stores cross-tenant activity for dashboards and timeline views.

### Suggested fields

- `entityType`
- `entityId`
- `siteId`
- `siteNameSnapshot`
- `eventType`
- `summary`
- `performedBy`
- `performedAt`
- `createdAt`

### Notes

- useful for dashboards without querying many subcollections
- can be built by Cloud Functions or app-side event publishing

## 20A. Trainings

### Collection

`tenants/{tenantId}/trainings/{trainingId}`

### Purpose

Stores training content metadata available to the tenant.

### Suggested fields

- `title`
- `description`
- `trainingSource`
- `trainingType`
- `durationMinutes`
- `topicIds`
- `relatedRiskAreas`
- `status`
- `hasQuickCheck`
- `createdAt`
- `updatedAt`

### Suggested `trainingSource` values

- `fiscore_system`
- `tenant_custom`

### Suggested `trainingType` values

- `full_course`
- `micro_learning`

## 20B. Training Topics

### Collection

`tenants/{tenantId}/trainings/{trainingId}/topics/{topicId}`

### Purpose

Stores individual topics within a training item.

### Suggested fields

- `title`
- `description`
- `displayOrder`
- `estimatedMinutes`
- `createdAt`
- `updatedAt`

## 20C. Training Assignments

### Collection

`tenants/{tenantId}/trainingAssignments/{assignmentId}`

### Purpose

Stores assignments of training to users for operational remediation or improvement.

### Suggested fields

- `tenantId`
- `siteId`
- `trainingId`
- `assignedTo`
- `assignedBy`
- `dueDate`
- `status`
- `linkedViolationId`
- `linkedAuditId`
- `linkedRiskArea`
- `completedAt`
- `createdAt`
- `updatedAt`

### Suggested `status` values

- `assigned`
- `in_progress`
- `completed`
- `overdue`
- `cancelled`

### Notes

- `linkedViolationId` should be the main issue-level link for version 1
- `linkedAuditId` should be used when training is assigned from audit context
- `linkedRiskArea` should usually come from the training item or be derived from source context rather than typed manually during assignment

## 20D. Training Progress

### Collection

`tenants/{tenantId}/trainingAssignments/{assignmentId}/progress/{progressId}`

### Purpose

Stores progress or completion data for assigned training.

### Suggested fields

- `progressPercent`
- `startedAt`
- `lastActiveAt`
- `completedAt`
- `quickCheckResult`
- `acknowledgedAppliedAt`
- `createdAt`
- `updatedAt`

## 21. Sync Queue or Client Sync Metadata

Firestore itself handles offline caching, but FiScore may need explicit sync-state documents for trust-sensitive workflows.

### Option A: Per-document sync fields

Store fields such as:

- `syncStatus`
- `lastSyncedAt`
- `pendingOperationCount`
- `conflictStatus`

This is often enough for version 1.

### Option B: Dedicated sync records

`tenants/{tenantId}/syncRecords/{syncRecordId}`

Suggested fields:

- `entityType`
- `entityId`
- `operationType`
- `status`
- `lastErrorCode`
- `lastErrorMessage`
- `retryCount`
- `updatedAt`

This should only be added if product UX truly needs tenant-visible sync management beyond per-document state.

## Recommended Denormalization Rules

Firestore works best when certain fields are repeated intentionally.

Recommended duplicated fields:

- site name on audits and violations
- checklist name on audit sessions
- question prompt snapshots on audit responses
- latest score/grade summaries on sites
- latest response summary on violations
- source summary fields on tenant violation records

This duplication is normal and desirable for Firestore.

## Recommended Query Patterns

The schema should support these common queries efficiently:

- sites for a tenant
- manual unlinked sites for a tenant
- sites pending master-match review
- audit schedules for a tenant filtered by site and status
- upcoming or overdue audit schedule instances
- audits for a tenant filtered by site and status
- violations for a tenant filtered by site, status, assignee, severity, and due date
- latest public inspections for a site
- findings for one public inspection
- responses for one audit
- responses and evidence for one violation

## Suggested Composite Index Areas

The exact index set will depend on app screens, but likely needs include:

- `sites` by `masterLinkStatus`
- `sites` by `masterLinkStatus + zipCode`
- `auditSchedules` by `siteId + status`
- `auditSchedules` by `nextDueAt`
- `auditSchedules/{scheduleId}/instances` by `status + dueAt`
- `trainingAssignments` by `assignedTo + status`
- `trainingAssignments` by `siteId + status`
- `trainingAssignments` by `status + dueDate`
- `violations` by `siteId + status`
- `violations` by `status + assignedTo`
- `violations` by `status + dueDate`
- `audits` by `siteId + status`
- `audits` by `startedAt`
- `publicInspections` by `inspectionDate`

## Security Boundary Recommendations

### Top-Level Rule

Tenant users should only read and write data within tenants where they are members.

### Recommended Security Pattern

- check membership in `tenants/{tenantId}/members/{userId}`
- enforce role-based write restrictions for manager-only violation closure
- treat public inspection projections as read-only to tenant users
- allow tenant-owned records such as audits and violations to be writable according to role

## What Should Not Live Only in Firestore

The following should remain outside Firestore or have another system as the true source of truth:

- public inspection ingestion source registry
- scraper runs and parser diagnostics
- raw source artifacts
- canonical master restaurant records
- full operational review workflows for ingestion

Those belong to the ingestion/master-data platform.

## Version 1 Priority Collections

For version 1, the most important Firestore collections are:

- `users`
- `tenants`
- `tenants/{tenantId}/members`
- `tenants/{tenantId}/sites`
- `tenants/{tenantId}/auditSchedules`
- `tenants/{tenantId}/auditSchedules/{scheduleId}/instances`
- `tenants/{tenantId}/audits`
- `tenants/{tenantId}/audits/{auditId}/responses`
- `tenants/{tenantId}/violations`
- `tenants/{tenantId}/violations/{violationId}/threads`
- `tenants/{tenantId}/violations/{violationId}/responses`
- `tenants/{tenantId}/trainings`
- `tenants/{tenantId}/trainingAssignments`
- `tenants/{tenantId}/sites/{siteId}/publicInspections`
- `tenants/{tenantId}/sites/{siteId}/publicInspections/{publicInspectionId}/findings`

These are enough to support the main tenant workflows.

## Summary

The FiScore Firestore schema should be a tenant-scoped NoSQL document model optimized for mobile screens, offline-first workflows, and efficient reads. It should use denormalized tenant-owned documents for audits, violations, responses, and restaurant summaries, while treating public inspection data as tenant-readable projections from the separate master-data platform.
