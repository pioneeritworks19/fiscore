# Training Execution Flow

## Purpose

This document defines the setup and execution flow for the FiScore Training module in version 1.

It covers:

- FiScore library training versus tenant training
- training creation, editing, and publishing
- training assignment
- trainee completion flow
- training reporting

## Core Principle

FiScore training should function as an operational remediation tool, not as a generic LMS.

Training should help teams:

- fix real issues
- improve audit performance
- reinforce expected food-safety behavior

## Training Sources

FiScore should support two main training sources.

### 1. Library Training

Library training is FiScore-provided content that can be used across tenants.

Examples:

- handwashing basics
- hot holding temperature basics
- sanitizer testing basics
- allergen awareness refresher

Recommended characteristics:

- authored and maintained by FiScore
- reusable across tenants
- assignable by tenant managers
- suited for common food-safety topics

### 2. Tenant Training

Tenant training is customer-created content available only within that tenant.

Examples:

- company SOP refresher
- internal onboarding content
- site-specific process reminders
- local retraining content

Recommended characteristics:

- owned by the tenant
- editable only by permitted tenant users
- available for tenant-specific assignment

## Training Types

Version 1 should support:

- `full_course`
- `micro_learning`

### Full Course

Used for:

- onboarding
- broader refresher training
- annual or periodic compliance refreshers

### Micro-Learning

Used for:

- violation follow-up
- targeted coaching
- focused retraining after audits

## Training Library Model

The training area should present a simple library model with two buckets:

- `FiScore Library`
- `Tenant Library`

Recommended user outcomes:

- browse available training
- search by title or topic
- filter by type
- review training details before assignment

When a tenant starts from FiScore Library content, the product should support two explicit creation modes:

- `Synced from Library`
- `Created from Library`

`Synced from Library` means:

- the tenant gets a tenant-owned training record linked to the source library item
- newer library versions can surface as `Update available`
- the tenant chooses when to adopt the newer version
- the tenant may later detach from the library relationship

`Created from Library` means:

- the tenant gets a one-time tenant-owned copy
- no future sync is expected

## 1. Training Setup Flow

### Goal

Allow FiScore library training to be available across tenants and allow tenants to create and manage their own training content.

### Recommended user roles

Version 1 should keep assignment manager-driven, but tenant training setup should also be controlled.

Recommended setup roles:

- `tenant_owner`
- `admin`
- `manager`

### Training Setup Entry Points

Users should be able to enter training setup from:

- training library
- tenant administration or content area
- assignment flow when they realize a needed training item does not yet exist

### Recommended setup actions

From the library, users should be able to choose:

- `Assign`
- `Synced from Library`
- `Created from Library`

`Assign` is appropriate when the tenant is comfortable using the current tenant-active version immediately.

`Synced from Library` is appropriate when the tenant wants FiScore to keep offering newer library versions over time.

`Created from Library` is appropriate when the tenant wants a starting point with no future update linkage.

## 2. Create Tenant Training Flow

### Goal

Allow a tenant to create its own training content.

### Steps

1. user opens the training library
2. user selects `Create Training`
3. user chooses training type:
   - `full_course`
   - `micro_learning`
4. user enters core metadata
5. user adds topics or content blocks
6. user optionally enables a quick check
7. user saves as draft or publishes

### Recommended training fields

- title
- description
- training type
- duration estimate
- training source
- status
- risk area tags
- site availability if site-specific control is later needed

### Recommended status values

- `draft`
- `active`
- `archived`

### Versioning recommendation

- tenant training should include a version number
- draft training may be edited more freely
- if training has already been assigned, meaningful content changes should create a new version for future assignments
- the app should avoid silently changing the content for users who already have an assignment in progress

## 3. Edit Tenant Training Flow

### Goal

Allow permitted tenant users to improve or update tenant-owned training.

### Steps

1. user opens a tenant training item
2. user edits metadata, topics, or quick check
3. user saves the updates
4. FiScore preserves the updated training record for future assignments

### Important recommendation

Version 1 should keep training editing practical and avoid deep versioning complexity unless future compliance needs require it.

If the training is already assigned and the content change is meaningful, FiScore should guide the user toward creating a new version instead of overwriting the assigned version in place.

### Recommended behavior when assignments already exist

- users already assigned the training remain on their assigned version
- users already in progress remain on their assigned version
- completed assignments remain tied to their completed version
- new assignments use the newest active version
- if the training is synced from the library, adopting a newer library version should update future tenant versions only, not existing assignments

## 4. Publish or Activate Training Flow

### Goal

Make training available for assignment.

### Steps

1. user completes or reviews the training item
2. user activates or publishes the training
3. FiScore makes it available in the assignable training library

### Recommended rule

- `draft` training should not appear in normal assignment lists
- `active` training should be assignable
- if a newer version is published, new assignments should use that newer version
- existing assignments should remain linked to the earlier assigned version
- library-linked training should upgrade through an explicit tenant action rather than silent live mirroring

## 5. Quick Check Setup Flow

### Goal

Allow optional lightweight knowledge checks without turning FiScore into a full testing engine.

### Recommended version 1 model

Quick check should be:

- optional
- short
- easy to author
- operationally relevant

### Suggested setup pattern

When editing a training item:

1. user toggles `Include Quick Check`
2. FiScore shows a small quick-check builder
3. user adds 1 to 3 questions
4. user selects:
   - `true_false`
   - `single_choice`
5. user enters the correct answer
6. user optionally adds an explanation

### Important guidance

Quick checks should stay simple in version 1:

- no advanced quiz engine
- no timed exams
- no complex scoring rules
- no large question banks

## 6. Risk Area Model

### What risk area means

`riskArea` is the operational topic the training is about.

Examples:

- handwashing
- temperature_control
- cross_contamination
- cleaning_and_sanitizing
- chemical_safety
- allergen_control

### How risk area should be used

Version 1 should avoid asking managers to manually enter risk area during routine assignment.

Recommended sources for `riskArea`:

- defined on the training item itself
- derived from violation or audit context when obvious
- optionally selected by a manager only in less common general-assignment scenarios

### Recommended rule

Treat `riskArea` primarily as:

- a training category
- a recommendation signal
- a reporting dimension

Not as a required user-entered field during normal assignment.

## 7. Training Assignment Flow

### Goal

Allow managers to assign relevant training to specific users.

### Primary actor

- `manager`

### Assignment entry points

Training may be assigned from:

- a violation
- a violation created after an internal-audit issue is submitted
- the training library
- a general team-management need

### Steps

1. manager opens a violation or selects `Assign Training` from the training area
2. FiScore opens a searchable training-library assignment flow
3. FiScore may recommend training based on linked context
4. manager selects a training item
5. manager selects one or more active users with access to the site from a searchable teammate picker
6. manager sets due date
7. manager optionally adds an assignment note
8. FiScore creates one independently trackable assignment per selected user

Assignments are site-scoped: a user may only be assigned training for a site they can access.

### Recommended linkage model

Assignments should support linkage to:

- `violationId`
- `siteId`
- `assignedTo`
- `trainingVersion`

Optional broader context may also include:

- `riskArea`

### Important simplification

Version 1 should not require a separate `violationResponseId` or `auditId` link.

Linking to the violation itself is enough for corrective training and keeps the model simpler, including when that violation originated in an internal audit.

## 8. Assigned User Completion Flow

### Goal

Allow the assigned user to complete training with minimal friction.

### Entry point

The assigned user should see training in:

- `My Training`
- `My Tasks`
- the dashboard `Training assigned to me` queue
- violation-linked context where appropriate

### Steps

1. user opens assigned training
2. user sees a short overview and starts the lesson
3. user moves through practical topic pages one at a time
4. user completes the quick check configured on the assigned lesson
5. FiScore reveals whether the answer is correct, highlights the correct response, and shows a concise explanation
6. FiScore records completion state and shows a simple completion summary

For FiScore starter micro-learning, lesson sections and quick-check questions are maintained in the Training library configuration. When assigned, that content is snapshotted onto the assignment so later library updates do not change training already assigned or completed.

### Media-enabled lessons

Lesson sections may include ordered `blocks` of type `text`, `image`, `video`,
or `tip`. Existing text-only sections remain supported.

  - FiScore Library images and videos live in immutable versioned Storage paths.
  - Each lesson version stores media metadata by `mediaId`; topic blocks
    reference that ID instead of containing Storage paths.
- Tenant adoption retains media references instead of copying the file into
  every tenant.
- Assignment section snapshots retain the exact versioned media references
  assigned to the employee.
- A lesson with changed learning media becomes a newer library version and
  appears as `Update` in `Explore FiScore`.
  - Required short videos prevent progression until playback completes.
  - Longer demonstration videos are optional supplemental content in
  micro-learning lessons.

### Recommended assignment states

- `assigned`
- `in_progress`
- `completed`
- `overdue`
- `cancelled`

## 9. Completion Tracking Flow

### Goal

Keep completion operational and easy to understand.

### Recommended captured fields

- started at
- last active at
- completed at
- progress percent
- quick check result when present
- assigned training version
- snapshotted lesson sections and quick-check questions
- incorrect answer count for the quick check
- completion summary snapshot

### Important recommendation

Version 1 should focus on completion and accountability, not advanced certification logic.

A printable certificate is not part of version 1. A clean in-app completion summary is appropriate for short operational coaching.

### Assignment cancellation

- tenant owners, admins, and managers may cancel an active training assignment
- cancellation preserves the assignment record and stores who cancelled it and when
- cancelled training no longer appears in the assigned user's active worklist or overdue counts
- managers can review cancelled assignments as history

## 10. Training Reporting Flow

### Goal

Help managers understand who completed training and whether it influenced improvement.

### Recommended reporting views

- assigned versus completed
- overdue by user
- overdue by site
- training linked to violations
- training linked to audit context
- training by risk area
- later audit outcomes after training

### Key reporting questions

Managers should eventually be able to answer:

- who still has training overdue?
- which sites are missing key remediation training?
- which violations resulted in training assignments?
- did later audits improve after training was completed?

## Example End-to-End Flows

### Violation-driven assignment

1. manager opens a temperature-control violation
2. FiScore suggests `Holding Temperature Basics`
3. manager assigns it to one staff member
4. due date is set
5. staff completes the training
6. FiScore links completion back to the violation and site

### Audit-driven assignment

1. manager reviews a completed audit
2. repeated handwashing weakness is visible
3. manager assigns handwashing micro-learning to the shift team
4. staff complete the training
5. later audit outcomes are compared against prior training activity

### Tenant-created training

1. tenant manager creates `Opening Shift Sanitizer Check`
2. manager adds short instructions and 2 quick-check questions
3. manager publishes the training
4. manager assigns it to new hires at one site

## Screen-Level Recommendations

### Training Library

- separate FiScore and tenant content clearly
- make training type and duration easy to scan
- show assignable status clearly
- show whether a tenant item is `Synced from Library`, `Created from Library`, or `Tenant Custom`
- show `Update available` when a newer library version exists for a synced tenant item

### Training Detail

- keep title, description, duration, and topic summary near the top
- show whether the item is FiScore-provided or tenant-created
- keep quick check expectations visible if enabled

### Assignment Screen

- keep manager decisions simple:
  select training, one or more users, due date
- open as a dedicated searchable library flow so the catalog can scale
- show linked violation context when relevant

### My Training

- make this the default Training landing view
- emphasize assigned, in-progress, overdue, and completed sections
- allow quick resume

### Team Progress

- provide a separate manager view for open, overdue, completed, and all assignments
- make overdue training reachable from the dashboard

### Reporting

- prioritize operational accountability over academic course analytics

## Summary

FiScore training in version 1 should support two content sources, two training types, manager-driven assignment, simple completion tracking, optional lightweight quick checks, and reporting tied back to sites, violations, and audits. Library content should be presented as FiScore Library rather than live system-owned records inside tenant workflows, and tenants should be able to either stay synced to library updates or create detached one-time copies. The experience should stay practical and intuitive rather than growing into a full LMS.
