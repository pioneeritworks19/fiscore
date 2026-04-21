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

All app data should be clearly scoped to a tenant. Tenant users should only access the data for restaurants and workflows that belong to their tenant.

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

The Firestore schema should center around tenants and their restaurants.

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
- `restaurants`
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

## 4. Tenant Restaurants

### Collection

`tenants/{tenantId}/restaurants/{restaurantId}`

### Purpose

Represents a restaurant location inside the tenant app context.

This is the tenant-owned restaurant record linked to the master data platform.

### Suggested fields

- `tenantId`
- `restaurantName`
- `normalizedRestaurantName`
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

- duplicate a few summary fields here to power restaurant list screens efficiently
- do not force the app to query many collections just to build the restaurant dashboard
- this collection is also the foundation for a tenant-level restaurants overview screen

### Recommended Summary Fields for Portfolio View

These fields are especially useful for a cross-restaurant landing page:

- `restaurantName`
- `city`
- `state`
- `latestInspectionDate`
- `latestInspectionScore`
- `latestInspectionGrade`
- `openViolationCount`
- `pendingReviewViolationCount`
- `lastAuditDate` if available later
- `draftAuditCount` if tracked later

## 5A. Future Restaurant Modules

FiScore should leave room under each tenant restaurant for future operational modules beyond inspections and violations.

Potential future collections may include:

- `tenants/{tenantId}/restaurants/{restaurantId}/assets/{assetId}`
- `tenants/{tenantId}/restaurants/{restaurantId}/complaints/{complaintId}`

These do not need to be implemented in version 1, but the restaurant-centered data model should leave clear space for them.

## 5. Restaurant Team Membership

If restaurant-level permissions become distinct from tenant-level permissions:

### Collection

`tenants/{tenantId}/restaurants/{restaurantId}/members/{userId}`

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

`tenants/{tenantId}/restaurants/{restaurantId}/publicInspections/{publicInspectionId}`

### Purpose

Stores tenant-readable projections of public inspection data for linked restaurants.

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

### Suggested `reportAvailability` values

- `official_available`
- `official_unavailable`
- `tenant_uploaded_only`
- `both`

## 6A. Public Inspection Report Attachments

### Collection

`tenants/{tenantId}/restaurants/{restaurantId}/publicInspections/{publicInspectionId}/reports/{reportId}`

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

`tenants/{tenantId}/restaurants/{restaurantId}/publicInspections/{publicInspectionId}/findings/{findingId}`

### Purpose

Stores tenant-readable public findings or violations from a public inspection.

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

- public findings can remain read-only here
- tenant-owned workflow records live separately in the tenant violation model

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
- `ownerUserId`
- `ownerDisplayNameSnapshot`
- `tagIds`
- `tagLabels`
- `assignedRestaurantIds`
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
- `create_action_on_submit`
- `flag_critical_response`

### Notes

- this collection is optional if rule objects remain small enough to embed in the question document
- use a dedicated collection if rules become numerous, reusable, or frequently edited

## 11. Audit Sessions

### Collection

`tenants/{tenantId}/audits/{auditId}`

### Purpose

Represents a specific audit execution for a restaurant.

### Suggested fields

- `tenantId`
- `restaurantId`
- `restaurantNameSnapshot`
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

Stores one-time and recurring audit schedule definitions for restaurants or sites.

### Suggested fields

- `tenantId`
- `restaurantId`
- `restaurantNameSnapshot`
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
- `siteId` can be optional if version 1 schedules are restaurant-level only

## 11B. Audit Schedule Instances

### Collection

`tenants/{tenantId}/auditSchedules/{scheduleId}/instances/{instanceId}`

### Purpose

Stores generated scheduled audit occurrences and their operational state.

### Suggested fields

- `scheduleId`
- `tenantId`
- `restaurantId`
- `restaurantNameSnapshot`
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

## 15. Violations

### Collection

`tenants/{tenantId}/violations/{violationId}`

### Purpose

Stores tenant-owned violation workflow records regardless of source.

### Suggested fields

- `tenantId`
- `restaurantId`
- `restaurantNameSnapshot`
- `sourceType`
- `sourceReferenceId`
- `sourceInspectionId`
- `sourceFindingId`
- `sourceQuestionResponseId`
- `violationType`
- `title`
- `summaryText`
- `displayText`
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

- this collection is top-level under the tenant because cross-restaurant filtering is important
- duplicate restaurant display fields here to support list and dashboard screens efficiently

## 16. Violation Responses

### Collection

`tenants/{tenantId}/violations/{violationId}/responses/{responseId}`

### Purpose

Stores simple responses and CAPA responses over the life of a violation.

### Suggested fields

- `responseType`
- `status`
- `summary`
- `correctiveAction`
- `preventiveAction`
- `rootCause`
- `verificationNotes`
- `submittedForReviewAt`
- `submittedForReviewBy`
- `approvedAt`
- `approvedBy`
- `rejectedAt`
- `rejectedBy`
- `rejectionReason`
- `createdAt`
- `createdBy`
- `updatedAt`

### Suggested `responseType` values

- `simple`
- `capa`

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
- `reason`
- `changedAt`
- `changedBy`
- `responseId`
- `reviewDecisionId`
- `createdAt`

## 20. Activity Feed

### Collection

`tenants/{tenantId}/activity/{activityId}`

### Purpose

Stores cross-tenant activity for dashboards and timeline views.

### Suggested fields

- `entityType`
- `entityId`
- `restaurantId`
- `restaurantNameSnapshot`
- `eventType`
- `summary`
- `performedBy`
- `performedAt`
- `createdAt`

### Notes

- useful for dashboards without querying many subcollections
- can be built by Cloud Functions or app-side event publishing

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

- restaurant name on audits and violations
- checklist name on audit sessions
- question prompt snapshots on audit responses
- latest score/grade summaries on restaurants
- latest response summary on violations
- source summary fields on tenant violation records

This duplication is normal and desirable for Firestore.

## Recommended Query Patterns

The schema should support these common queries efficiently:

- restaurants for a tenant
- audit schedules for a tenant filtered by restaurant and status
- upcoming or overdue audit schedule instances
- audits for a tenant filtered by restaurant and status
- violations for a tenant filtered by restaurant, status, assignee, severity, and due date
- latest public inspections for a restaurant
- findings for one public inspection
- responses for one audit
- responses and evidence for one violation

## Suggested Composite Index Areas

The exact index set will depend on app screens, but likely needs include:

- `auditSchedules` by `restaurantId + status`
- `auditSchedules` by `nextDueAt`
- `auditSchedules/{scheduleId}/instances` by `status + dueAt`
- `violations` by `restaurantId + status`
- `violations` by `status + assignedTo`
- `violations` by `status + dueDate`
- `audits` by `restaurantId + status`
- `audits` by `startedAt`
- `publicInspections` by `inspectionDate`

## Security Boundary Recommendations

### Top-Level Rule

Tenant users should only read and write data within tenants where they are members.

### Recommended Security Pattern

- check membership in `tenants/{tenantId}/members/{userId}`
- enforce role-based write restrictions for manager/owner-only actions
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
- `tenants/{tenantId}/restaurants`
- `tenants/{tenantId}/auditSchedules`
- `tenants/{tenantId}/auditSchedules/{scheduleId}/instances`
- `tenants/{tenantId}/audits`
- `tenants/{tenantId}/audits/{auditId}/responses`
- `tenants/{tenantId}/violations`
- `tenants/{tenantId}/violations/{violationId}/responses`
- `tenants/{tenantId}/restaurants/{restaurantId}/publicInspections`
- `tenants/{tenantId}/restaurants/{restaurantId}/publicInspections/{publicInspectionId}/findings`

These are enough to support the main tenant workflows.

## Summary

The FiScore Firestore schema should be a tenant-scoped NoSQL document model optimized for mobile screens, offline-first workflows, and efficient reads. It should use denormalized tenant-owned documents for audits, violations, responses, and restaurant summaries, while treating public inspection data as tenant-readable projections from the separate master-data platform.
