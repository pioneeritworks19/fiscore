# FiScore Operational Workflows

## Purpose

This document defines the day-to-day operational workflows for FiScore version 1.

It focuses on how tenant users move through the product during normal usage, including:

- tenant setup
- restaurant linking
- user invitation
- restaurant switching
- public inspection import behavior
- internal audit execution
- violation creation and response
- review, closure, and reopening

This document intentionally focuses on operational usage rather than checklist template authoring or scoring-rule design.

## Scope

The following workflows are included in version 1:

- tenant registration
- add restaurant from master list
- invite user
- switch restaurant
- import public inspections and findings
- upload onsite health department report
- create internal audit
- complete internal audit
- auto-create violation from audit
- manually add violation
- respond to violation
- submit violation for review
- manager closes violation
- reopen violation

## Workflow Principles

### 1. Restaurant Context Is Central

The app should always make it clear which restaurant the user is currently working in. Users work in one restaurant at a time and switch context when needed.

### 2. Public Data and Tenant Workflows Are Separate

Public inspections and findings are brought into the tenant for internal use, but the tenant's responses and remediation activity remain private to the tenant.

### 3. Audits Are Offline-First

Internal audits are a primary offline workflow. Users should be able to complete an audit without connectivity and sync should happen when the audit is submitted.

### 4. Violation Closure Is Manager-Controlled

Staff and auditors can contribute to the response process, but managers control final closure in version 1.

### 5. Historical Traceability Matters

Even when a workflow is simple from the user's perspective, the system should preserve source links, audit context, and lifecycle history behind the scenes.

## 1. Tenant Registration Workflow

### Goal

Allow the first user to create a tenant and become the tenant owner.

### Primary Actor

- tenant owner

### Steps

1. user signs up using supported authentication
2. user creates a tenant profile
3. user becomes the `tenant_owner`
4. tenant record is created
5. user is taken into the app onboarding flow

### Result

- tenant exists
- tenant owner exists
- app is ready for restaurant linking

## 2. Add Restaurant from Master List Workflow

### Goal

Allow a tenant to add a restaurant by linking to the FiScore master restaurant list.

### Primary Actors

- tenant owner
- admin

### Preconditions

- tenant already exists
- user has permission to add restaurants

### Steps

1. user starts the add restaurant flow
2. user enters a zip code
3. FiScore searches the master restaurant list for that zip code
4. user filters or searches by restaurant name
5. FiScore shows candidate restaurants
6. user selects the correct restaurant
7. FiScore creates the tenant restaurant record
8. FiScore creates the tenant-to-master restaurant link
9. FiScore imports all historical public inspections for that restaurant into tenant-readable projections
10. FiScore imports public findings for those inspections
11. FiScore automatically creates tenant violations only for findings from the most recent public inspection
12. older public findings remain visible, but users choose whether to activate or work them as tenant violations

### Result

- restaurant is linked to the tenant
- full public inspection history is available in tenant context
- latest inspection findings become active tenant violations automatically

### Important Product Rule

Only the latest public inspection findings should auto-create tenant violations. This keeps the initial workload focused and avoids overwhelming a newly linked restaurant with every historical finding becoming active at once.

## 3. Remove Restaurant Workflow

### Goal

Allow a tenant owner or admin to remove a restaurant from the tenant with clear warning about data consequences.

### Primary Actors

- tenant owner
- admin

### Preconditions

- restaurant is already linked to the tenant

### Steps

1. user initiates restaurant removal
2. FiScore shows a warning that removing the restaurant will remove tenant-side restaurant data associated with that tenant context
3. user must explicitly acknowledge the warning
4. FiScore removes the restaurant from the tenant
5. FiScore removes or archives tenant-owned workflows associated with that restaurant according to the final implementation policy

### Recommended Warning Message Direction

The user should clearly understand that removing and re-adding a restaurant may create data continuity issues and should not be treated as a casual action.

### Recommended Product Note

Version 1 should strongly prefer explicit confirmation before restaurant removal because re-adding the restaurant later could create confusion around prior imported findings and tenant workflows.

## 4. Invite User Workflow

### Goal

Allow admins and managers to invite users into the tenant.

### Primary Actors

- admin
- manager

### Steps

1. inviter opens team management
2. inviter enters the user's email and assigns a role
3. inviter optionally assigns restaurant access
4. invitation record is created
5. invited user receives the invitation
6. invited user accepts and joins the tenant

### Result

- user becomes a tenant member
- user receives role-based access

## 5. Switch Restaurant Workflow

### Goal

Allow users with access to multiple restaurants to switch the active restaurant context.

### Primary Actors

- all tenant users with restaurant access

### Rules

- tenant owner and admin can see all restaurants in the tenant
- other users only see restaurants they are assigned to
- the app shows one restaurant at a time

### Steps

1. user opens the restaurant switcher
2. FiScore lists restaurants the user can access
3. user selects a restaurant
4. app updates current restaurant context
5. screens refresh to show that restaurant's audits, violations, and public data

## 6. Import Public Inspections and Findings Workflow

### Goal

Bring public inspection history into tenant context after restaurant linking.

### Primary Trigger

- add restaurant from master list

### Steps

1. FiScore identifies the linked master restaurant
2. FiScore pulls all historical public inspections for that restaurant
3. FiScore stores tenant-readable projections of those inspections
4. FiScore pulls all public findings associated with those inspections
5. FiScore stores tenant-readable finding projections
6. FiScore auto-creates tenant violations only from findings on the most recent inspection
7. historical findings from older inspections remain visible without automatically becoming active tenant violations

### Result

- tenant users can review public inspection history
- the latest public inspection becomes immediately actionable

## 7. Create Internal Audit Workflow

## 6A. Upload Onsite Health Department Report Workflow

### Goal

Allow permitted tenant users to attach a copy of the onsite health department inspection report when the public source does not provide the official report document.

### Primary Actors

- tenant owner
- admin
- manager
- auditor

### Preconditions

- a public inspection record already exists for the restaurant
- the user has permission to upload supporting inspection documents

### Steps

1. user opens a public inspection detail screen
2. FiScore shows whether an official report is available from the public source
3. if no official report exists, FiScore offers an `Upload Onsite Copy` action
4. user uploads a PDF, image, or scanned copy of the onsite report
5. FiScore stores the file as a tenant-provided document linked to that specific public inspection
6. FiScore records who uploaded the document and when
7. the inspection detail screen shows the report as a tenant-uploaded onsite copy

### Important Rule

The uploaded onsite report must be clearly labeled as tenant-provided and must not be treated as the official public-source artifact.

### Result

- the tenant has a more complete inspection record
- the uploaded report can support review, remediation, and future inspection preparation

## 7. Create Internal Audit Workflow

### Goal

Allow a manager or auditor to start an internal audit for a restaurant.

### Primary Actors

- manager
- auditor

### Preconditions

- user is in a restaurant context
- checklist template exists

### Steps

1. user chooses to start an audit
2. user selects the checklist template
3. FiScore creates an audit session in `draft` or `in_progress` state
4. checklist content is loaded onto the device
5. user begins responding to questions

### Offline Behavior

- this workflow should support offline usage
- audit content should be available locally once the audit starts
- responses should save locally during the audit

## 8. Save and Resume Audit Workflow

### Goal

Allow the same user to save an audit draft and return later.

### Primary Actors

- manager
- auditor

### Rules

- audit drafts are supported
- only the original user should resume that draft in version 1

### Steps

1. user starts an audit
2. user answers part of the checklist
3. audit remains saved as draft or in-progress
4. user leaves the workflow
5. later, the same user resumes the audit
6. FiScore restores saved responses and progress

## 9. Complete and Submit Internal Audit Workflow

### Goal

Allow a manager or auditor to finish an audit and submit it.

### Primary Actors

- manager
- auditor

### Steps

1. user completes the checklist
2. FiScore calculates score and grade
3. audit remains local until submission if offline
4. user submits the audit
5. FiScore syncs the audit when connectivity is available
6. submitted audit becomes a completed record
7. auto-created violations are generated based on configured audit responses

### Important Rule

Auto-created violations should be created only after the audit is submitted, not while the user is still in the middle of the audit.

### Why

This avoids creating premature findings while the audit is still incomplete and reduces unnecessary churn if answers change before submission.

## 10. Auto-Create Violation from Audit Workflow

### Goal

Create tenant violations automatically when submitted audit responses trigger configured rules.

### Trigger

- audit submission

### Steps

1. audit is submitted
2. FiScore evaluates violation trigger rules for the submitted responses
3. for each qualifying response, FiScore creates a violation
4. the violation links back to:
   - the audit
   - section
   - question
   - triggering response
5. the new violation enters the standard violation lifecycle

### Result

- audit findings become actionable tenant violations

## 11. Manually Add Violation Workflow

### Goal

Allow users to add a violation manually during an audit.

### Primary Actors

- manager
- auditor

### Version 1 Rule

Manual violations are supported during an audit.

### Steps

1. user is conducting an audit
2. user identifies an issue that should be tracked even if it was not auto-triggered
3. user adds a manual violation
4. FiScore links the violation to the current audit
5. the violation enters the standard violation lifecycle

### Product Recommendation

FiScore should likely support standalone manual violations outside an audit in a later version, and there is a strong case for eventually allowing them. Real-world restaurant operations often uncover issues outside formal audit flows.

For version 1, however, limiting manual violation creation to the audit workflow keeps the product simpler and more structured.

## 12. Respond to Violation Workflow

### Goal

Allow staff, auditors, and managers to work on a violation response.

### Primary Actors

- manager
- auditor
- staff

### Response Model

Version 1 should use one active response record per violation, but that response can be completed in phases over time.

Example:

- corrective action entered today
- preventive action added later
- verification notes added later

### Steps

1. user opens a violation
2. user starts or edits the active response
3. user adds response details such as:
   - notes
   - corrective action
   - preventive action
   - evidence
4. FiScore saves the evolving response
5. response remains associated with the violation until review or closure

## 13. Submit Violation for Review Workflow

### Goal

Allow staff or auditors to submit a completed response to a manager for review.

### Primary Actors

- staff
- auditor
- manager

### Steps

1. user works on the violation response
2. user submits the violation for review
3. violation status moves to `pending_review`
4. manager reviews the response and evidence

### Manager Review Outcomes

Manager can:

- approve and close
- reject and send back
- request more work
- edit the response before closing

## 14. Manager Closes Violation Workflow

### Goal

Allow a manager to close a violation after reviewing the response.

### Primary Actor

- manager

### Steps

1. manager opens a violation in review or active status
2. manager reviews the current response
3. manager may edit the response if needed
4. manager closes the violation
5. FiScore records the closing user and closing timestamp
6. violation status becomes `closed`

### Mandatory Requirements

Version 1 does not require a separate mandatory closure form. The working assumption is that the response itself contains the details needed for closure.

## 15. Reject or Request More Work Workflow

### Goal

Allow a manager to reject a response or request additional work.

### Primary Actor

- manager

### Steps

1. manager reviews the submitted response
2. manager determines that the violation is not ready to close
3. manager either rejects the response or requests more work
4. violation moves back to an active working state
5. assigned users continue updating the same active response

## 16. Reopen Violation Workflow

### Goal

Allow a manager to reopen a previously closed violation.

### Primary Actor

- manager

### Steps

1. manager opens a closed violation
2. manager selects reopen
3. FiScore records reopen timestamp and user
4. violation status moves back to `open`
5. the existing response history is retained

### Version 1 Rule

Reopening a violation should move it back to open rather than creating a completely separate response cycle object.

This keeps the workflow simpler while still preserving history.

## Cross-Workflow Rules

## Public Findings Import Rule

- import all public inspection history when a restaurant is added
- auto-create tenant violations only for the latest inspection findings
- older findings remain visible but not automatically activated

## Audit Draft Rule

- audits can be saved and resumed
- only the original user can resume the draft in version 1

## Audit Auto-Violation Rule

- audit-triggered violations are created only on audit submission

## Manual Violation Rule

- version 1 supports manual violations during an audit
- standalone manual violations are a likely future enhancement

## Violation Response Rule

- one active response per violation
- response can be completed in phases over time

## Closure Rule

- only managers can close violations

## Offline Rule

- audits are the main offline workflow
- audit responses save locally during execution
- sync happens when the audit is submitted
- most other workflows are primarily online in version 1

## Public Inspection Report Rule

- if the public source provides an official report, FiScore should show it as the official source document
- if the public source does not provide an official report, permitted tenant users may upload an onsite copy
- tenant-uploaded onsite copies must remain clearly distinct from official public-source documents

## Recommended Future Enhancements

Potential later workflow enhancements:

- standalone manual violation creation outside audits
- multi-user collaborative audit completion
- offline support for more workflows beyond audits
- richer review and assignment routing
- explicit archive vs delete behavior when removing restaurants

## Summary

FiScore version 1 should support a structured day-to-day workflow model in which tenants register, link restaurants from the master list, import full public inspection history, run offline-friendly internal audits, create violations through public data or submitted audit outcomes, and manage remediation through manager-controlled review and closure.
