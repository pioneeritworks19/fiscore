# FiScore Operational Workflows

## Purpose

This document defines the day-to-day operational workflows for FiScore version 1.

It focuses on how tenant users move through the product during normal usage, including:

- tenant setup
- site management and restaurant linking
- user invitation
- restaurant switching
- public inspection import behavior
- internal audit execution
- violation creation and response
- training assignment and completion
- review, closure, and reopening

This document intentionally focuses on operational usage rather than checklist template authoring or scoring-rule design.

## Scope

The following workflows are included in version 1:

- tenant registration
- add site from master list
- manually add site
- link manual site to master restaurant
- invite user
- switch restaurant
- import public inspections and findings
- upload onsite health department report
- schedule audit
- create recurring audit schedule
- create internal audit
- complete internal audit
- auto-create violation from audit
- manually add violation during audit
- respond to violation
- assign training
- complete training
- submit violation for review
- manager closes violation
- reopen violation

## Workflow Principles

### 1. Site Context Is Central

The app should always make it clear which site the user is currently working in. Users work in one site at a time and switch context when needed.

If a user has access to multiple sites, the app should start with a site summary list.

If a user has access to exactly one site, the app may open that site directly.

Users with permission to add sites should still see an `Add Site` entry point even if they currently have access to only one site.

### 2. Public Data and Tenant Workflows Are Separate

Public inspections and findings are brought into the tenant for internal use, but the tenant's responses and remediation activity remain private to the tenant.

### 3. Audits Are Offline-First

Internal audits are a primary offline workflow. Users should be able to complete an audit without connectivity and sync should happen when the audit is submitted.

Scheduled audit definitions and generated audit instances should normally be created online, but once an audit instance is started, execution should support offline use.

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

## 2. Add Site from Master List Workflow

### Goal

Allow a tenant to add a site by linking it to the FiScore master restaurant list.

### Primary Actors

- tenant owner
- admin

### Preconditions

- tenant already exists
- user has permission to add sites

### Steps

1. user starts the add restaurant flow
2. user enters a zip code
3. FiScore searches the master restaurant list for that zip code
4. user filters or searches by restaurant name
5. FiScore shows candidate restaurants
6. user selects the correct restaurant
7. FiScore creates the tenant site record
8. FiScore creates the tenant-to-master restaurant link
9. FiScore imports all historical public inspections for that restaurant into tenant-readable projections
10. FiScore imports public findings for those inspections
11. FiScore automatically creates tenant violations from findings on the most recent public inspection
12. older public findings remain visible as historical records and can be turned into tenant violations later if needed

### Result

- site is linked to the tenant
- full public inspection history is available in tenant context
- latest inspection findings become active tenant violations automatically

### Important Product Rule

Only the latest public inspection findings should auto-create tenant violations. This keeps the initial workload focused and avoids overwhelming a newly linked restaurant with every historical finding becoming active at once.

## 3. Manually Add Site Workflow

### Goal

Allow a tenant to create a site manually when it cannot be found in FiScore master data.

### Primary Actors

- tenant owner
- admin

### Preconditions

- tenant already exists
- user has permission to add sites

### Steps

1. user starts the add site flow
2. user searches master data but cannot find a reliable match
3. FiScore offers `Add Site Manually`
4. user enters site details such as name, address, city, state, zip code, and timezone
5. FiScore creates a tenant-owned site without a master link
6. the new site appears in the tenant portfolio and restaurant switcher
7. FiScore makes internal audits, violations, and assignments available for that site immediately

### Result

- tenant can operate the site even without a master-data match
- public inspection import remains unavailable until the site is linked later

### Important Product Rule

Manual site creation should be treated as a supported operating path, not only as an exception.

## 4. Link Manual Site to Master Restaurant Workflow

### Goal

Allow a previously manual tenant site to be linked later to a master restaurant record.

### Primary Actors

- tenant owner
- admin

### Preconditions

- tenant site already exists as a manual site
- a valid master restaurant match is now available

### Steps

1. user opens the site management area
2. user selects a manual site
3. user starts the `Link to Master Restaurant` flow
4. FiScore searches for candidate master restaurants
5. user selects the verified match
6. FiScore creates the tenant-to-master link without replacing existing tenant-side audit or violation history
7. FiScore imports public inspection history for the linked restaurant
8. FiScore applies the standard public finding import rules for the newly linked site

### Result

- the site keeps its tenant history and gains public inspection data going forward

### Important Product Rule

Linking a manual site later must preserve tenant-created audits, violations, assignments, and history.

## 5. Remove Site Workflow

### Goal

Allow a tenant owner or admin to remove a site from the tenant with clear warning about data consequences.

### Primary Actors

- tenant owner
- admin

### Preconditions

- site is already present in the tenant

### Steps

1. user initiates site removal
2. FiScore shows a warning that removing the site will remove tenant-side site data associated with that tenant context
3. user must explicitly acknowledge the warning
4. FiScore removes the site from the tenant
5. FiScore removes or archives tenant-owned workflows associated with that site according to the final implementation policy

### Recommended Warning Message Direction

The user should clearly understand that removing and re-adding a restaurant may create data continuity issues and should not be treated as a casual action.

### Recommended Product Note

Version 1 should strongly prefer explicit confirmation before site removal because re-adding the site later could create confusion around prior imported findings and tenant workflows.

## 6. Invite User Workflow

### Goal

Allow admins and managers to invite users into the tenant.

### Primary Actors

- admin
- manager

### Steps

1. inviter opens team management
2. inviter enters the user's email and assigns a role
3. inviter optionally assigns site access
4. invitation record is created
5. invited user receives the invitation
6. invited user accepts and joins the tenant

### Result

- user becomes a tenant member
- user receives role-based access

### Version 1 Identity Rule

- invitations should use email as the primary identifier
- phone number may exist on the user profile, but should not be the primary invite key in version 1

## 7. Switch Site Workflow

### Goal

Allow users with access to multiple sites to switch the active site context.

### Primary Actors

- all tenant users with site access

### Rules

- tenant owner and admin can see all sites in the tenant
- other users only see sites they are assigned to
- the app shows one site at a time

### Steps

1. user opens the site switcher
2. FiScore lists sites the user can access
3. user selects a site
4. app updates current site context
5. screens refresh to show that site's audits, violations, and public data

### Version 1 Entry Recommendation

- if the user has access to more than one site, start at the site summary list
- if the user has access to exactly one site, open that site directly
- if the user has permission to add sites, keep an `Add Site` entry visible even in the single-site experience

## 8. Import Public Inspections and Findings Workflow

### Goal

Bring public inspection history into tenant context after linking a tenant site to a master restaurant.

### Primary Trigger

- add site from master list
- link manual site to master restaurant

### Steps

1. FiScore identifies the linked master restaurant
2. FiScore pulls all historical public inspections for that restaurant
3. FiScore stores tenant-readable projections of those inspections
4. FiScore pulls all public findings associated with those inspections
5. FiScore stores tenant-readable copies of those findings under the site inspection history
6. FiScore auto-creates tenant violations only from findings on the most recent inspection
7. historical findings from older inspections remain visible without automatically becoming active tenant violations

### Result

- tenant users can review public inspection history
- the latest public inspection becomes immediately actionable through linked tenant violations

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

## 9. Schedule Audit Workflow

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

## 10. Create Recurring Audit Schedule Workflow

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

## 11. Scheduled Audit State Tracking Workflow

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

## 12. Create Internal Audit Workflow

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

## 13. Save and Resume Audit Workflow

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

## 14. Complete and Submit Internal Audit Workflow

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
8. auto-created violations are generated based on configured audit responses

### Important Rule

Auto-created violations should be created only after the audit is submitted, not while the user is still in the middle of the audit.

### Why

This avoids creating premature findings while the audit is still incomplete and reduces unnecessary churn if answers change before submission.

## 15. Auto-Create Violation from Audit Workflow

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

## 16. Manually Add Violation During Audit Workflow

### Goal

Allow users to add a violation during an audit even when it was not initiated from a question response.

### Primary Actors

- manager
- auditor

### Steps

1. user is conducting an audit
2. user identifies an issue that should be tracked even if it was not auto-triggered
3. user adds a manual violation
4. FiScore links the violation to the current audit and site
5. the violation enters the standard violation lifecycle

### Product Recommendation

Manual violation creation during the audit should be supported even when the issue did not come from a configured question trigger.

## 17. Respond to Violation Workflow

### Goal

Allow staff, auditors, and managers to work on a violation response.

### Primary Actors

- manager
- auditor
- staff

### Response Model

Version 1 should use one active response record per violation, and that response can be completed in phases over time.

Example:

- corrective action entered today
- preventive action added later
- verification notes added later

### Steps

1. user opens a violation
2. user starts or edits the active response
3. user adds response details such as:
   - `responseGeneral`
   - `responseContainment`
   - `responseRootCause`
   - `responseCorrectiveAction`
   - `responsePreventiveAction`
   - evidence
4. FiScore saves the evolving response
5. response remains associated with the violation until review or closure

### Collaboration Recommendation

Violation records should also support built-in collaboration or chat so team members can coordinate follow-up work in context.

### Thread Recommendation

For important remediation work, the violation should function as a persistent thread containing:

- comments
- mentions
- status updates
- assignments
- photo evidence
- structured response context

## 18. Assign Training Workflow

### Goal

Allow a manager to assign targeted training linked to a violation, structured response, audit risk area, or general site need.

### Primary Actors

- manager

### Steps

1. manager opens a violation, violation response, audit finding, or training area
2. FiScore may show recommended training options based on context
3. manager selects the user and training item
4. manager sets due date and assignment note if needed
5. FiScore creates the training assignment
6. assigned user sees the training in their work queue

### Result

- training becomes an actionable follow-up item linked to the operational issue

## 19. Complete Training Workflow

### Goal

Allow an assigned user to complete operational training and preserve completion history.

### Primary Actors

- staff
- auditor
- manager

### Steps

1. user opens assigned training
2. user reviews the course or micro-learning content
3. user completes any lightweight knowledge check if configured
4. FiScore records completion state and completion timestamp
5. training completion remains linked to the original issue or risk context when applicable

### Result

- the system preserves training history for future operational review
- managers can later compare training activity against later audit outcomes

## 20. Submit Violation for Review Workflow

### Goal

Allow staff or auditors to submit a completed violation response to a manager for review.

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

## 21. Manager Closes Violation Workflow

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

## 22. Reject or Request More Work Workflow

### Goal

Allow a manager to reject a violation response or request additional work.

### Primary Actor

- manager

### Steps

1. manager reviews the submitted response
2. manager determines that the violation is not ready to close
3. manager either rejects the response or requests more work
4. violation moves back to an active working state
5. assigned users continue updating the same active response

## 23. Reopen Violation Workflow

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

- import all public inspection history when a site is linked to a master restaurant
- auto-create tenant violations only for the latest inspection findings
- older findings remain visible but not automatically activated

## Site Linking Rule

- a tenant site may be linked to master data or remain manual and unlinked
- manual sites should support audits, violations, assignments, and analytics
- only linked sites should receive imported public inspection data
- a manual site may be linked later without losing tenant-created history

## Training Rule

- training should function as operational remediation rather than generic LMS content
- managers are the primary assigners in version 1
- the system may recommend training from audits, findings, and repeat issues
- training completion should remain linked to the originating risk context when applicable

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

- audit-triggered violations are created only on audit submission

## Manual Violation Rule

- version 1 supports manual violations during an audit
- manual violations created by users are always site-scoped

## Violation Response Rule

- one active response per violation
- response can be completed in phases over time

## Collaboration Rule

- violations should support built-in collaboration or chat on follow-up work
- important violations should behave as discussion threads with persistent history
- thread discussion should remain separate from the structured violation response fields

## Notification Rule

- operational notifications should support assigned violations, assigned training, overdue audits, overdue training, and manager review requests

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

- multi-user collaborative audit completion
- offline support for more workflows beyond audits
- richer review and assignment routing
- more configurable overdue-to-missed policy windows by checklist or tenant
- deeper training reporting and retraining loops
- explicit archive vs delete behavior when removing sites

## Summary

FiScore version 1 should support a structured day-to-day workflow model in which tenants register, link sites from the master restaurant list, import full public inspection history, run offline-friendly internal audits, create violations through public data, manual site entry, or submitted audit outcomes, and manage remediation through manager-controlled review and closure.
