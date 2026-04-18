# FiScore Sync Strategy

## Purpose

This document defines the offline-first synchronization approach for FiScore. The goal is to ensure restaurant teams can continue working without connectivity and trust that their data will not be lost, silently overwritten, or become inconsistent across devices.

FiScore operates in an environment where users may work in kitchens, storage rooms, basements, or older buildings with weak or unstable internet access. Because of that, synchronization is a core product capability rather than a background technical detail.

## Goals

- Support reliable offline usage for core workflows
- Save user actions immediately on the device
- Automatically sync when connectivity returns
- Prevent silent data loss or confusing overwrites
- Make sync state visible and understandable to users
- Provide a predictable conflict resolution model
- Maintain an audit trail for critical compliance-related changes

## Non-Goals

- Real-time collaboration for every field on every screen in version 1
- Fully automatic conflict resolution for all data types
- Perfect multi-device editing without any user review for high-risk records

## Product Principles

### 1. Local First

Every important user action should be written to the device first before cloud confirmation. Users should never feel that a failed network request means their work disappeared.

### 2. Eventual Cloud Sync

When the device is online, FiScore should attempt background synchronization automatically. The user should not need to manually retry normal operations.

### 3. No Silent Loss

If the system cannot safely merge changes, it should preserve both states or require review rather than silently overwriting one user's work.

### 4. Clear User Feedback

Users need clear signals that explain whether data is:

- saved locally
- waiting to sync
- synced successfully
- blocked by an error
- in conflict and awaiting review

### 5. Compliance-Aware Data Handling

Health inspections, violations, and corrective actions are operationally important and may have legal or regulatory significance. Changes to these records should be traceable.

## Scope of Offline Support

The following version 1 workflows should work offline:

- Sign in persistence after initial authentication
- Switching between restaurants already available to the user on the device
- Viewing recently synced inspections, audits, violations, and checklists
- Starting and completing an internal audit
- Creating, editing, and closing violations
- Adding notes, checklist responses, assignees, due dates, and corrective actions
- Inviting team members should be queued if initiated offline, but final account acceptance may still require connectivity

The following workflows may have limited offline support in version 1:

- First-time login on a brand-new device
- Pulling newly available restaurants not yet synced to the device
- Loading large analytics datasets beyond the cached range
- Media-heavy uploads if files are large and connectivity is poor

## Data Model Expectations

Each syncable record should include enough metadata to support conflict detection, auditability, and safe retries.

Suggested common fields:

- `id`: globally unique record identifier
- `tenantId`: organization identifier
- `restaurantId`: restaurant identifier
- `createdAt`: server timestamp for creation
- `updatedAt`: server timestamp for most recent accepted update
- `updatedBy`: user id of last accepted update
- `deviceId`: originating device id for the last update attempt
- `revision`: monotonically increasing revision number or version token
- `syncStatus`: local sync state such as `pending`, `synced`, `failed`, or `conflict`
- `deletedAt`: nullable soft-delete timestamp when applicable

For high-value compliance workflows, it is also useful to maintain:

- `changeReason`: optional explanation for important changes
- `closedAt` / `closedBy`: violation closure traceability
- `reopenedAt` / `reopenedBy`: reopening traceability

## Local Storage Strategy

FiScore should maintain a local database on the device for offline access and queued writes.

Recommended local storage responsibilities:

- Cache all user-accessible restaurants selected for offline work
- Store recent inspections, audits, violations, checklist templates, and assignments
- Maintain an outbound operation queue for pending writes
- Store per-record sync metadata separately from domain data when helpful
- Persist queue state across app restarts and device sleep

For Flutter, this usually means using a local persistence layer in addition to Firebase's built-in capabilities, especially if the app needs explicit sync state, operation queues, and conflict handling beyond default last-write-wins behavior.

## Synchronization Model

### Read Path

1. The app reads from local storage first.
2. If online, the app refreshes in the background from the server.
3. Any fresher server data updates the local cache.
4. The UI refreshes without blocking the user from accessing cached information.

### Write Path

1. The user performs an action.
2. The app validates the action locally.
3. The change is written to local storage immediately.
4. A sync operation is added to the outbound queue.
5. The UI shows that the change is saved locally and is pending sync if needed.
6. When online, the queue is processed automatically.
7. On successful server acknowledgment, the local record is updated to `synced`.
8. On failure, the record remains available locally and the sync state is updated accordingly.

## Queue Design

The outbound queue should be durable, ordered, and retryable.

Each queued operation should include:

- operation id
- record id
- record type
- action type such as create, update, close, reopen, delete
- payload delta or full payload snapshot
- local timestamp
- user id
- device id
- retry count
- last error code and message

Queue behavior should follow these rules:

- Preserve ordering for dependent operations on the same record
- Coalesce redundant updates when safe
- Retry transient failures automatically with backoff
- Stop retrying permanently invalid operations and surface them for review
- Avoid blocking the entire queue because of one failed record if operations are independent

## Conflict Detection

Conflicts happen when the local device edits a record based on stale information and another accepted server change already exists.

A conflict should be detected when:

- the local write is based on an older `revision` than the server record
- the record has changed on the server since the device last synced it
- the operation attempts to modify fields that were already changed elsewhere

Conflict detection should happen on records such as:

- violations
- inspection findings
- audit results
- corrective actions
- assignments

## Conflict Resolution Strategy

FiScore should use different strategies depending on the type of data being edited.

### Safe Auto-Merge Candidates

These can often be merged automatically if they are additive or independent:

- appended notes
- photo attachments
- comment threads
- checklist answers for untouched fields
- locally added draft observations with unique identifiers

### Cautious Merge Candidates

These may be auto-merged only with clear rules:

- due dates
- assignees
- status transitions
- priority levels

For example, a status change from `open` to `closed` should not be silently replaced by another device unless the business rule explicitly allows it.

### Manual Review Required

These should trigger a conflict review flow when edited concurrently:

- violation closure and reopening
- final inspection scores
- corrective action completion state
- audit completion sign-off
- any record with compliance significance or downstream reporting impact

## Recommended Business Rules

To keep sync behavior predictable in version 1, the app should adopt explicit rules such as:

- Never permanently delete important compliance records from the client; use soft delete
- Closing a violation requires preserving who closed it and when
- Reopening a closed violation should create a traceable state transition
- Notes should append rather than overwrite where possible
- Checklist responses should be field-based rather than whole-record replacement
- Analytics should be derived from synced source data, not treated as the source of truth

## User Experience Requirements

The UI should make sync behavior obvious without being noisy.

### Core Indicators

Use clear statuses such as:

- `Saved offline`
- `Syncing`
- `Synced`
- `Needs attention`
- `Conflict detected`

### UX Expectations

- Users should get immediate confirmation when an action is saved locally
- Pending sync items should remain visible and usable
- Errors should name the affected item and suggested next action
- Conflict messaging should be understandable to non-technical restaurant staff
- The app should avoid vague wording like "something went wrong" for sync issues

### Helpful Surfaces

- A small global network/sync banner
- Per-record sync badges for important records
- An activity center or sync queue screen for failed items
- A conflict review screen for high-risk records

## Failure Handling

### Temporary Failures

Examples:

- no connectivity
- timeouts
- transient Firebase service issues

Handling:

- keep data locally
- retry automatically
- show non-blocking status when appropriate

### Permanent or Business Rule Failures

Examples:

- permission revoked
- restaurant access removed
- invalid state transition
- record deleted or archived remotely in a conflicting way

Handling:

- stop blind retries
- preserve unsynced local data until reviewed
- surface a clear resolution path to the user or admin

## Audit Trail Requirements

Important actions should be reconstructable later for trust and compliance.

Recommended audit events:

- violation created
- violation updated
- violation closed
- violation reopened
- audit started
- audit completed
- corrective action assigned
- corrective action completed

Each audit event should ideally capture:

- event type
- record id
- restaurant id
- actor user id
- device id
- timestamp
- changed fields or summary

## Firebase Considerations

Firebase provides a strong starting point, but FiScore should not rely on default sync behavior alone for critical workflows.

Important considerations:

- Firestore offline persistence helps with caching and queued writes
- Default behavior may still feel opaque to users unless explicit sync state is modeled in the app
- Firestore alone does not provide a complete product-level conflict UX
- Security rules must be aligned with tenant and restaurant boundaries
- Cloud Functions may be useful for server-side validation, audit logging, notifications, and conflict-aware workflows

## Recommended Version 1 Architecture

For version 1, a practical approach is:

- Flutter app with explicit local persistence layer
- Firestore as the primary cloud data store
- Offline queue for domain operations
- Sync service responsible for retries, conflict checks, and status updates
- Cloud Functions for selected server-side business rules and audit logging

This gives the team more control than depending only on implicit Firestore sync behavior.

## Open Design Decisions

These decisions should be finalized before deep implementation:

- Which local database to use in Flutter
- Whether `revision` is client-managed, server-managed, or function-validated
- Which fields are field-mergeable versus review-required
- Whether conflict review lives fully in mobile apps or also in the web app
- How much historical data should be cached per restaurant
- How photo and attachment uploads behave during long offline periods

## Suggested Next Technical Deliverables

- Data model spec for inspections, audits, and violations
- Sync state diagram
- Conflict resolution matrix by entity and field
- Local storage architecture decision
- API and Cloud Function responsibilities
- UX wireframes for offline and sync states

## Summary

FiScore should be built as an offline-first system where user trust is protected through immediate local saves, durable queued synchronization, explicit sync status, and careful conflict handling. The design should prioritize predictability and traceability over aggressive automatic merging for compliance-relevant data.

