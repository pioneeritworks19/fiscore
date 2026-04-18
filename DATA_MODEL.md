# FiScore Data Model

## Purpose

This document defines the core data model for FiScore based on the current product requirements. The goal is to provide a clear, implementation-ready conceptual model for Flutter and Firebase development while keeping the design aligned with the product documentation in `README.md`, `FEATURES.md`, `SYNC_STRATEGY.md`, and `SCORING_RULES.md`.

The data model is designed for:

- multi-tenant restaurant organizations
- offline-first mobile usage
- checklist-driven audits
- checklist-specific scoring and grading
- unified violation management
- support for health department and internal audit workflows

This is a conceptual and logical model, not a final Firestore schema. It is intended to define the main entities, relationships, and important fields before implementation.

## Design Principles

### 1. Tenant-Aware

All operational data should belong to a tenant so FiScore can support organizations with one or many restaurant locations.

### 2. Restaurant-Centric

Most workflows are performed in the context of a restaurant location. Core entities should therefore carry `restaurantId` when applicable.

### 3. Audit and Violation Traceability

Audits, findings, violations, responses, closures, and scoring outcomes should all be traceable to their source.

### 4. Offline-First Readiness

Entities should support local save, queued sync, conflict detection, and auditability.

### 5. Versioned Checklist Logic

Checklist templates and scoring logic should be versioned so historical audit results remain stable.

## Cross-Cutting Metadata

Most syncable entities should include common metadata fields.

Suggested shared fields:

- `id`
- `tenantId`
- `restaurantId` when applicable
- `createdAt`
- `createdBy`
- `updatedAt`
- `updatedBy`
- `deviceId`
- `revision`
- `syncStatus`
- `isDeleted`
- `deletedAt`
- `deletedBy`

Suggested `syncStatus` values:

- `pending`
- `synced`
- `failed`
- `conflict`

## High-Level Domain Areas

The current product scope can be grouped into these model areas:

- tenant and user management
- restaurants and membership
- audit checklist templates
- audit execution
- scoring and grading
- violations and remediation
- evidence attachments
- external inspection ingestion
- sync and audit trail support

## Core Entities

## 1. Tenant

Represents an organization that owns or manages one or more restaurant locations.

Suggested fields:

- `id`
- `name`
- `status`
- `primaryOwnerUserId`
- `settings`
- `subscriptionPlan` if needed later

Relationships:

- one tenant has many restaurants
- one tenant has many users through memberships
- one tenant has many checklist templates

## 2. User

Represents a person using FiScore.

Suggested fields:

- `id`
- `displayName`
- `email`
- `phoneNumber`
- `authProviders`
- `photoUrl`
- `status`
- `lastActiveAt`

Notes:

- Authentication may come from Google or Apple
- A user may belong to multiple tenants if the business allows it

## 3. Tenant Membership

Represents the user's role and access within a tenant.

Suggested fields:

- `id`
- `tenantId`
- `userId`
- `role`
- `status`
- `invitedBy`
- `invitedAt`
- `joinedAt`

Suggested roles:

- `owner`
- `manager`
- `staff`
- `auditor` if needed later

## 4. Restaurant

Represents a restaurant location within a tenant.

Suggested fields:

- `id`
- `tenantId`
- `name`
- `externalReference`
- `address`
- `city`
- `state`
- `postalCode`
- `country`
- `phoneNumber`
- `timezone`
- `status`
- `healthDepartmentMetadata`

Relationships:

- one restaurant has many audits
- one restaurant has many violations
- one restaurant may have many imported health inspections

## 5. Restaurant Membership

Represents which users can access which restaurant.

Suggested fields:

- `id`
- `tenantId`
- `restaurantId`
- `userId`
- `role`
- `status`

This allows a tenant-level user to have restaurant-specific permissions if needed.

## Checklist and Audit Template Model

## 6. Checklist Template

Represents an audit or inspection checklist definition.

Suggested fields:

- `id`
- `tenantId`
- `name`
- `description`
- `category`
- `status`
- `version`
- `isActive`
- `appliesTo`
- `scoringConfigId`
- `publishedAt`
- `archivedAt`

Examples:

- Daily Food Safety Audit
- Weekly Manager Walkthrough
- Opening Checklist
- Closing Checklist

Important notes:

- Each checklist template should be versioned
- Historical audits should reference the exact template version used

## 7. Checklist Section

Represents a section within a checklist template.

Suggested fields:

- `id`
- `checklistTemplateId`
- `version`
- `title`
- `description`
- `displayOrder`
- `weight` if section-level scoring is supported
- `isScored`

## 8. Checklist Question

Represents an individual checklist prompt.

Suggested fields:

- `id`
- `checklistTemplateId`
- `sectionId`
- `version`
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
- `allowsManualViolation`
- `responseRuleSetId`
- `violationTriggerRuleSetId`

Suggested `answerType` values:

- `yes_no`
- `pass_fail`
- `pass_fail_na`
- `single_select`
- `multi_select`
- `numeric`
- `text`
- `date`
- `score`

Suggested `criticality` values:

- `normal`
- `serious`
- `critical`

## 9. Question Response Option

Represents allowed answers for selectable question types.

Suggested fields:

- `id`
- `questionId`
- `label`
- `value`
- `displayOrder`
- `pointValue`
- `isPassing`
- `isCriticalTrigger`
- `createsViolationByDefault`
- `isNotApplicable`

## 10. Question Rule

Represents conditional logic, score logic, or violation rules connected to a question.

Suggested fields:

- `id`
- `questionId`
- `ruleType`
- `condition`
- `action`
- `priority`
- `isActive`

Suggested `ruleType` values:

- `show_followup_question`
- `require_note`
- `require_photo`
- `require_video`
- `create_violation`
- `grade_cap`
- `grade_downgrade`
- `auto_fail`

## Scoring Model

## 11. Scoring Configuration

Represents checklist-specific score and grade behavior.

Suggested fields:

- `id`
- `checklistTemplateId`
- `version`
- `scoringMethod`
- `gradeScaleType`
- `usesSectionWeighting`
- `excludeNotApplicableFromDenominator`
- `liveScoreEnabled`
- `criticalRulePrecedence`

Relationships:

- one scoring configuration has many grade thresholds
- one scoring configuration has many critical score rules

## 12. Grade Threshold

Represents the mapping from score range to grade.

Suggested fields:

- `id`
- `scoringConfigId`
- `gradeLabel`
- `minScore`
- `maxScore`
- `displayOrder`

Examples:

- `A` 95-100
- `B` 85-94.99

## 13. Critical Score Rule

Represents a rule that modifies final grade based on serious responses.

Suggested fields:

- `id`
- `scoringConfigId`
- `name`
- `triggerType`
- `condition`
- `actionType`
- `gradeCap`
- `gradeDowngradeSteps`
- `resultGrade`
- `createsViolation`
- `requiresManagerReview`
- `priority`

Suggested `actionType` values:

- `grade_cap`
- `grade_downgrade`
- `auto_fail`
- `require_review`

## Audit Execution Model

## 14. Audit Session

Represents an instance of a user performing a checklist audit for a restaurant.

Suggested fields:

- `id`
- `tenantId`
- `restaurantId`
- `checklistTemplateId`
- `checklistVersion`
- `scoringConfigVersion`
- `sourceType`
- `status`
- `startedAt`
- `startedBy`
- `completedAt`
- `completedBy`
- `submittedAt`
- `submittedBy`
- `deviceStartedOn`
- `deviceCompletedOn`
- `offlineStarted`
- `offlineCompleted`
- `scorePercentage`
- `defaultGrade`
- `finalGrade`
- `gradeWasAdjusted`
- `gradeAdjustmentSummary`

Suggested `status` values:

- `draft`
- `in_progress`
- `submitted`
- `completed`
- `archived`

Suggested `sourceType` values:

- `internal_audit`
- `manager_check`
- `opening_check`
- `closing_check`

## 15. Audit Section Result

Represents section-level progress or score information within an audit session.

Suggested fields:

- `id`
- `auditSessionId`
- `sectionId`
- `sectionTitleSnapshot`
- `displayOrder`
- `earnedPoints`
- `possiblePoints`
- `scorePercentage`
- `status`

This entity is optional if section state can be derived, but it is useful for fast reporting and progress tracking.

## 16. Audit Question Response

Represents the user's answer to a question during a specific audit session.

Suggested fields:

- `id`
- `auditSessionId`
- `sectionId`
- `questionId`
- `questionVersion`
- `questionPromptSnapshot`
- `responseType`
- `selectedOptionIds`
- `numericValue`
- `textValue`
- `dateValue`
- `note`
- `scoreEarned`
- `scorePossible`
- `isNotApplicable`
- `isPassing`
- `isCriticalResponse`
- `triggeredViolation`
- `triggeredRuleIds`
- `respondedAt`
- `respondedBy`

Important note:

- Snapshot fields are useful so completed audits remain historically accurate even if the checklist template changes later

## 17. Audit Result Snapshot

Represents the final scoring and grading output for a completed audit.

Suggested fields:

- `id`
- `auditSessionId`
- `checklistTemplateId`
- `checklistVersion`
- `scoringConfigId`
- `scoringConfigVersion`
- `totalEarnedPoints`
- `totalPossiblePoints`
- `scorePercentage`
- `defaultGrade`
- `finalGrade`
- `triggeredCriticalRuleIds`
- `scoreSummary`
- `gradeSummary`
- `calculatedAt`

This should be immutable once finalized, except for explicit administrative correction workflows.

## Violation Model

## 18. Violation

Represents a compliance or food safety issue that must be addressed.

Suggested fields:

- `id`
- `tenantId`
- `restaurantId`
- `sourceType`
- `sourceReferenceId`
- `sourceQuestionId`
- `sourceQuestionResponseId`
- `violationType`
- `title`
- `summaryText`
- `description`
- `displayText`
- `clauseReference`
- `sectionLabel`
- `questionLabel`
- `responseLabel`
- `severity`
- `priority`
- `status`
- `lifecycleStage`
- `identifiedAt`
- `identifiedBy`
- `assignedTo`
- `dueDate`
- `closedAt`
- `closedBy`
- `reopenedAt`
- `reopenedBy`
- `currentResponseType`
- `requiresReview`
- `reviewStatus`
- `reviewedAt`
- `reviewedBy`

Suggested `sourceType` values:

- `health_department_inspection`
- `internal_audit`
- `audit_auto_trigger`
- `manual`

Suggested `severity` values:

- `low`
- `medium`
- `high`
- `critical`

Suggested `status` or `lifecycleStage` values:

- `open`
- `in_progress`
- `pending_review`
- `closed`
- `reopened`

Notes:

- `status` and `lifecycleStage` may collapse into one field in implementation
- Violations should not be hard deleted in normal workflows
- `title`, `summaryText`, or `displayText` should provide a readable violation representation even when no deeper source structure exists
- Structured source fields such as clause, section, question, and response should be preserved when available so the UI can render richer context

## 19. Violation Source Detail

Represents source-specific metadata that may vary by violation origin.

Suggested patterns:

- separate subdocuments by source type
- or optional structured fields on the violation

### For Health Department Violations

Suggested fields:

- `inspectionId`
- `agencyName`
- `inspectionDate`
- `officialViolationCode`
- `officialClauseReference`
- `officialViolationText`
- `officialSeverity`
- `governmentSourceUrl`

### For Internal Audit Violations

Suggested fields:

- `auditSessionId`
- `checklistTemplateId`
- `checklistVersion`
- `sectionId`
- `sectionLabelSnapshot`
- `questionId`
- `questionLabelSnapshot`
- `responseId`
- `responseLabelSnapshot`
- `wasAutoCreated`

## 20. Violation Response

Represents work performed by a user in response to a violation.

Suggested fields:

- `id`
- `violationId`
- `responseType`
- `status`
- `summary`
- `correctiveAction`
- `preventiveAction`
- `rootCause`
- `verificationNotes`
- `submittedForReviewAt`
- `submittedForReviewBy`
- `closedRequestedAt`
- `closedRequestedBy`
- `createdAt`
- `createdBy`

Suggested `responseType` values:

- `simple`
- `capa`

Suggested `status` values:

- `draft`
- `submitted`
- `approved`
- `rejected`

Notes:

- There may be multiple responses over the life of one violation
- The latest approved response may be used for closure support

## 21. CAPA Plan

Represents structured corrective and preventive action details for a violation response.

Suggested fields:

- `id`
- `violationResponseId`
- `issueSummary`
- `rootCause`
- `correctiveActionPlan`
- `preventiveActionPlan`
- `responsiblePersonId`
- `targetCompletionDate`
- `actualCompletionDate`
- `effectivenessCheck`
- `effectivenessCheckedAt`
- `effectivenessCheckedBy`

This could also be embedded into `ViolationResponse` if the team prefers a simpler model.

## 22. Violation Review Decision

Represents manager or owner review of a submitted violation response.

Suggested fields:

- `id`
- `violationId`
- `violationResponseId`
- `decision`
- `notes`
- `reviewedAt`
- `reviewedBy`

Suggested `decision` values:

- `approved`
- `rejected`
- `needs_more_work`
- `closed`
- `reopened`

## 23. Violation Status History

Represents the lifecycle history of a violation.

Suggested fields:

- `id`
- `violationId`
- `fromStatus`
- `toStatus`
- `reason`
- `changedAt`
- `changedBy`
- `responseId`
- `reviewDecisionId`

This history is important for traceability and sync-safe auditing.

## Attachment Model

## 24. Attachment

Represents a media or document file connected to audits or violations.

Suggested fields:

- `id`
- `tenantId`
- `restaurantId`
- `ownerType`
- `ownerId`
- `attachmentType`
- `storagePath`
- `fileName`
- `mimeType`
- `fileSizeBytes`
- `durationSeconds`
- `thumbnailPath`
- `captureSource`
- `localOnly`
- `uploadStatus`
- `createdAt`
- `createdBy`

Suggested `ownerType` values:

- `audit_response`
- `violation`
- `violation_response`

Suggested `attachmentType` values:

- `image`
- `video`
- `document`

Suggested `uploadStatus` values:

- `pending`
- `uploading`
- `uploaded`
- `failed`

Best-practice notes:

- images and videos should be optimized for mobile
- large originals may not need to be retained on device after successful upload if product policy allows

## External Inspection Model

## 25. Health Department Inspection

Represents an imported official inspection record harvested from a government source.

Suggested fields:

- `id`
- `tenantId`
- `restaurantId`
- `agencyName`
- `inspectionDate`
- `inspectionType`
- `grade`
- `score`
- `reportUrl`
- `externalInspectionReference`
- `importedAt`
- `sourceStatus`

Relationships:

- one imported inspection may create many violations

## 26. Imported Inspection Finding

Represents a finding or violation harvested from an official inspection.

Suggested fields:

- `id`
- `inspectionId`
- `tenantId`
- `restaurantId`
- `code`
- `title`
- `description`
- `severity`
- `officialStatus`
- `identifiedAt`
- `mappedViolationId`

This model allows the system to preserve the official record even if a normalized `Violation` is also created for workflow purposes.

## Activity and Audit Trail Model

## 27. Domain Event

Represents an auditable business event.

Suggested fields:

- `id`
- `tenantId`
- `restaurantId`
- `entityType`
- `entityId`
- `eventType`
- `payloadSummary`
- `performedAt`
- `performedBy`
- `deviceId`

Examples:

- audit started
- audit completed
- violation created
- violation closed
- response submitted for review

## Sync Support Model

## 28. Sync Operation

Represents a queued local operation waiting to sync with the backend.

Suggested fields:

- `id`
- `entityType`
- `entityId`
- `operationType`
- `payload`
- `dependencyIds`
- `attemptCount`
- `lastAttemptAt`
- `lastErrorCode`
- `lastErrorMessage`
- `status`
- `createdAt`
- `createdBy`
- `deviceId`

Suggested `operationType` values:

- `create`
- `update`
- `delete`
- `upload_attachment`

Suggested `status` values:

- `queued`
- `processing`
- `failed`
- `completed`
- `conflict`

## Relationships Summary

Key relationship patterns:

- Tenant -> many Restaurants
- Tenant -> many Checklist Templates
- User -> many Tenant Memberships
- Restaurant -> many Audit Sessions
- Checklist Template -> many Sections
- Checklist Section -> many Questions
- Question -> many Response Options
- Checklist Template -> one active Scoring Configuration per version
- Audit Session -> many Audit Question Responses
- Audit Session -> one Audit Result Snapshot
- Audit Session -> many Violations
- Violation -> many Violation Responses
- Violation -> many Status History records
- Audit Response or Violation Response -> many Attachments
- Imported Health Inspection -> many Imported Inspection Findings
- Imported Inspection Finding -> optional mapped Violation

## Implementation Notes for Firestore

This document is conceptual, but a Firestore implementation should keep these realities in mind:

- some entities may be embedded for read efficiency
- some snapshot data should be duplicated intentionally for historical stability
- high-write subcollections may work better than giant root-level documents
- attachments likely need cloud storage plus metadata documents
- versioned checklist data should not rely only on mutable references

Likely candidates for snapshotting:

- question prompt text on completed responses
- scoring configuration version on audit session
- grade result summary on audit completion
- official violation text from imported inspection records

## Recommended Version 1 Priorities

For version 1, the most important entities to implement first are:

- Tenant
- User
- Restaurant
- Checklist Template
- Checklist Section
- Checklist Question
- Scoring Configuration
- Grade Threshold
- Audit Session
- Audit Question Response
- Audit Result Snapshot
- Violation
- Violation Response
- Attachment
- Health Department Inspection
- Imported Inspection Finding

These cover the essential operational workflows without overcomplicating the first release.

## Open Design Decisions

These items still need product and engineering decisions:

- whether restaurant membership should be separate from tenant membership
- whether CAPA should be embedded into violation response or modeled separately
- whether section results are stored or derived
- how much attachment metadata is stored locally versus only in cloud records
- whether review decisions are separate documents or part of violation history
- how aggressively to normalize imported government inspection data

## Summary

FiScore's data model should center on tenants, restaurants, versioned audit checklists, checklist-specific scoring, audit execution, and unified violation remediation. The model should preserve source traceability, support offline-first operation, and keep historical audit and scoring outcomes stable even as checklist definitions evolve.

The violation model in particular should support both simple text-based representation and richer structured context. Some violations may only have a short description and type, while others may need to preserve official clause references or internal section-question-response context for accurate display and reporting.
