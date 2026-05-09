# FiScore Firestore Schema Examples

## Purpose

This document provides sample Firestore JSON shapes for the tenant-facing FiScore app.

These are examples only:

- field sets may evolve
- not every field is required in every record
- examples are intentionally simplified for readability

Use [FIRESTORE_SCHEMA.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\app\FIRESTORE_SCHEMA.md) as the canonical schema reference.

## 1. Checklist Template

This first example represents a tenant-owned template that is available only to selected sites.

Document path:

`tenants/{tenantId}/checklistTemplates/{checklistTemplateId}`

```json
{
  "name": "Monthly Food Safety Internal Audit",
  "description": "Full internal food safety audit for restaurant operations.",
  "category": "food_safety",
  "templateSource": "tenant_custom",
  "templateScope": "tenant",
  "sourceTemplateId": null,
  "ownerUserId": "user_mgr_001",
  "ownerDisplayNameSnapshot": "Maria Thomas",
  "tagIds": ["food-safety", "monthly", "kitchen"],
  "tagLabels": ["Food Safety", "Monthly", "Kitchen"],
  "assignedSiteIds": ["site_1001", "site_1002"],
  "status": "published",
  "version": 3,
  "stableTemplateId": "chk_food_safety_monthly",
  "scoringConfig": {
    "method": "weighted_percentage",
    "excludeNotApplicableFromDenominator": true,
    "liveScoreEnabled": true
  },
  "gradeThresholds": [
    { "grade": "A", "minScore": 90, "maxScore": 100 },
    { "grade": "B", "minScore": 80, "maxScore": 89.99 },
    { "grade": "C", "minScore": 70, "maxScore": 79.99 },
    { "grade": "D", "minScore": 60, "maxScore": 69.99 },
    { "grade": "F", "minScore": 0, "maxScore": 59.99 }
  ],
  "criticalRules": [
    {
      "ruleId": "crit_001",
      "name": "Critical food temperature failure",
      "actionType": "grade_cap",
      "gradeCap": "B"
    }
  ],
  "sectionCount": 8,
  "questionCount": 54,
  "isActive": true,
  "publishedAt": "2026-05-07T09:00:00Z",
  "createdAt": "2026-04-20T13:10:00Z",
  "updatedAt": "2026-05-07T09:00:00Z"
}
```

In this example:

- the template is owned by the tenant
- only `site_1001` and `site_1002` can use it
- if `assignedSiteIds` were omitted or empty, it would be available to all sites in that tenant

## 1A. FiScore-Owned System Template Adopted By A Tenant

This example represents a FiScore-owned template made available inside one tenant.

Document path:

`tenants/{tenantId}/checklistTemplates/{checklistTemplateId}`

```json
{
  "name": "Daily Opening Food Safety Check",
  "description": "FiScore prebuilt checklist for opening food safety readiness.",
  "category": "food_safety",
  "templateSource": "fiscore_prebuilt",
  "templateScope": "system",
  "sourceTemplateId": "fiscore_chk_opening_001",
  "ownerUserId": null,
  "ownerDisplayNameSnapshot": null,
  "tagIds": ["opening", "daily", "food-safety"],
  "tagLabels": ["Opening", "Daily", "Food Safety"],
  "assignedSiteIds": [],
  "status": "published",
  "version": 1,
  "stableTemplateId": "fiscore_chk_opening_001",
  "scoringConfig": {
    "method": "weighted_percentage",
    "excludeNotApplicableFromDenominator": true,
    "liveScoreEnabled": true
  },
  "gradeThresholds": [
    { "grade": "A", "minScore": 90, "maxScore": 100 },
    { "grade": "B", "minScore": 80, "maxScore": 89.99 },
    { "grade": "C", "minScore": 70, "maxScore": 79.99 },
    { "grade": "D", "minScore": 60, "maxScore": 69.99 },
    { "grade": "F", "minScore": 0, "maxScore": 59.99 }
  ],
  "criticalRules": [],
  "sectionCount": 5,
  "questionCount": 28,
  "isActive": true,
  "publishedAt": "2026-05-07T09:00:00Z",
  "createdAt": "2026-05-07T09:00:00Z",
  "updatedAt": "2026-05-07T09:00:00Z"
}
```

In this example:

- the template originated from FiScore
- it is available inside the tenant
- `assignedSiteIds: []` means it is available to all sites in that tenant

## 2. Checklist Section

Document path:

`tenants/{tenantId}/checklistTemplates/{checklistTemplateId}/sections/{sectionId}`

```json
{
  "title": "Food Temperature Control",
  "description": "Cold holding, hot holding, and temperature verification checks.",
  "stableSectionId": "sec_temp_control",
  "displayOrder": 2,
  "weight": 20,
  "isScored": true,
  "createdAt": "2026-04-20T13:10:00Z",
  "updatedAt": "2026-05-07T09:00:00Z"
}
```

## 3. Checklist Question

Document path:

`tenants/{tenantId}/checklistTemplates/{checklistTemplateId}/sections/{sectionId}/questions/{questionId}`

```json
{
  "stableQuestionId": "q_hot_holding_135f",
  "prompt": "Are potentially hazardous foods held at 135F or above?",
  "helpText": "Hot-held foods must remain at or above the required safe holding temperature.",
  "answerType": "yes_no_na",
  "displayOrder": 4,
  "isRequired": true,
  "isScored": true,
  "maxPoints": 5,
  "weight": 1,
  "criticality": "critical",
  "allowsNotes": true,
  "allowsMedia": true,
  "allowsDocuments": false,
  "requiresSignature": false,
  "allowsBarcodeScan": false,
  "allowsQrScan": false,
  "capturesLocation": false,
  "measurementUnit": "F",
  "minValue": 135,
  "maxValue": null,
  "defaultValue": null,
  "predefinedNotes": [
    "Steam table below 135F.",
    "Product reheated and returned to compliant holding temperature.",
    "Equipment calibration needed."
  ],
  "allowsManualViolation": true,
  "responseOptions": [
    {
      "optionId": "yes",
      "label": "Yes",
      "value": "yes",
      "pointValue": 5,
      "isPassing": true,
      "isNotApplicable": false
    },
    {
      "optionId": "no",
      "label": "No",
      "value": "no",
      "pointValue": 0,
      "isPassing": false,
      "isNotApplicable": false
    },
    {
      "optionId": "na",
      "label": "N/A",
      "value": "na",
      "pointValue": 0,
      "isPassing": true,
      "isNotApplicable": true
    }
  ],
  "triggerRules": [
    {
      "ruleId": "rule_temp_001",
      "ruleType": "require_comment",
      "conditionOperator": "equals",
      "conditionValue": "no",
      "effectType": "require_comment",
      "effectPayload": {
        "required": true
      },
      "displayOrder": 1,
      "isActive": true
    },
    {
      "ruleId": "rule_temp_002",
      "ruleType": "require_photo",
      "conditionOperator": "equals",
      "conditionValue": "no",
      "effectType": "require_photo",
      "effectPayload": {
        "required": true
      },
      "displayOrder": 2,
      "isActive": true
    },
    {
      "ruleId": "rule_temp_003",
      "ruleType": "create_violation_on_submit",
      "conditionOperator": "equals",
      "conditionValue": "no",
      "effectType": "create_violation",
      "effectPayload": {
        "severity": "high",
        "title": "Hot holding temperature below safe threshold"
      },
      "displayOrder": 3,
      "isActive": true
    },
    {
      "ruleId": "rule_temp_004",
      "ruleType": "suggest_training",
      "conditionOperator": "equals",
      "conditionValue": "no",
      "effectType": "suggest_training",
      "effectPayload": {
        "trainingIds": ["trn_hot_holding_basics"]
      },
      "displayOrder": 4,
      "isActive": true
    }
  ],
  "createdAt": "2026-04-20T13:10:00Z",
  "updatedAt": "2026-05-07T09:00:00Z"
}
```

## 4. Audit Session

Document path:

`tenants/{tenantId}/audits/{auditId}`

```json
{
  "tenantId": "tenant_001",
  "siteId": "site_1001",
  "siteNameSnapshot": "FiScore Demo Kitchen - Downtown",
  "scheduleId": "sched_0901",
  "scheduleInstanceId": "inst_0901_2026_05_07",
  "auditOrigin": "scheduled",
  "checklistTemplateId": "chk_1001_v3",
  "checklistTemplateNameSnapshot": "Monthly Food Safety Internal Audit",
  "checklistVersion": 3,
  "scoringConfigVersion": 3,
  "status": "submitted",
  "startedAt": "2026-05-07T13:00:00Z",
  "startedBy": "user_aud_001",
  "completedAt": "2026-05-07T13:48:00Z",
  "completedBy": "user_aud_001",
  "submittedAt": "2026-05-07T13:49:00Z",
  "submittedBy": "user_aud_001",
  "offlineStarted": true,
  "offlineCompleted": true,
  "scorePercentage": 86,
  "defaultGrade": "A",
  "finalGrade": "B",
  "gradeWasAdjusted": true,
  "gradeAdjustmentSummary": "Critical hot-holding failure lowered the grade cap to B.",
  "criticalRuleSummary": [
    {
      "ruleId": "crit_001",
      "name": "Critical food temperature failure",
      "effect": "grade_cap:B"
    }
  ],
  "openViolationCount": 2,
  "syncStatus": "synced",
  "createdAt": "2026-05-07T13:00:00Z",
  "updatedAt": "2026-05-07T13:49:00Z"
}
```

## 5. Audit Response

Document path:

`tenants/{tenantId}/audits/{auditId}/responses/{responseId}`

```json
{
  "sectionId": "sec_temp_control",
  "sectionTitleSnapshot": "Food Temperature Control",
  "questionId": "q_0204",
  "stableQuestionId": "q_hot_holding_135f",
  "questionPromptSnapshot": "Are potentially hazardous foods held at 135F or above?",
  "questionDisplayOrder": 4,
  "responseType": "yes_no_na",
  "selectedOptionIds": ["no"],
  "selectedOptionLabels": ["No"],
  "numericValue": 128,
  "textValue": null,
  "dateValue": null,
  "timeValue": null,
  "dateTimeValue": null,
  "note": "Steam table holding at 128F. Product reheated and returned to 135F.",
  "commentRequired": true,
  "photoRequired": true,
  "signatureValue": null,
  "signatureCapturedAt": null,
  "barcodeValue": null,
  "qrValue": null,
  "locationCapture": null,
  "measurementValue": 128,
  "measurementUnit": "F",
  "scoreEarned": 0,
  "scorePossible": 5,
  "isNotApplicable": false,
  "isPassing": false,
  "isCriticalResponse": true,
  "prefilledFromAuditId": "audit_2026_04_07_1001",
  "prefilledFromResponseId": "resp_2026_04_07_0204",
  "prefillSuggestedValue": "yes",
  "previousAuditId": "audit_2026_04_07_1001",
  "previousResponseId": "resp_2026_04_07_0204",
  "previousResponseSummary": "Previously marked compliant.",
  "triggeredRuleIds": [
    "rule_temp_001",
    "rule_temp_002",
    "rule_temp_003",
    "rule_temp_004"
  ],
  "triggeredViolationIds": ["viol_2026_05_07_001"],
  "respondedAt": "2026-05-07T13:21:00Z",
  "respondedBy": "user_aud_001",
  "syncStatus": "synced",
  "createdAt": "2026-05-07T13:21:00Z",
  "updatedAt": "2026-05-07T13:22:00Z"
}
```

## 6. Manual Violation Created During Audit

This example reflects your clarified rule: the auditor can create a violation during the audit even when it was not initiated by a question response.

Document path:

`tenants/{tenantId}/violations/{violationId}`

```json
{
  "tenantId": "tenant_001",
  "siteId": "site_1001",
  "siteNameSnapshot": "FiScore Demo Kitchen - Downtown",
  "sourceType": "internal_audit",
  "sourceReferenceId": "audit_2026_05_07_1001",
  "sourceInspectionId": null,
  "sourceFindingId": null,
  "sourceQuestionResponseId": null,
  "violationType": "manual_audit_observation",
  "title": "Unlabeled spray bottle near prep station",
  "summaryText": "Chemical bottle near prep station was missing a label.",
  "displayText": "Unlabeled spray bottle near prep station",
  "clauseReference": null,
  "sectionLabel": "Chemical Safety",
  "questionLabel": null,
  "responseLabel": null,
  "severity": "medium",
  "priority": "normal",
  "status": "open",
  "identifiedAt": "2026-05-07T13:31:00Z",
  "identifiedBy": "user_aud_001",
  "assignedTo": "user_mgr_001",
  "dueDate": "2026-05-09T21:00:00Z",
  "requiresReview": true,
  "reviewStatus": "not_submitted",
  "reviewedAt": null,
  "reviewedBy": null,
  "closedAt": null,
  "closedBy": null,
  "reopenedAt": null,
  "reopenedBy": null,
  "currentResponseType": "structured",
  "latestResponseSummary": null,
  "latestEvidenceCount": 0,
  "syncStatus": "synced",
  "createdAt": "2026-05-07T13:31:00Z",
  "updatedAt": "2026-05-07T13:31:00Z"
}
```

## 7. Violation Response

Document path:

`tenants/{tenantId}/violations/{violationId}/responses/{responseId}`

```json
{
  "status": "submitted",
  "responseGeneral": "Bottle was identified during the internal audit and removed from the prep area immediately.",
  "responseContainment": "Removed the unlabeled bottle from the prep station and separated it from food-contact surfaces.",
  "responseRootCause": "Team member transferred cleaning solution into a spray bottle without applying the required secondary label.",
  "responseCorrectiveAction": "Bottle was labeled correctly and staff were reminded of the chemical labeling procedure.",
  "responsePreventiveAction": "Added labeling check to shift opening walkthrough and retrained team on secondary-container labeling.",
  "verificationNotes": "Manager confirmed labeled replacement bottle in place.",
  "submittedForReviewAt": "2026-05-07T15:12:00Z",
  "submittedForReviewBy": "user_staff_004",
  "approvedAt": null,
  "approvedBy": null,
  "rejectedAt": null,
  "rejectedBy": null,
  "rejectionReason": null,
  "latestThreadEntryId": "thread_0007",
  "createdAt": "2026-05-07T14:40:00Z",
  "createdBy": "user_staff_004",
  "updatedAt": "2026-05-07T15:12:00Z"
}
```

## 8. How To Read The Model

Simple mental model:

- `checklistTemplates` define what can be audited
- `sections` group questions
- `questions` define answer and trigger behavior
- `audits` represent one performed audit for one site
- `audit responses` are the actual answers
- `violations` are the tenant’s actionable issues
- `violation responses` are the official remediation records

## Summary

The FiScore app-side model should separate:

- reusable checklist definition
- actual audit execution
- site-scoped violation workflow

That separation keeps the model clean while still allowing:

- auto-created violations from submitted responses
- manual violations created during an audit
- public-inspection-origin violations
- consistent response and review behavior across all violation sources
