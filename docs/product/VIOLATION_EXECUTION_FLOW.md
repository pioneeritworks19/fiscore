# Violation Execution Flow

## Purpose

This document defines the screen-by-screen violation workflow for FiScore version 1.

It translates the broader product requirements into a practical user flow covering:

- violation intake
- violation list and detail screens
- thread discussion
- structured response editing
- review submission
- manager review and closure
- reopening

## Core Principle

In FiScore, a violation is the tenant's actionable issue record.

Every violation:

- belongs to a `site`
- follows the same lifecycle regardless of source
- supports thread discussion for collaboration
- supports a structured response for the official remediation record

The thread and the structured response are related, but they are not the same thing.

- the thread is how the team collaborates
- the structured response is how the team records how the issue was addressed

## Sources of Violation Initiation

A violation may begin from any of these paths:

- imported from the latest public inspection findings for a linked site
- auto-created from an internal audit response after audit submission
- manually created during an internal audit
- manually created directly against a site

Regardless of source, once the violation exists in the tenant, it should move through the same working and closure flow.

For manually created violations, the creator should be able to capture the issue clearly at creation time using:

- title
- severity
- creator comments or issue description
- optional photo or other lightweight evidence

This is the initial issue capture. It should not require the creator to complete the full structured remediation response immediately.

## Lifecycle Model

Recommended working lifecycle:

- `open`
- `in_progress`
- `pending_review`
- `closed`

Important note:

- reopening should be recorded as a lifecycle event
- after reopening, the working status should move back to `open`
- the system may still preserve a separate reopen history event for reporting

## Main Screens

The violation experience should typically involve these screens:

1. violation list
2. violation detail
3. thread tab or thread area
4. structured response tab or response area
5. submit for review confirmation
6. manager review screen
7. close or reopen actions

## 1. Violation List Screen

### Goal

Give users a clear working queue of violations for the current site or tenant context.

### Entry Points

Users may arrive here from:

- the site dashboard
- a site-level violations tab
- a post-audit completion screen
- a public inspection detail screen
- a notification

### What the list should show

Each violation row should show enough information to let the user decide what needs attention.

Recommended fields:

- violation title or readable summary
- source type
- site name when in cross-site view
- severity or priority
- current status
- assignee if present
- due date if present
- latest activity or updated time
- pending review indicator when applicable

### Primary filters

Recommended filters:

- status
- site
- source
- severity
- assignee
- due date

### UX expectation

The list should feel like a working queue, not just historical records.

## 2. Violation Detail Screen

### Goal

Show the full operational context for one violation.

### What the screen should contain

The detail screen should combine:

- header summary
- source context
- lifecycle state
- thread discussion
- structured response
- evidence
- review and closure actions

### Recommended header content

- title
- readable summary
- status
- severity
- assignee
- due date
- identified date
- source badge

### Recommended source context

The detail screen should keep the issue understandable by using two layers:

- `Issue Summary`
  a short readable statement of the issue
- `Issue Context`
  a compact source-specific explanation of why the violation exists

This is preferable to forcing the title or one long paragraph to carry every detail.

If the violation came from a public inspection:

- inspection date
- inspection type
- agency or source reference
- official clause or text if available
- problem summary
- inspector or auditor comments when available

If the violation came from an audit:

- audit name or checklist name
- section
- question
- triggering response when applicable
- auditor comments when available
- linked photos when available

If the violation was manual:

- manually created indicator
- creator
- created date
- creator comments
- optional photos

### Layout recommendation

The screen should make both collaboration and structured remediation easy to reach.

A practical version 1 pattern is:

- summary at top
- `Issue Context` card directly under the summary
- evidence preview if available
- `Thread` and `Response` as tabs or segmented sections
- action buttons anchored near the bottom or in the screen action area

## 3. Thread Discussion Flow

### Goal

Allow the team to collaborate inside the violation record.

### Typical user actions

Users should be able to:

- add a comment
- mention a teammate
- attach a photo
- add a status update
- capture assignment-related notes

### How it should behave

- newest entries should appear clearly in the timeline
- thread history should be preserved
- discussion should remain readable as an operational record
- thread entries should not overwrite the structured response fields

### Example use cases

- staff posts proof photo after immediate containment
- manager asks for additional preventive action detail
- auditor adds clarifying note from the original finding

## 4. Structured Response Flow

### Goal

Capture the official remediation record for the violation.

### Response model

Version 1 should use one active structured response per violation.

That response can be completed in phases over time.

### Fields

The response should support:

- `responseGeneral`
- `responseContainment`
- `responseRootCause`
- `responseCorrectiveAction`
- `responsePreventiveAction`

### Evidence

The response should also allow lightweight evidence such as:

- images
- short videos
- documents

### Expected editing behavior

- users may fill only part of the response at first
- users may return later and expand it
- users should not be forced to complete every field for every violation
- more serious violations may encourage fuller responses

## 5. Working the Violation

### Goal

Support the normal active remediation phase between creation and manager review.

### Typical sequence

1. violation is created in `open`
2. staff, auditor, or manager adds thread updates
3. structured response begins to take shape
4. evidence is attached as needed
5. status may move to `in_progress`
6. training may be assigned if needed

### Important UX expectation

The app should make it easy to understand:

- what is already known
- what work has already been done
- what is still missing before review

## 6. Submit for Review Flow

### Goal

Allow staff or auditor to signal that the violation is ready for manager review.

### Primary actors

- staff
- auditor
- manager

### Steps

1. user opens the violation
2. user reviews the current thread and structured response
3. user selects `Submit for Review`
4. FiScore validates the minimum required response state
5. violation moves to `pending_review`
6. manager receives a review request signal or notification

### Recommended pre-submit checks

Depending on configuration and severity, the app may check for:

- at least one meaningful response field
- required evidence if policy demands it
- assignment completeness if used by the tenant

Version 1 should stay practical and not over-complicate this gate.

## 7. Manager Review Screen

### Goal

Let the manager review the full remediation picture before making a closure decision.

### What the manager should review

- violation header and source context
- structured response
- evidence
- thread history
- any linked training or follow-up context if visible

### Manager actions

Manager can:

- close the violation
- request more work
- reject the response
- edit the response before closing

### UX expectation

Review should feel like a focused approval screen rather than forcing the manager to reconstruct the whole history manually.

## 8. Close Violation Flow

### Goal

Complete the violation lifecycle with a manager-controlled close action.

### Steps

1. manager opens a violation in `pending_review`, `open`, or `in_progress`
2. manager reviews the response and evidence
3. manager optionally edits the response
4. manager chooses `Close`
5. FiScore records:
   - closing user
   - closing timestamp
6. violation status becomes `closed`

### Important rule

Version 1 does not require a separate closure form.

The structured response is the main closure record.

## 9. Request More Work or Reject Flow

### Goal

Allow the manager to send the violation back into active remediation.

### Steps

1. manager reviews the violation
2. manager determines the response is not sufficient
3. manager selects `Request More Work` or `Reject`
4. FiScore records the review outcome
5. violation moves back to `open`
6. the same active response remains available for continued editing

### UX expectation

The app should clearly show:

- why it was sent back
- what needs to be improved

## 10. Reopen Flow

### Goal

Allow the manager to reactivate a previously closed violation.

### Typical reasons

- issue recurred
- closure evidence was insufficient
- later verification failed

### Steps

1. manager opens a closed violation
2. manager selects `Reopen`
3. FiScore records reopen metadata
4. working status returns to `open`
5. prior thread and response history remain intact

### Important rule

Reopening should not create a brand-new isolated workflow object in version 1.

It should preserve continuity inside the same violation record.

## Example End-to-End Flows

### Public inspection violation

1. site is linked to master restaurant data
2. latest public inspection imports a finding
3. FiScore creates a tenant violation
4. staff discusses the issue in the thread
5. staff adds containment and corrective action details
6. staff submits for review
7. manager closes the violation

### Audit auto-trigger violation

1. auditor submits an internal audit
2. a configured failing response creates a violation
3. violation detail links back to the audit, section, question, and response
4. staff uploads proof photo and adds structured response details
5. manager reviews and closes

### Manual violation during audit

1. auditor notices an issue not directly tied to a trigger rule
2. auditor manually adds a violation during the audit
3. auditor enters title, severity, comments, and optional evidence
4. violation is linked to the site and audit
5. team works it through thread plus response
6. manager closes later

### Manual site violation

1. manager creates a violation directly against a site
2. manager enters title, severity, comments, and optional evidence
3. team collaborates and records remediation
4. manager reviews and closes

## Screen-Level Design Recommendations

### Violation List

- emphasize status and severity
- make pending review highly visible
- keep source context scannable

### Violation Detail

- keep source context visible near the top
- avoid burying the response and thread under too many tabs
- show the latest structured response summary near the top when helpful

### Thread

- optimize for quick updates and evidence sharing
- preserve a readable timeline

### Structured Response

- support partial completion over time
- avoid making every field mandatory for every violation
- keep evidence tied clearly to the response context

### Manager Review

- present closure decision actions clearly
- highlight missing remediation detail or missing evidence

### Status History

- preserve lifecycle history even if the current status is shown as a simple badge
- make important transitions readable, such as created, submitted for review, closed, and reopened
- use system notes in the thread and structured history records together when helpful

## Data and State Expectations

At the implementation level, the flow should align with:

- [WORKFLOWS.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\WORKFLOWS.md)
- [FEATURES.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\FEATURES.md)
- [DATA_MODEL.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\DATA_MODEL.md)
- [FIRESTORE_SCHEMA.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\app\FIRESTORE_SCHEMA.md)

Relevant Firestore areas include:

- `tenants/{tenantId}/violations/{violationId}`
- `tenants/{tenantId}/violations/{violationId}/threads/{threadEntryId}`
- `tenants/{tenantId}/violations/{violationId}/responses/{responseId}`
- `tenants/{tenantId}/violations/{violationId}/reviewDecisions/{decisionId}`
- `tenants/{tenantId}/violations/{violationId}/history/{historyId}`

## Summary

FiScore's violation experience should feel like a focused operational remediation workflow:

- one unified violation model across all sources
- clear site-scoped ownership
- thread-based collaboration
- structured remediation response
- manager-controlled review and closure
- preserved lifecycle and source traceability
