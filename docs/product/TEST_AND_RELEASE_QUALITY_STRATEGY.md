# FiScore Test And Release Quality Strategy

## Purpose

This document defines the test automation and release-quality strategy for
FiScore after the initial MVP. FiScore stores food-safety work, evidence,
training completion, tenant access, and review decisions. A release can look
visually correct while still damaging trust if it loses proof, exposes one
tenant's data to another, creates the wrong action, or closes work incorrectly.

The strategy therefore favors:

- testing business workflows, not only screens
- automated tenant and role security checks
- server-side workflow integrity tests
- mobile-first usability coverage for critical field work
- controlled production rollout with useful diagnostics

## Current Baseline As Of May 25, 2026

The repository does not yet have a complete release-grade automated testing
system.

Present today:

- Python parser/request tests under `tests/`
- one Flutter welcome-screen widget test under `apps/fiscore_app/test/`
- `flutter analyze` as a manual application quality check
- JavaScript syntax checks available for Firebase Functions
- manual development validation of the principal app workflows
- manual production rollout and smoke-test guidance

Not yet present:

- automated tests for callable Firebase Functions
- Firestore and Storage Security Rules unit tests
- Flutter repository or workflow widget tests
- Flutter integration tests covering sign-in and core operational flows
- browser/mobile visual regression checks
- CI quality gates on pull requests
- automated post-deploy smoke tests
- Crashlytics-based mobile release health monitoring

## Quality Goals

FiScore should reach these goals before broad paid-customer rollout:

1. No tenant-crossing data access can be introduced without a failing automated
   security test.
2. Status changes, assignments, action items, and completion records are
   validated through backend workflow tests.
3. The most important restaurant-staff journeys run automatically before
   release.
4. Media workflows are verified on a real phone-class device, not only Chrome.
5. Releases are promoted through a repeatable gate with rollback readiness and
   monitoring.

## Risk-Based Testing Priorities

### Highest Risk

- tenant isolation and site access permissions
- manager-only actions such as closure and team administration
- violation submit, send back, close, and reopen transitions
- training assignment, completion, cancellation, and overdue state
- action inbox accuracy and deep linking
- audit submission creating correct violations
- evidence attachment storage, visibility, deletion, and source context

### High Risk

- invite acceptance and role/access updates
- FiScore Library version adoption and assignment/checklist snapshots
- report and training media access
- offline or interrupted saves during restaurant work
- ingestion data projected into tenant sites

### Normal Risk

- labels, chips, summaries, empty states, and secondary navigation
- cosmetic spacing and visual polish

## Test Layers

| Layer | Purpose | Tooling | Runs When |
| --- | --- | --- | --- |
| Static checks | Catch compile, lint, syntax, and formatting issues | `flutter analyze`, `dart format`, `node --check`, `ruff` | Every pull request |
| Unit tests | Test calculations, mapping, parsing, display logic, and pure helpers | `flutter_test`, `pytest`, Node test runner | Every pull request |
| Rules tests | Prove tenant, role, and storage access boundaries | Firebase Emulator Suite, `@firebase/rules-unit-testing` | Every pull request touching rules/data access |
| Function workflow tests | Verify atomic business transitions and action-item population | Firebase Functions + Firestore emulators, Node test runner | Every pull request touching Functions/workflows |
| Flutter widget tests | Verify major states and interactions without a full backend | `flutter_test` | Every pull request touching UI |
| Integration tests | Verify complete user journeys against controlled backend state | Flutter `integration_test`, Firebase emulators or dev test tenant | Before merge for critical flows, before release |
| Visual/device tests | Catch mobile layout and media regressions | screenshots on phone/tablet/browser, later golden tests | Before release for UI-heavy work |
| Production validation | Confirm deployed system health | smoke run, Cloud Logging, Crashlytics, alerts | Each production release |

## Test Architecture Recommendation

### Local And CI Test Environment

Use the Firebase Local Emulator Suite for automated tenant-app tests:

- Authentication emulator for test identities
- Firestore emulator for tenant data and security rules
- Cloud Functions emulator for callable workflows
- Storage emulator for attachment access and metadata tests

Tests must never depend on the production Firebase project. A separately
controlled `fiscore-dev` smoke tenant can remain useful for human acceptance
testing after emulator tests pass.

### Deterministic Test Data

Create small reusable fixtures:

- one tenant
- two sites
- tenant owner, admin, manager, auditor, staff, and inactive staff accounts
- one imported public violation
- one internal-audit violation
- one training item and one checklist template
- sample image proof and short sample video

Each automated test suite should seed only the state it needs and delete or
reset emulator state afterward.

### Backend Ownership Boundary

Test writes according to their true owner:

- Draft response, note, and permitted proof upload tests may use the client
  boundary.
- Submit, send back, close, reopen, training assignment, training completion,
  cancellation, and action-item creation must be tested through callable Cloud
  Functions.
- Client attempts to bypass server-owned transitions must fail Security Rules
  tests.

This prevents tests from validating a path that production users should not be
allowed to take.

## Critical Workflow Automation Matrix

### Access And Team

| Scenario | Expected Result | Priority |
| --- | --- | --- |
| Owner invites staff with selected site access | Invite is visible and accepted member receives only assigned site | Critical |
| Inactive user signs in | Cannot access tenant work | Critical |
| Manager attempts tenant-admin-only team administration | Rejected | Critical |
| Staff attempts to read another tenant | Rejected by rules | Critical |
| Access changes while user is signed in | New access is reflected without data leakage | High |

### Violations And Action Inbox

| Scenario | Expected Result | Priority |
| --- | --- | --- |
| Staff saves a draft fix | Draft persists; no manager review action yet | High |
| Staff submits valid fix | Violation becomes pending review and reviewer action is created atomically | Critical |
| Staff submits without required resolution | Function rejects submission; no action created | Critical |
| Manager sends fix back | Review action closes; submitting user gets follow-up action and feedback | Critical |
| Manager closes submitted fix | Violation closes; review action closes; site counts remain correct | Critical |
| Staff tries to close a fix | Rejected | Critical |
| Inbox action tapped | Opens exact linked violation or training assignment | High |

### Internal Audits

| Scenario | Expected Result | Priority |
| --- | --- | --- |
| User completes checklist with no attention items | Audit submits with no violations | High |
| Attention answer includes observation and photo | Submitted audit creates violation with observed proof preserved | Critical |
| Submitted audit is reopened or duplicated accidentally | Duplicate violation behavior is prevented or controlled | High |
| Checklist snapshot after template update | Completed audit retains original questions/version | High |

### Training

| Scenario | Expected Result | Priority |
| --- | --- | --- |
| Manager assigns training to site-authorized staff | Assignment and action item are created | Critical |
| Manager assigns training to staff without site access | Rejected | Critical |
| Staff selects wrong quick-check answer | Correction appears and course completion rules are honored | High |
| Staff completes training | Completion snapshot saved and open action closes | Critical |
| Manager cancels assignment | Staff action closes and assignment remains in history | High |
| Incomplete assignment passes due date | Scheduled workflow marks action overdue | High |
| Assigned version is later updated in library | Existing assignment retains assigned snapshot | Critical |

### Media And Reports

| Scenario | Expected Result | Priority |
| --- | --- | --- |
| Camera photo is added to fix | Immediate preview, later durable thumbnail and full image view | Critical |
| Photo is attached to audit observation | Violation proof preserves source context after submission | Critical |
| User without access requests media URL/file | Rejected | Critical |
| Training image/video loads from FiScore Library | Authorized user can view; required video gate functions | High |
| Stored public report is unavailable or malformed | App fails gracefully and does not expose ingestion URL | High |

## Frontend Test Strategy

### Unit And Widget Tests

Add tests for:

- status and severity label rendering
- dashboard action counts and empty states
- collapsed/expanded source and violation details
- resolution form validation
- action inbox rows and filters
- audit section navigation, review summary, and submission states
- training lesson navigation, quick-check feedback, and completion summary
- member/invite states and site access controls

Use repository/service interfaces or injectable fakes so widget tests are not
forced to talk to Firebase.

### Integration Tests

Create a small set of durable, high-value flows:

1. Staff resolves a violation, manager reviews and closes it.
2. Manager sends a violation back, staff sees the action and resubmits.
3. Auditor submits an internal check with proof and follows the generated
   violation.
4. Manager assigns training, staff completes lesson and check, action closes.
5. Owner changes site access and user immediately loses inaccessible site data.

Run these initially on Chrome for speed, then on Android for mobile execution,
camera/media, keyboard, bottom-sheet, and responsive layout behavior. Add iOS
execution once the native sign-in and build pipeline is active.

### Visual Validation

For screens staff repeatedly use, maintain screenshot fixtures at:

- narrow phone portrait
- typical modern phone portrait
- tablet portrait or landscape where audit execution is important

Priority screens:

- dashboard
- violation resolution and proof
- audit execution and review
- training lesson and quick check
- action inbox

Visual tests should catch overflow, clipped media, missing thumbnails, disabled
primary-action confusion, and tap targets that are too cramped.

## Firebase Backend Test Strategy

### Callable Functions

Test Functions with emulated Auth, Firestore, Functions, and Storage where
relevant.

Minimum automated Function coverage:

- team invite, accept, reactivate, update access, deactivate
- site linking and master-data sync projection
- internal audit creation and submission
- library listing and tenant adoption
- violation review transition functions
- training assignment/completion/cancellation functions
- attachment processing behavior
- overdue action scheduling behavior

For every server workflow function test:

- assert successful document changes
- assert action item changes where relevant
- assert site summary/count updates where relevant
- assert unauthorized roles fail
- assert repeated invocation is safe or produces a controlled result

### Security Rules

Security Rules tests are release blockers. Test Firestore and Storage
independently of UI behavior.

Minimum rule personas:

- signed out
- tenant owner
- admin
- manager
- auditor
- staff
- inactive member
- member of another tenant
- site-limited member without access to the target site

Required assertions:

- each persona can read only allowed tenants/sites
- server-owned action items cannot be created or completed by clients
- server-owned status/assignment transitions cannot be forged by clients
- drafts, notes, and authorized proof uploads remain usable
- uploaded media cannot be accessed across tenants or unauthorized sites

## Ingestion And Master Data Test Strategy

The ingestion backend currently has some Python parser coverage. Expand it
into a fixture-driven suite:

- request construction tests per source/jurisdiction
- HTML/JSON parsing fixtures for normal, empty, malformed, and changed pages
- normalization and deduplication tests
- report-artifact handling tests
- projection tests ensuring only intended latest findings become active tenant
  violations
- regression fixtures for every production parsing incident

Any parser bug found in production should create a new permanent fixture before
the code fix is released.

## Performance, Reliability, And Cost Tests

Before broad adoption, measure:

- dashboard load when a site has hundreds of violations and assignments
- action inbox query/read cost and render behavior
- audit checklist performance for larger templates
- thumbnail/full-image load and upload responsiveness on mobile networks
- server-side image compression output size and processing duration
- Cloud Function retry/idempotency behavior

Add budget and anomaly monitoring for:

- Firestore read/write growth
- Storage growth and transfer
- Functions invocation/error rates
- Cloud SQL and ingestion job spend

## Observability And Production Feedback

Automated testing cannot reproduce every device and network condition.

Recommended operational visibility:

- Firebase Crashlytics for Android and iOS Flutter runtime crashes and handled
  high-value failures
- Cloud Functions structured logs for workflow failures, including function
  name, tenant/site identifiers where safe, target record type/id, and error
  code
- Cloud Monitoring alerting for Functions failures and backend API errors
- a simple release annotation process so incidents are tied to app/function
  versions

Chrome development console logs are useful while building, but they are not a
production monitoring strategy.

## Continuous Integration Gates

### On Every Pull Request

Required:

- Python lint and unit tests
- Firebase Functions syntax/lint and unit tests
- Flutter format check
- Flutter analyzer
- Flutter unit/widget tests
- Firestore and Storage Rules emulator tests when related files or data-access
  code changes

### For Workflow Or Security Changes

Required in addition:

- callable Function emulator tests
- rule tests for affected roles
- at least one end-to-end integration test covering the changed workflow

### Before Production Release

Required:

- all automated checks green
- manual mobile smoke test of changed high-risk flow in the dev environment
- deploy to a controlled staging/dev Firebase project
- post-deploy smoke test
- explicit release approval

## Release Smoke Checklist

Each production release should verify only the most important journeys, using a
designated test tenant/site:

1. Sign in and access allowed site.
2. Open dashboard and action inbox.
3. Save and submit a test violation fix; review and close or send it back.
4. Run a short internal audit when audit code changed.
5. Assign and complete training when training code changed.
6. Upload and open a photo when media/storage code changed.
7. Confirm no new high-severity Functions or Crashlytics failures.

Avoid destructive or confusing test records in real customer sites.

## Rollout Roadmap

### Phase 1: Foundation Before Broader MVP Testing

- add this strategy as the release-quality source of truth
- add Functions test runner and initial callable workflow tests
- add Firestore and Storage Rules emulator tests
- add Flutter widget tests around dashboard/actions, violations, audits, and
  training
- add CI running analyze, unit/widget, backend, and rules tests

### Phase 2: Before First Paid Customer Release

- add five critical Flutter integration journeys
- add Android device smoke execution for media and audit workflows
- add Crashlytics for native mobile releases
- add post-deploy smoke-test procedure and release result capture

### Phase 3: As Usage Grows

- add golden/screenshot regression coverage for core mobile screens
- add performance/cost budgets and trend monitoring
- add scheduled-action and push-delivery tests when push is implemented
- add iOS integration execution as native distribution becomes active

## Recommended Next Implementation Work

The next engineering step should be a small but complete test foundation:

1. Configure Firebase emulators for Auth, Firestore, Functions, and Storage.
2. Add Firestore/Storage rules tests for tenant and site isolation.
3. Add callable Function tests for violation submit/review action creation and
   training assignment/completion action creation.
4. Add CI to run these checks together with `flutter analyze`, Flutter tests,
   and Python tests.

This directly protects the newly introduced Actions and Notifications
architecture, where a missing action item could cause restaurant staff or a
manager to miss required work.

## Reference Documentation

- Flutter testing and integration tests:
  <https://docs.flutter.dev/testing/integration-tests>
- Firebase Firestore Security Rules testing:
  <https://firebase.google.com/docs/firestore/security/test-rules-emulator>
- Firebase Cloud Functions local emulator:
  <https://firebase.google.com/docs/functions/local-emulator>
- Firebase Crashlytics for Flutter:
  <https://firebase.google.com/docs/crashlytics/flutter/get-started>

