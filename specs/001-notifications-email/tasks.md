# Tasks: Notifications and Email Strategy

**Input**: Design documents from `specs/001-notifications-email/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/notification-functions.md`, `quickstart.md`

**Tests**: Include focused backend checks and manual/emulator validation. Full Flutter analysis is only required for app UI changes.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

**Reconciliation note (2026-06-04)**: Checklist status reflects code merged through PR #25 and Firebase Functions/Firestore deployment to `fiscore-dev`. Manual validation, provider selection, and admin-console notification history remain open.

**Provider note (2026-06-06)**: Resend is the selected V1 transactional email provider, behind the existing notification adapter. `noop` remains the default until `FISCORE_EMAIL_PROVIDER=resend`, the `RESEND_API_KEY` Firebase Secret Manager secret, and sender environment configuration are set for the target Firebase project.

**Provider delivery note (2026-06-07)**: Resend delivery webhooks are wired through `receiveResendWebhook`, with `RESEND_WEBHOOK_SECRET` in Firebase Secret Manager and a `deliveryAttempts.providerMessageId` collection-group index. Admin Console notification history shows rendered email content, delivery attempts, and provider delivery metadata after webhook replay/success.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare the notification/email backend boundary.

- [x] T001 Create `apps/fiscore_app/functions/notifications.js` with exported notification decision, dedupe, and email adapter helpers.
- [x] T002 Export the notification helpers from `apps/fiscore_app/functions/index.js` only if callable or scheduled functions are added.
- [x] T003 [P] Add code-owned `en`/`es` notification template constants for account access and onboarding emails in `apps/fiscore_app/functions/notifications.js`.
- [x] T004 [P] Document required provider environment variables in `apps/fiscore_app/functions/README.md` or `docs/product/NOTIFICATION_FLOW.md`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data and delivery plumbing that all stories use.

- [x] T005 Define notification event and delivery attempt write helpers in `apps/fiscore_app/functions/notifications.js`.
- [x] T006 Add dedupe key generation and suppression checks in `apps/fiscore_app/functions/notifications.js`.
- [x] T007 Add provider adapter interface, locale fallback helper, and `noop`/sandbox behavior in `apps/fiscore_app/functions/notifications.js`.
- [x] T008 Add Firestore rules for tenant notification event read access in `apps/fiscore_app/firestore.rules`.
- [x] T009 Add required Firestore composite indexes for notification event query shapes in `apps/fiscore_app/firestore.indexes.json`.
- [x] T010 [P] Add syntax validation notes for `node --check index.js` and `node --check notifications.js` to `specs/001-notifications-email/quickstart.md` if commands change.

**Checkpoint**: Notification decisions can be recorded and delivery attempts can be written without sending real email.

---

## Phase 3: User Story 1 - Invite and access emails get users into the right workspace (Priority: P1) MVP

**Goal**: Tenant owner/admin invite and resend flows send clear account-access emails and record delivery state.

**Independent Test**: Invite and resend a staff user; verify pending invite state, notification event, delivery attempt, and invite acceptance.

- [x] T011 [US1] Wire `createTenantInvite` in `apps/fiscore_app/functions/team.js` to record/send `team_invite_created`.
- [x] T012 [US1] Wire `resendTenantInvite` in `apps/fiscore_app/functions/team.js` to record/send `team_invite_resent`.
- [x] T013 [US1] Ensure invite email template identifies FiScore, includes workspace name, tenant context, inviter/context when available, role/site context, and join CTA in `apps/fiscore_app/functions/notifications.js`.
- [x] T014 [US1] Ensure rapid resend attempts use dedupe/suppression behavior in `apps/fiscore_app/functions/notifications.js`.
- [x] T015 [US1] Validate invite/resend flow against `specs/001-notifications-email/quickstart.md`.

**Checkpoint**: Invite and resend emails are usable without changing operational action items.

---

## Phase 4: User Story 2 - First-time owner understands their new workspace (Priority: P1)

**Goal**: New tenant owners receive a workspace-created orientation message after workspace creation.

**Independent Test**: Create a new workspace from a fresh owner account; verify notification event, delivery attempt, and first-owner orientation copy.

- [x] T016 [US2] Wire `createTenantAndOwner` in `apps/fiscore_app/functions/tenants.js` to record/send `workspace_created`.
- [x] T017 [US2] Add localized workspace-created template copy with FiScore sender identity and tenant context in `apps/fiscore_app/functions/notifications.js`.
- [x] T018 [US2] Include app return path, add/link restaurant next step, website/help mention, and admin console mention in template data in `apps/fiscore_app/functions/notifications.js`.
- [x] T019 [US2] Add dedupe protection for retried workspace creation in `apps/fiscore_app/functions/notifications.js`.
- [ ] T020 [US2] Validate workspace-created flow against `specs/001-notifications-email/quickstart.md`.

**Checkpoint**: First owner receives one clear orientation email.

---

## Phase 5: User Story 3 - Operational notifications point users to important work without noise (Priority: P1)

**Goal**: Existing violation, training, and check action item flows remain action-item-first and do not send email for low-value work.

**Independent Test**: Exercise existing operational transitions and verify action items change while outbound email attempts are not created for notes, draft saves, photos, or routine status changes.

- [x] T021 [US3] Review `apps/fiscore_app/functions/actions.js` and document which action item types are non-email by default.
- [x] T022 [US3] Add guard or helper naming in `apps/fiscore_app/functions/notifications.js` that makes operational email opt-in rather than default.
- [x] T023 [US3] Verify `submitViolationForReview`, `sendViolationBack`, training assignment, and check assignment still create action items in `apps/fiscore_app/functions/violations.js`, `apps/fiscore_app/functions/training.js`, and `apps/fiscore_app/functions/audits.js`.
- [ ] T024 [US3] Validate no email delivery attempts are created for notes, draft saves, attachment uploads, and normal operational action item creation using `specs/001-notifications-email/quickstart.md`.

**Checkpoint**: Operational workflows remain low-noise.

---

## Phase 6: User Story 4 - Incomplete onboarding gets a gentle nudge (Priority: P2)

**Goal**: Stalled setup receives sparse lifecycle reminders without creating operational action items.

**Independent Test**: Simulate no-workspace and no-site states; verify reminders send only while conditions remain true.

- [x] T025 [US4] Add scheduled or callable-testable helper for signed-in users with no workspace in `apps/fiscore_app/functions/notifications.js`.
- [x] T026 [US4] Add scheduled or callable-testable helper for workspaces with no sites in `apps/fiscore_app/functions/notifications.js`.
- [x] T027 [US4] Add localized templates for `signed_in_no_workspace` and `workspace_has_no_site` in `apps/fiscore_app/functions/notifications.js`.
- [x] T028 [US4] Ensure reminder helpers re-check eligibility immediately before delivery in `apps/fiscore_app/functions/notifications.js`.
- [x] T029 [US4] Export scheduled reminder functions from `apps/fiscore_app/functions/index.js`.
- [ ] T030 [US4] Validate reminder scenarios against `specs/001-notifications-email/quickstart.md`.

**Checkpoint**: Setup reminders recover abandoned setup without daily spam.

---

## Phase 7: User Story 5 - Users and support can understand notification status (Priority: P2)

**Goal**: Admin/support can inspect sent, failed, skipped, and suppressed states.

**Independent Test**: Trigger each V1 notification category and inspect stored notification event/delivery records.

- [x] T031 [US5] Add query indexes for tenant notification events by status, event type, recipient, and target in `apps/fiscore_app/firestore.indexes.json`.
- [x] T032 [US5] Add a read-only repository or admin-console data access plan for notification events in `apps/tenant_admin_web/src` when admin UI is implemented.
- [x] T033 [US5] Add support-facing status definitions to `docs/product/NOTIFICATION_FLOW.md`.
- [x] T034 [US5] Validate support/debug inspection using Firestore records created by prior stories and document gaps in `specs/001-notifications-email/quickstart.md`.

**Checkpoint**: Delivery behavior can be understood without raw function logs.

---

## Phase 8: User Story 6 - Notification preferences stay simple but extensible (Priority: P3)

**Goal**: Safe defaults exist now, with a path for future user preferences.

**Independent Test**: New users receive required access emails without configuring preferences; optional categories can be modeled later without changing event records.

- [x] T035 [US6] Document V1 default preferences in `docs/product/NOTIFICATION_FLOW.md`.
- [ ] T036 [US6] Add placeholder preference entity notes to `docs/app/FIRESTORE_SCHEMA.md` only if implementation stores preference data.
- [x] T037 [US6] Ensure required account/security emails bypass optional preference suppression in `apps/fiscore_app/functions/notifications.js`.

**Checkpoint**: Preference design is future-ready but not overbuilt.

---

## Phase 9: Polish & Cross-Cutting Concerns

- [x] T038 [P] Run `node --check index.js` from `apps/fiscore_app/functions`.
- [x] T039 [P] Run `node --check notifications.js` from `apps/fiscore_app/functions`.
- [ ] T040 [P] Run `flutter analyze` from `apps/fiscore_app` only if Flutter files are touched.
- [x] T041 Deploy updated Firebase Functions and Firestore rules/indexes from `apps/fiscore_app` to `fiscore-dev`.
- [x] T042 Update implementation notes in `docs/product/NOTIFICATION_FLOW.md` after the first provider is selected.

---

## Dependencies & Execution Order

### Phase Dependencies

- Phase 1 Setup has no dependencies.
- Phase 2 Foundational depends on Phase 1 and blocks all user stories.
- US1 and US2 are the MVP email slices and can be implemented after Phase 2.
- US3 can run in parallel after Phase 2 because it validates the non-email boundary.
- US4 depends on Phase 2 and can follow US2.
- US5 depends on notification records created by US1/US2/US4.
- US6 can be deferred until preference UI/product need appears.

### MVP Scope

MVP is Phase 1, Phase 2, US1, and US2:

- notification record/delivery foundation
- team invite/resend email
- workspace-created orientation email

### Parallel Opportunities

- T003/T004 can run in parallel.
- T010 can run in parallel with most foundational code work.
- US1 and US2 can be split between developers after notification helpers exist.
- US3 validation can run while US1/US2 templates are refined.
- US5 admin visibility can be deferred or assigned separately after records exist.

## Implementation Strategy

1. Build a no-op/sandbox notification foundation first.
2. Wire invite/resend emails and validate with dev users.
3. Wire workspace-created orientation email.
4. Confirm operational action item flows do not generate email noise.
5. Add sparse onboarding reminders.
6. Add support/admin visibility after delivery records are stable.
