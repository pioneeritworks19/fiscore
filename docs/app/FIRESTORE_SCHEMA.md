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
- `subscriptionPlan`
- `subscriptionStatus`
- `billingProvider`
- `includedSiteCount`
- `activeSiteCount`
- `enterpriseManaged`
- `currentPeriodStartsAt`
- `currentPeriodEndsAt`
- `foundingCohortEligible`
- `foundingCohortLabel`
- `createdAt`
- `updatedAt`

### Example subcollections

- `members`
- `sites`
- `audits`
- `violations`
- `publicInspections`
- `billingPurchases`
- `billingEvents`
- `activity`

### Suggested `subscriptionStatus` values

- `trial`
- `active`
- `past_due`
- `cancelled`
- `expired`
- `enterprise_managed`

### Suggested `billingProvider` values

- `app_store`
- `play_store`
- `enterprise`
- `none`

### Notes

- FiScore should treat billing as tenant-level entitlement rather than user-level access
- `includedSiteCount` should represent how many active sites the tenant has paid for
- `activeSiteCount` should reflect how many non-archived sites currently count against entitlement
- `enterpriseManaged` should disable self-serve paywall behavior in normal app flows

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

## 3A. Tenant Billing Purchases

### Collection

`tenants/{tenantId}/billingPurchases/{purchaseId}`

### Purpose

Stores verified purchase records and entitlement-affecting billing transactions for a tenant.

### Suggested fields

- `tenantId`
- `billingProvider`
- `productType`
- `productId`
- `purchaseToken`
- `originalTransactionId`
- `purchasedByUserId`
- `purchasedAt`
- `effectiveStartsAt`
- `effectiveEndsAt`
- `status`
- `siteIncrementCount`
- `isFoundingOffer`
- `createdAt`
- `updatedAt`

### Suggested `productType` values

- `starter_annual_1_site`
- `additional_site_annual`
- `enterprise_override`

### Suggested `status` values

- `pending_verification`
- `active`
- `renewed`
- `expired`
- `cancelled`
- `refunded`
- `failed`

### Notes

- one purchase should not be assumed to equal one user entitlement
- purchase records should be mapped to the tenant so multiple tenant members can benefit from the subscription
- store-specific identifiers such as `purchaseToken` or `originalTransactionId` should support backend verification and support workflows

## 3B. Tenant Billing Events

### Collection

`tenants/{tenantId}/billingEvents/{billingEventId}`

### Purpose

Stores normalized billing lifecycle events for auditability and support.

### Suggested fields

- `tenantId`
- `eventType`
- `billingProvider`
- `purchaseId`
- `summary`
- `effectiveAt`
- `performedByUserId`
- `createdAt`

### Suggested `eventType` values

- `subscription_started`
- `subscription_renewed`
- `subscription_past_due`
- `subscription_cancelled`
- `subscription_expired`
- `site_entitlement_increased`
- `enterprise_override_applied`

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

## 7A. FiScore Library Published Content

### Collections

`fiscoreLibrary/checklist/items/{libraryItemId}`

`fiscoreLibrary/training/items/{libraryItemId}`

Published library items are summary/current-pointer documents. Immutable
published content is stored below each item:

`fiscoreLibrary/{contentType}/items/{libraryItemId}/versions/{libraryVersion}`

The summary document includes `currentVersion` and
`latestPublishedVersion`. Tenant adoption copies the chosen version content
and stores `libraryVersionPath`; previously assigned content remains captured
in assignment snapshots.

### Purpose

Stores FiScore-authored published content available for tenants to discover
and selectively adopt into `My Library`.

### Notes

- the early implementation bootstraps starter published records from
  server-owned curated definitions
- tenants do not execute audits or assignments from these central records
- adopting content creates or updates a tenant-owned operational record
- a future FiScore administration workflow should publish new versions here
  instead of relying on code-maintained starter content

## 8. Audit Checklist Templates

If tenant-visible checklist templates are stored in Firestore:

### Collection

`tenants/{tenantId}/checklistTemplates/{checklistTemplateId}`

### Purpose

Stores tenant-usable checklist templates and versions for internal audits.

For the current internal-audit MVP, `Food Safety Walkthrough` and
`Opening Readiness Check` are available from FiScore Library and become
tenant-owned documents in this collection when explicitly adopted. New audit
sessions are started only from these tenant records and store the selected
template snapshot on the audit document.

In the library browsing experience, managers select individual FiScore
checklists from `Explore FiScore Library` and adopt them into `My Library`.
Future tenant-authored checklists use this same collection with
`templateSource = tenant_custom`.

### Suggested fields

- `name`
- `description`
- `category`
- `templateSource`
- `templateScope`
- `sourceTemplateId`
- `libraryTemplateId`
- `libraryVersion`
- `syncMode`
- `syncStatus`
- `lastSyncedAt`
- `updateAvailable`
- `detachedFromLibraryAt`
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
- checklist versions should normally be editable while in `draft`
- once a checklist version is published, that version should be treated as immutable for normal editing
- later changes should create a new draft version rather than modifying the published version in place
- one published version should be treated as the active version for future audit creation
- `assignedSiteIds` should be treated as a tenant-side availability control
- if `assignedSiteIds` is empty or omitted, the template is available to all sites in that tenant
- if `assignedSiteIds` is populated, the template is restricted to those sites
- FiScore-owned library templates should be represented through tenant-owned copies or tenant-side enablement records before site assignment is applied
- tenant audits should never execute directly against mutable library records
- synced library upgrades should create or activate a newer tenant version for future audits rather than mutating the tenant version already tied to historical audits
- TODO: add a tenant checklist editor, category/filter metadata, recently used
  and suggested checklist discovery, and library sync/detach management after
  the starter workflow is validated

### Suggested `templateSource` values

- `library_synced`
- `library_copied`
- `tenant_custom`

### Suggested `templateScope` values

- `library`
- `tenant`

### Suggested `syncMode` values

- `synced_from_library`
- `created_from_library`
- `tenant_custom`

### Suggested `syncStatus` values

- `up_to_date`
- `update_available`
- `detached`
- `never_synced`

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
- `stableChecklistTemplateId`
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

### Notes

- audit sessions should always be created against a published checklist version
- `checklistVersion` should represent the exact published version used when the audit was created
- historical audit sessions should remain tied to that version even after newer checklist versions are published

## 11A. Assigned Checks (Implemented MVP)

### Collection

`tenants/{tenantId}/sites/{siteId}/auditAssignments/{assignmentId}`

### Purpose

Stores one-time internal checks assigned to a teammate, without introducing
recurring scheduling complexity.

### Suggested fields

- `templateId`
- `templateVersion`
- `templateNameSnapshot`
- `templateSnapshot`
- `assignedTo`
- `assignedToNameSnapshot`
- `assignedBy`
- `assignmentSource`
- `dueDate`
- `assignmentNote`
- `status`
- `auditId`
- `startedAt`
- `completedAt`
- `cancelledAt`
- `createdAt`
- `updatedAt`

### Suggested `status` values

- `assigned`
- `in_progress`
- `completed`
- `cancelled`

### Suggested `assignmentSource` values

- `assigned`
- `self_started`

### Notes

- the assignment stores the checklist snapshot used when it was assigned
- starting an assignment creates an audit session linked by `auditId`
- selecting `Start check` creates a `self_started` assignment owned by the
  signed-in user so an incomplete check remains visible in their action inbox
- an assignee action item is created, completed, reassigned, cancelled, or
  marked overdue through trusted Cloud Functions

## 11B. Audit Schedules (Future)

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

## 11C. Audit Schedule Instances (Future)

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
- `version`
- `libraryTrainingId`
- `libraryVersion`
- `syncMode`
- `syncStatus`
- `lastSyncedAt`
- `updateAvailable`
- `detachedFromLibraryAt`
- `trainingType`
- `durationMinutes`
- `topicIds`
- `relatedRiskAreas`
- `status`
- `hasQuickCheck`
- `topicSummaries`
- `sections`
- `quickCheckQuestions`
- `createdAt`
- `updatedAt`

### Suggested `trainingSource` values

- `library_synced`
- `library_copied`
- `tenant_custom`

### Suggested `trainingType` values

- `full_course`
- `micro_learning`

### Suggested `syncMode` values

- `synced_from_library`
- `created_from_library`
- `tenant_custom`

### Suggested `syncStatus` values

- `up_to_date`
- `update_available`
- `detached`
- `never_synced`

### Version 1 starter-library note

- starter FiScore training is adopted into tenant-owned `trainings` documents through an authorized library action
- managers select individual FiScore lessons from `Explore FiScore Library`
  and adopt them into tenant-owned `trainings` documents
- the app assigns from those tenant-owned documents rather than bundling runtime training content inside the mobile client
- `topicSummaries` is a small listing read model for short micro-learning
- starter micro-learning may store compact `sections` and `quickCheckQuestions` directly on the training document
- future tenant-authored training uses the same collection with
  `trainingSource = tenant_custom`

Training documents may include a `mediaAssets` map keyed by generated
`mediaId`. Each media record stores fields such as `type`, `fileName`,
`contentType`, `storagePath`, `altText`, `durationLabel`, and `required`.

Training `sections` may also contain ordered `blocks` for visual lessons:

- `type`: `text`, `image`, `video`, or `tip`
- `body`: text or tip content where applicable
- `mediaId`: reference to the `mediaAssets` record for image/video blocks
- `caption`: user-facing media description
- `durationLabel`: user-facing video duration where applicable
- media behavior such as `required` is defined by the referenced media record

FiScore Library media is referenced by tenant-synced training documents and
assignment snapshots. Media files are not duplicated into tenant storage.

Storage convention:

`fiscoreLibrary/training/{libraryTrainingId}/versions/{libraryVersion}/media/{mediaId}/{fileName}`

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
- `trainingVersion`
- `assignedTo`
- `assignedBy`
- `dueDate`
- `status`
- `linkedViolationId`
- `linkedRiskArea`
- `trainingTopicsSnapshot`
- `trainingSectionsSnapshot`
- `quickCheckQuestionsSnapshot`
- `hasQuickCheckSnapshot`
- `incorrectAnswerCount`
- `quickCheckCompletedAt`
- `completedTopicCount`
- `completionSummarySnapshot`
- `cancelledAt`
- `cancelledBy`
- `cancelledByNameSnapshot`
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
- version 1 should not store audit or audit-question linkage on assignments; when an internal audit requires follow-up training, its created violation is the training link
- `linkedRiskArea` should usually come from the training item or be derived from source context rather than typed manually during assignment
- `trainingVersion` should preserve which version the user was assigned
- content snapshot fields preserve exactly what the assigned user reviewed and completed
- assignment creation should require the assignee to be an active tenant member with access to the assignment site
- existing assignments should remain tied to their assigned version even if a newer training version becomes active later
- library-linked training upgrades should affect future assignments only after the tenant adopts the newer tenant version

## 20D. Action Items

### Collection

`tenants/{tenantId}/actionItems/{actionItemId}`

### Purpose

Stores read-optimized operational work items for the dashboard and action
inbox. The linked violation or training assignment remains the authoritative
workflow record.

### Suggested fields

- `type`
- `status`
- `priority`
- `recipientUserId`
- `recipientRoleSnapshot`
- `siteId`
- `siteNameSnapshot`
- `targetType`
- `targetId`
- `targetPath`
- `targetKey`
- `title`
- `detail`
- `dueAt`
- `dueState`
- `assignmentSourceSnapshot`
- `managerVisible`
- `readAt`
- `completedAt`
- `completionReason`
- `createdAt`
- `updatedAt`

### Notes

- Action items are server-owned and should not be created or completed by clients.
- Callable Cloud Functions create and resolve items during workflow transitions.
- Scheduled Cloud Functions may update due-state for overdue training and
  assigned checks.
- Draft responses, notes, and media remain direct collaborative writes and do not each create action items.

## 20E. Training Progress

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
- tenant billing purchases by status or provider
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
- `billingPurchases` by `status + purchasedAt`
- `billingPurchases` by `billingProvider + status`
- `auditSchedules` by `siteId + status`
- `auditSchedules` by `nextDueAt`
- `auditSchedules/{scheduleId}/instances` by `status + dueAt`
- `trainingAssignments` by `assignedTo + status`
- `trainingAssignments` by `siteId + status`
- `trainingAssignments` by `status + dueDate`
- `actionItems` by `recipientUserId + status + siteId`
- `actionItems` by `managerVisible + status + siteId`
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
