# FiScore Audit Execution Flow

## Purpose

This document defines the screen-by-screen user flow for scheduling an audit, starting an audit, performing the audit, and submitting the audit in FiScore version 1.

This is a practical walkthrough doc intended to make the current spec easier to visualize before app code starts.

Read alongside:

- [WORKFLOWS.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\WORKFLOWS.md)
- [AUDIT_CHECKLIST_DESIGN.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\AUDIT_CHECKLIST_DESIGN.md)
- [APP_NAVIGATION.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\app\APP_NAVIGATION.md)

## Core Model

There are three related but different audit flows:

1. `Schedule audit`
   Defines work that should happen later
2. `Start audit`
   Creates a real audit session
3. `Perform audit`
   Captures checklist answers, evidence, and findings

Simple mental model:

- scheduling is planning
- starting is creating the live audit session
- performing is answering and recording findings

## Roles

Version 1 primary roles:

- `tenant_owner`
- `admin`
- `manager`
- `auditor`

For the initial implementation, tenant owners and admins may also conduct
internal checks. This lets small restaurant operators set up and use the
workflow directly without creating a second operational account.

## Internal Audit MVP

The first implementation should focus on ad hoc internal checks rather than
scheduling or checklist authoring.

### Included

- two FiScore starter templates copied into the tenant checklist library:
  - `Food Safety Walkthrough`
  - `Opening Readiness Check`
- searchable tenant-owned checklist selection from a site
- in-progress check execution and same-user resume
- `Pass`, `Needs attention`, and `N/A` responses
- inline observation capture when an item needs attention
- photo proof attached to an audit response
- review and submission
- tenant violations created from configured failed responses on submission
- completed check summary

### Deferred

- one-time and recurring scheduling
- tenant checklist authoring and template editing
- manual violation creation during a check
- video proof
- final audit report generation and mobile-friendly `View report` experience
- durable offline operation queue and conflict handling

The MVP should preserve the long-term model by creating audits only from a
tenant-owned checklist template and snapshotting that template version into
each audit session. Starter content may originate in FiScore, but the running
audit does not execute directly against a live shared library definition.

### TODO: Checklist Library Growth

After the starter template and audit execution flow is stable:

- add tenant-created company checklists and a checklist editor
- add categories and filters such as Opening, Closing, Food safety, Equipment,
  and Cleaning
- surface recently used and suggested checks for faster shift workflows
- add library update, detach, and version-management controls for administrators
- support site-level template availability where operations require it

### TODO: Internal Audit Report

After internal check execution, violations, and remediation are stable,
generate a tenant-owned report when a check is submitted. The completed audit
view should open that stored report directly and eventually support sharing or
export. The report should include checklist answers, observations, evidence,
created violations, and later review or closure history.

## Screen Flow Overview

```text
Audits List
-> Schedule Audit
   -> Save one-time or recurring schedule

Audits List
-> Scheduled Audit Detail
-> Start Audit
-> In-Progress Audit
-> Review and Submit
-> Audit Completion Summary

Audits List
-> Start New Audit
-> Select Template
-> In-Progress Audit
-> Review and Submit
-> Audit Completion Summary
```

## Part 1. Schedule Audit

## Screen 1. Audits List

### Purpose

This is the main audit landing area for managers and auditors.

### Recommended content

- upcoming scheduled audits
- overdue audits
- missed audits
- in-progress drafts
- recently completed audits
- unanswered or incomplete draft indicators where useful
- `Start New Audit`
- `Schedule Audit`
- `Create Recurring Schedule`

### User actions

- open a scheduled audit
- start an ad hoc audit
- create a one-time schedule
- create a recurring schedule
- resume a draft audit

## Screen 2. Schedule Audit

### Purpose

Create a one-time scheduled audit for a specific site.

### Required inputs

- site
- checklist template
- due date

### Optional inputs

- assignee
- note or description

### System result

FiScore creates:

- `auditSchedules/{scheduleId}`

and later:

- a generated schedule instance when applicable

### User outcome

The audit now appears in upcoming audit views for that site.

## Screen 3. Create Recurring Schedule

### Purpose

Set a repeat cadence for a checklist at a site.

### Required inputs

- site
- checklist template
- recurrence pattern

### Optional inputs

- start date
- end date
- assignee
- note

### System result

FiScore creates:

- recurring `auditSchedules/{scheduleId}`
- recurring generated `instances/{instanceId}`

### User outcome

The site now has durable expected audit occurrences over time.

## Part 2. Start Audit

There are two start paths.

## Path A. Start From Scheduled Audit

## Screen 4A. Scheduled Audit Detail

### Purpose

Show the user what is due before they start.

### Recommended content

- site name
- checklist name
- scheduled date
- due state
- assignee if any
- schedule note if any
- `Start Audit`

### User action

- tap `Start Audit`

### System result

FiScore:

- creates `audits/{auditId}`
- links it to `scheduleId`
- links it to `scheduleInstanceId`
- snapshots checklist version and metadata
- moves schedule instance to `in_progress`
- loads checklist content to the device

## Path B. Start Ad Hoc Audit

## Screen 4B. Start New Audit

### Purpose

Allow a manager or auditor to create an unscheduled live audit session.

### Required inputs

- site
- checklist template

### Optional inputs

- note

### User action

- tap `Start Audit`

### System result

FiScore:

- creates `audits/{auditId}`
- marks `auditOrigin = ad_hoc`
- snapshots checklist version and metadata
- loads checklist content to the device

## Part 3. Perform Audit

## Screen 5. In-Progress Audit

### Purpose

This is the main audit execution screen.

### Recommended layout

Hybrid section-based flow:

- one section in focus at a time
- grouped questions within that section
- visible section progress
- visible overall audit progress
- easy movement back and forth between sections
- clear awareness of what is unanswered, incomplete, flagged, or not applicable

### Recommended persistent elements

- site name
- checklist name
- current section title
- progress indicator
- save state / sync state
- unanswered count if available
- flagged or review count if available

### Recommended actions

- answer question
- add note
- add photo or video
- move next or previous
- open section navigator
- jump to unanswered questions
- jump to flagged questions if supported
- save and exit
- manually add violation during audit

## Screen 5A. Section Navigator

### Purpose

Give the auditor a fast way to move through large audits without losing orientation.

### Recommended content

- all sections in display order
- completion status per section
- answered count per section
- unanswered count per section
- flagged count per section if supported
- section-level N/A state where applicable

### Recommended actions

- open a section directly
- jump to the next incomplete section
- review flagged sections

### Why

Long audits need strong navigation support so the auditor can recover from interruptions and complete missing items efficiently.

## Question Interaction Pattern

For each question, the user may:

- choose response
- enter measurement
- add note
- add evidence
- see prior response if available
- see trigger follow-up inline if rules fire

### Important v1 behavior

- follow-up should expand inline
- user should not be navigated away from the audit to satisfy trigger requirements
- response state should save locally as work happens

## Screen 6. Triggered Follow-Up State

### When this appears

When a response fires one or more configured rules.

### Examples

- require comment
- require photo
- require signature
- suggest training
- create violation on submit
- flag repeat issue

### Recommended UI behavior

- show why the trigger fired
- keep original question visible
- expand follow-up inline
- preserve section context

### Example

Question:

`Are potentially hazardous foods held at 135F or above?`

If user answers `No`:

- require temperature entry
- require comment
- require photo
- flag as high risk
- mark for violation creation on submit

## Screen 7. Manual Violation During Audit

### Purpose

Allow the auditor to record a violation during the audit even if it did not come from a question response trigger.

### Important product rule

This is explicitly supported in version 1.

### User actions

1. user taps `Add Violation`
2. enters violation details
3. links it to the current audit and site
4. saves it

### Source behavior

This should create a violation with:

- `sourceType = internal_audit`
- `sourceReferenceId = auditId`
- `sourceQuestionResponseId = null`

That means:

- it came from the audit
- but it was manually added by the auditor
- not triggered by a specific question response

## Screen 7A. Section-Level Not Applicable

### Purpose

Allow the auditor to mark a whole section as not applicable when the checklist permits it.

### When this should appear

- only if the checklist section allows section-level N/A

### Recommended user flow

1. auditor opens section actions
2. selects `Mark Section N/A`
3. FiScore confirms the action
4. auditor optionally enters note if required by checklist policy
5. section is marked not applicable

### Expected behavior

- questions in that section no longer block completion
- section progress reflects N/A rather than incomplete
- scoring excludes the section where checklist policy says N/A items should be excluded
- the audit summary clearly shows that the section was marked N/A

## Screen 8. Save Draft / Resume Later

### Purpose

Allow the same user to pause and resume the audit.

### Recommended actions

- `Save and Exit`
- `Resume Draft`

### Important version 1 rule

Only the same user should resume that audit draft in version 1.

### Offline behavior

- responses save locally
- evidence may remain local until synced
- draft state should be visible and understandable

## Screen 8A. Audit Completion Helper Views

### Purpose

Help the auditor finish large audits cleanly before submission.

### Recommended helper views

- `Unanswered`
- `Incomplete`
- `Flagged`
- `Section Summary`

### Recommended behaviors

- user can jump directly to incomplete questions
- user can jump directly to incomplete sections
- review screen should not be the first time unanswered items become visible

## Part 4. Review And Submit

## Screen 9. Review and Submit

### Purpose

Let the user review audit results before final submission.

### Recommended content

- section completion summary
- section not-applicable summary
- score percentage
- default grade
- final grade
- critical-rule impacts
- violation count preview
- unanswered or incomplete items if any

### Recommended actions

- go back to audit
- jump to unanswered items
- jump to flagged items if supported
- submit audit

### Important product behavior

At this point:

- score is calculated
- grade logic is applied
- but auto-created violations are still not yet finalized until submit

## Screen 10. Submit Audit

### User action

- tap `Submit Audit`

### System result

FiScore should:

1. mark audit as submitted/completed
2. sync when connectivity is available
3. if scheduled, move schedule instance to `completed`
4. evaluate violation trigger rules against submitted responses
5. create auto-triggered violations now
6. preserve all score and grade snapshots
7. create or queue final server-side audit report generation

### Important version 1 rule

Auto-created violations happen only after audit submission.

They should not be created in the middle of the audit.

## Screen 11. Audit Completion Summary

### Purpose

Give the user a clear finish state.

### Recommended content

- final score
- final grade
- critical findings summary
- count of created violations
- section summary with completed versus not-applicable sections
- lightweight report preview
- link to view completed audit
- link to open created violations
- option to share lightweight summary or lightweight PDF if available

### User outcome

The audit feels complete and the next operational steps are clear.

## Screen 11A. Lightweight Audit Summary / Share

### Purpose

Allow the auditor to show or share a clean on-site summary immediately after completion.

### Recommended use cases

- show manager on site
- leave a lightweight summary with the site team
- export or share a lightweight PDF

### Important product distinction

- this is not the final canonical audit report
- the final audit report is generated server-side and attached later to the audit record

## State Changes Summary

## Schedule States

- `scheduled`
- `in_progress`
- `completed`
- `overdue`
- `missed`

## Audit States

- `draft`
- `in_progress`
- `submitted`
- `completed`
- `archived`

## Violation Creation Timing

### Auto-created violation

- created on audit submit
- linked to question response

### Manual audit violation

- may be created during audit execution
- linked to audit
- may have no question-response link

## Example End-To-End Flow

```text
Auditor opens Audits
-> sees scheduled Monthly Food Safety Audit
-> opens schedule detail
-> taps Start Audit
-> audit session is created
-> answers section questions
-> one hot-holding question fails and requires note/photo
-> auditor manually adds another violation for an unlabeled chemical bottle
-> saves and continues
-> reaches review screen
-> sees score 86 and final grade B
-> taps Submit Audit
-> trigger-based violations are created
-> schedule instance becomes completed
-> completion summary is shown
```

## Screen Inventory Summary

Recommended key screens for version 1:

1. Audits List
2. Schedule Audit
3. Create Recurring Schedule
4. Scheduled Audit Detail
5. Start New Audit
6. In-Progress Audit
7. Triggered Follow-Up State
8. Manual Violation During Audit
9. Review and Submit
10. Audit Completion Summary
11. Resume Draft Entry
12. Section Navigator
13. Section-Level Not Applicable
14. Lightweight Audit Summary / Share

## Summary

FiScore audit flow should feel structured and operational:

- schedule when needed
- start a real session when work begins
- perform the audit in a guided section-based flow
- support large-checklist navigation and completion recovery
- support section-level N/A where allowed
- allow inline triggers and manual violations
- submit only when complete
- create auto-triggered violations only at submission time
- show a clean lightweight summary immediately
- generate the final canonical audit report server-side afterward

This keeps the workflow clean for users and stable for data and sync behavior.
