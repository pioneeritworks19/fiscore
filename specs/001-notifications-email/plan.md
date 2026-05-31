# Implementation Plan: Notifications and Email Strategy

**Branch**: `001-notifications-email` | **Date**: 2026-05-31 | **Spec**: `specs/001-notifications-email/spec.md`

**Input**: Feature specification from `specs/001-notifications-email/spec.md`

## Summary

FiScore needs a trusted notification and email foundation that preserves the existing action-item model. The implementation should keep operational work in in-app action items, add sparse backend-owned email delivery for account access and onboarding lifecycle events, and record every notification decision for support/debug visibility.

The first implementation slice should build the shared notification record/template/provider boundary, then wire team invite/resend and workspace-created emails. Setup nudges, admin visibility, and future push can build on the same model without changing core workflow transitions.

## Technical Context

**Language/Version**: Node.js 22 for Firebase Cloud Functions; Dart/Flutter for mobile app UI; React/Vite for Admin Console follow-up.

**Primary Dependencies**: `firebase-functions`, `firebase-admin`, existing callable/scheduled Cloud Functions, Firestore, Firebase Auth email-link flow. Transactional email provider to be introduced behind a small adapter; provider choice remains implementation-time but must support template variables, delivery response IDs, and sandbox/test mode. V1 email templates are code-owned renderer functions with English and Spanish system copy, rather than provider-managed or Firestore-managed customer-editable templates.

**Storage**: Firestore tenant-scoped notification records, delivery attempts, action items, invites, members, sites, and users. Existing Storage paths are not affected.

**Testing**: JavaScript syntax checks with `node --check`; focused Cloud Functions emulator/manual validation for callable and scheduled flows; Flutter static analysis for UI changes when app surfaces are touched. Unit tests can be introduced for pure notification decision helpers if practical.

**Target Platform**: Firebase Cloud Functions backend serving Flutter mobile/web app and later Admin Console.

**Project Type**: Multi-surface SaaS feature across Firebase backend, Flutter app, Firestore schema/rules, and later React admin visibility.

**Performance Goals**: Common dashboard/action reads remain bounded and query-specific. Notification writes must be part of existing business transitions where practical and must not add unbounded collection scans to user-facing operations.

**Constraints**: App must not send email directly. Operational email noise must be avoided. Notification decisions must be role-aware, tenant/site-scoped, deduped, and inspectable. Auth sign-in emails remain compatible with Firebase Auth. V1 uses lightweight tenant context in copy, not tenant-managed branding, logos, colors, sender domains, or editable templates.

**Scale/Scope**: Designed for many tenants with low per-tenant operational volume but long-lived history. Notification logs should be queryable by tenant, recipient, event type, status, and target without reading all history.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Tenant-first SaaS boundaries: PASS. Notification and delivery records are tenant-scoped except global user lifecycle state needed before workspace creation.
- Server-owned business transitions: PASS. Email/action decisions are owned by callable or scheduled backend workflows.
- Mobile-first, no-training operations: PASS. Staff daily work continues through action items; email is reserved for access/onboarding and future escalations.
- Three-surface system awareness: PASS. App, Cloud Functions, Firestore, Admin Console, and Ingestion boundaries are stated.
- Scalable reads, snapshots, and action items: PASS. Existing action item model remains primary; notification history is append/read-optimized.
- Product-safe notifications: PASS. Channels, recipients, triggers, dedupe, and audit expectations are explicit.
- Evolution without legacy drag: PASS. Dev data can be reseeded; production migration expectations must be explicit before pilot.

## Project Structure

### Documentation (this feature)

```text
specs/001-notifications-email/
|-- spec.md
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   `-- notification-functions.md
|-- checklists/
|   `-- requirements.md
`-- tasks.md
```

### Source Code (repository root)

```text
apps/fiscore_app/
|-- functions/
|   |-- index.js
|   |-- tenants.js
|   |-- team.js
|   |-- actions.js
|   |-- notifications.js          # new shared notification/email boundary, localized templates, provider adapter
|   `-- shared/runtime.js
|-- lib/
|   |-- data/repositories/
|   |-- features/actions/
|   |-- features/auth/
|   |-- features/dashboard/
|   `-- features/shell/
|-- firestore.rules
|-- firestore.indexes.json
`-- storage.rules

apps/tenant_admin_web/
`-- src/                         # later read-only delivery/status visibility

docs/product/
`-- NOTIFICATION_FLOW.md
```

**Structure Decision**: Use the existing Firebase Functions module structure. Add a notification module and keep provider-specific code behind an adapter so team, tenant, violation, audit, and training functions call a consistent business notification API. App/Admin changes should read notification/action data rather than duplicate business rules. Keep account/onboarding email templates in code for V1 so copy, localization, and tenant-context behavior are reviewed with the same PRs as the business workflow.

## Phase 0: Research Decisions

See `specs/001-notifications-email/research.md`.

## Phase 1: Design Artifacts

- Data model: `specs/001-notifications-email/data-model.md`
- Contracts: `specs/001-notifications-email/contracts/notification-functions.md`
- Quickstart validation: `specs/001-notifications-email/quickstart.md`

## Post-Design Constitution Check

- Tenant-first SaaS boundaries: PASS. Delivery and notification records include tenant/site/target context and global pre-tenant setup reminders are explicitly separated.
- Server-owned business transitions: PASS. Team invite, resend, tenant creation, and future lifecycle reminders are backend-owned.
- Mobile-first operations: PASS. No staff-facing workflow is moved to email.
- Three-surface awareness: PASS. Admin Console is read-only/follow-up, not a second sender.
- Scalable reads: PASS. Query and index requirements are included in the data model/tasks.
- Product-safe notifications: PASS. Dedupe, suppression, and status are first-class.
- Legacy drag: PASS. No legacy compatibility is required for early dev notification records.

## Complexity Tracking

No constitution violations require justification.
