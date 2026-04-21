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
- action creation and response
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
- schedule audit
- create recurring audit schedule
- create internal audit
- complete internal audit
- auto-create violation from audit
- create standalone action
- create recurring action
- manually add violation-type action
- respond to action
- submit action for review
- manager closes action
- reopen action

## Workflow Principles

### 1. Restaurant Context Is Central

The app should always make it clear which restaurant the user is currently working in. Users work in one restaurant at a time and switch context when needed.

### 2. Public Data and Tenant Workflows Are Separate

Public inspections and findings are brought into the tenant for internal use, but the tenant's responses and remediation activity remain private to the tenant.

### 3. Audits Are Offline-First

Internal audits are a primary offline workflow. Users should be able to complete an audit without connectivity and sync should happen when the audit is submitted.

Scheduled audit definitions and generated audit instances should normally be created online, but once an audit instance is started, execution should support offline use.

### 4. Action Closure Is Manager-Controlled

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
11. FiScore automatically creates tenant violation-type actions only for findings from the most recent public inspection
12. older public findings remain visible, but users choose whether to activate or work them as actions

### Result

- restaurant is linked to the tenant
- full public inspection history is available in tenant context
- latest inspection findings become active tenant actions automatically

### Important Product Rule

Only the latest public inspection findings should auto-create tenant violation-type actions. This keeps the initial workload focused and avoids overwhelming a newly linked restaurant with every historical finding becoming active at once.

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
6. FiScore auto-creates tenant violation-type actions only from findings on the most recent inspection
7. historical findings from older inspections remain visible without automatically becoming active tenant actions

### Result

- tenant users can review public inspection history
- the latest public inspection becomes immediately actionable

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

## 7. Schedule Audit Workflow

### Goal

Allow a manager or auditor to create a scheduled audit for a restaurant on a specific date.

### Primary Actors

- manager
- auditor

### Preconditions

- user is in a restaurant context or has selected a restaurant
- checklist template exists

### Steps

1. user opens the audits area
2. user chooses to schedule an audit
3. user selects the restaurant or site
4. user selects the checklist template
5. user sets the scheduled date
6. user optionally adds assignment details or notes
7. FiScore creates a scheduled audit record
8. the scheduled audit appears in upcoming audit views for that restaurant

### Result

- the restaurant has a future audit scheduled
- the assigned team can see the audit before it is due

## 8. Create Recurring Audit Schedule Workflow

### Goal

Allow a manager or auditor to define a recurring internal inspection cadence for a restaurant or site.

### Primary Actors

- manager
- auditor

### Preconditions

- checklist template exists
- target restaurant or site is known

### Steps

1. user opens audit scheduling
2. user selects `Create Recurring Schedule`
3. user chooses the restaurant or site
4. user selects the checklist template
5. user defines the recurrence pattern
6. user optionally sets start date, end date, assignee, and schedule notes
7. FiScore stores the recurring schedule definition
8. FiScore generates scheduled audit instances according to that cadence

### Result

- repeat inspections do not need to be scheduled manually each time
- FiScore can report expected versus completed audit cadence by restaurant

## 9. Scheduled Audit State Tracking Workflow

### Goal

Track whether scheduled audits are upcoming, in progress, completed, overdue, or missed.

### Primary System Behavior

- FiScore evaluates schedule state over time

### Recommended State Model

- `scheduled`
- `in_progress`
- `completed`
- `overdue`
- `missed`

### Recommended Rules

- a future audit stays `scheduled` until a user starts it
- an audit moves to `in_progress` when the assigned user starts working
- an audit moves to `completed` when the audit is submitted successfully
- an audit becomes `overdue` when the scheduled date passes and no completed submission exists
- an audit may move to `missed` when the operational policy decides that the scheduled occurrence was not completed within its allowed window and should now remain a historical miss rather than an active overdue item

### Product Recommendation

FiScore should treat `overdue` and `missed` differently:

- `overdue` means the team can still complete the scheduled audit and recover the workflow
- `missed` means the scheduled occurrence was not completed in time and should be counted historically as a miss even if a later audit is performed

This distinction helps accountability reporting and avoids hiding schedule failures behind late completions.

## 10. Create Internal Audit Workflow

### Goal

Allow a manager or auditor to start an internal audit for a restaurant, either ad hoc or from a scheduled audit instance.

### Primary Actors

- manager
- auditor

### Preconditions

- user is in a restaurant context
- checklist template exists

### Steps

1. user chooses to start an audit
2. user either:
   - starts from a scheduled audit
   - starts an ad hoc audit
3. user selects the checklist template if not already preselected by the schedule
4. FiScore creates an audit session in `draft` or `in_progress` state
5. if the audit came from a schedule, the linked schedule instance moves to `in_progress`
6. checklist content is loaded onto the device
7. user begins responding to questions

### Offline Behavior

- this workflow should support offline usage
- audit content should be available locally once the audit starts
- responses should save locally during the audit

## 11. Save and Resume Audit Workflow

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

## 12. Complete and Submit Internal Audit Workflow

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
7. if the audit was tied to a schedule, the linked schedule instance moves to `completed`
8. auto-created violation-type actions are generated based on configured audit responses

### Important Rule

Auto-created violation-type actions should be created only after the audit is submitted, not while the user is still in the middle of the audit.

### Why

This avoids creating premature findings while the audit is still incomplete and reduces unnecessary churn if answers change before submission.

## 13. Auto-Create Violation from Audit Workflow

### Goal

Create tenant violation-type actions automatically when submitted audit responses trigger configured rules.

### Trigger

- audit submission

### Steps

1. audit is submitted
2. FiScore evaluates violation trigger rules for the submitted responses
3. for each qualifying response, FiScore creates a violation-type action
4. the action links back to:
   - the audit
   - section
   - question
   - triggering response
5. the new action enters the standard action lifecycle

### Result

- audit findings become actionable tenant actions

## 14. Create Standalone Action Workflow

### Goal

Allow users to create an action that is not tied directly to an audit finding or imported public inspection finding.

### Primary Actors

- manager
- auditor
- admin later if needed

### Steps

1. user opens the actions area
2. user selects an action type
3. user enters the action details
4. user assigns the action if needed
5. FiScore creates the action in `Open` status

### Version 1 Recommendation

FiScore should support standalone actions as part of the broader action framework even if the first operational emphasis remains on violation-type actions.

This is important because restaurant teams often need to track follow-up work that is operationally important but not tied directly to a formal audit.

## 15. Create Recurring Action Workflow

### Goal

Allow users to create recurring tasks or actions for repeatable operational work.

### Primary Actors

- manager
- admin later if needed

### Steps

1. user chooses to create a recurring action
2. user selects the action type
3. user defines recurrence pattern
4. user assigns restaurant scope and assignee if needed
5. FiScore stores the recurring action definition
6. FiScore creates action instances on the defined cadence

### Result

- repeatable operational work can be tracked without manual recreation every time

## 16. Manually Add Violation-Type Action Workflow

### Goal

Allow users to add a violation-type action manually during an audit.

### Primary Actors

- manager
- auditor

### Version 1 Rule

Manual violation-type actions are supported during an audit.

### Steps

1. user is conducting an audit
2. user identifies an issue that should be tracked even if it was not auto-triggered
3. user adds a manual violation-type action
4. FiScore links the action to the current audit
5. the action enters the standard action lifecycle

### Product Recommendation

FiScore should support standalone actions outside audits, and violation-type actions should fit cleanly within that broader model.

For version 1, manual violation-type action creation during audits remains a strong structured starting point.

## 17. Respond to Action Workflow

### Goal

Allow staff, auditors, and managers to work on an action response.

### Primary Actors

- manager
- auditor
- staff

### Response Model

Version 1 should use one active response record per action, but that response can be completed in phases over time.

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
5. response remains associated with the action until review or closure

### Collaboration Recommendation

Action records should also support built-in collaboration or chat so team members can coordinate follow-up work in context.

## 18. Submit Action for Review Workflow

### Goal

Allow staff or auditors to submit a completed action response to a manager for review.

### Primary Actors

- staff
- auditor
- manager

### Steps

1. user works on the action response
2. user submits the action for review
3. action status moves to `pending_review`
4. manager reviews the response and evidence

### Manager Review Outcomes

Manager can:

- approve and close
- reject and send back
- request more work
- edit the response before closing

## 19. Manager Closes Action Workflow

### Goal

Allow a manager to close an action after reviewing the response.

### Primary Actor

- manager

### Steps

1. manager opens an action in review or active status
2. manager reviews the current response
3. manager may edit the response if needed
4. manager closes the action
5. FiScore records the closing user and closing timestamp
6. action status becomes `closed`

### Mandatory Requirements

Version 1 does not require a separate mandatory closure form. The working assumption is that the response itself contains the details needed for closure.

## 20. Reject or Request More Work Workflow

### Goal

Allow a manager to reject an action response or request additional work.

### Primary Actor

- manager

### Steps

1. manager reviews the submitted response
2. manager determines that the action is not ready to close
3. manager either rejects the response or requests more work
4. action moves back to an active working state
5. assigned users continue updating the same active response

## 21. Reopen Action Workflow

### Goal

Allow a manager to reopen a previously closed action.

### Primary Actor

- manager

### Steps

1. manager opens a closed action
2. manager selects reopen
3. FiScore records reopen timestamp and user
4. action status moves back to `open`
5. the existing response history is retained

### Version 1 Rule

Reopening an action should move it back to open rather than creating a completely separate response cycle object.

This keeps the workflow simpler while still preserving history.

## Cross-Workflow Rules

## Public Findings Import Rule

- import all public inspection history when a restaurant is added
- auto-create tenant violation-type actions only for the latest inspection findings
- older findings remain visible but not automatically activated

## Audit Draft Rule

- audits can be saved and resumed
- only the original user can resume the draft in version 1

## Audit Schedule Rule

- audits may be created ad hoc or from scheduled audit instances
- scheduled audits should support one-time dates and recurring cadence
- schedule states should distinguish `scheduled`, `in_progress`, `completed`, `overdue`, and `missed`
- overdue audits remain actionable
- missed audits remain historically reportable

## Audit Auto-Violation Rule

- audit-triggered violation-type actions are created only on audit submission

## Manual Violation Rule

- version 1 supports manual violation-type actions during an audit
- standalone actions should also be supported in the broader action framework

## Action Response Rule

- one active response per action
- response can be completed in phases over time

## Collaboration Rule

- actions should support built-in collaboration or chat on follow-up work

## Closure Rule

- only managers can close actions

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

- richer recurring action configuration
- start audits from actions
- multi-user collaborative audit completion
- offline support for more workflows beyond audits
- richer review and assignment routing
- more configurable overdue-to-missed policy windows by checklist or tenant
- explicit archive vs delete behavior when removing restaurants

## Summary

FiScore version 1 should support a structured day-to-day workflow model in which tenants register, link restaurants from the master list, import full public inspection history, run offline-friendly internal audits, create actions through public data, operational work, or submitted audit outcomes, and manage remediation through manager-controlled review and closure.
