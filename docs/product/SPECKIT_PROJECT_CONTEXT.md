# FiScore SpecKit Project Context

This document is the baseline context for future SpecKit specs. It describes what exists today, where the work lives, and how new specs should identify their scope.

## Repo Areas

| Area | Path | Current Role |
| --- | --- | --- |
| FiScore App | `apps/fiscore_app` | Flutter app for restaurant staff, managers, tenant owners, and admins. Uses Firebase Auth, Firestore, Storage, Cloud Functions, localized UI strings, and mobile-first workflows. |
| App Cloud Functions | `apps/fiscore_app/functions` | Firebase Cloud Functions for tenant/team/site/library/action/training/audit/violation business actions and attachment processing. |
| FiScore Admin Console | `apps/tenant_admin_web` | React/Vite/Firebase web app for tenant administration and support-style workflows. |
| FiScore Ingestion | `src/fiscore_backend` | Python/FastAPI backend, ingestion worker, source adapters, GCP storage integration, and Postgres master data. |
| Product Docs | `docs/product` | Product workflows, roles, pricing, billing, notifications, checklists, training, onboarding, and execution flows. |
| App Docs | `docs/app` | Firestore-facing app schema and app navigation references. |
| Backend Docs | `docs/backend`, `docs/ingestion`, `docs/source-integrations` | Master data architecture, schema, ingestion operations, and source-specific integration plans. |

## Current Architecture Snapshot

### FiScore App

- Flutter app with Android, iOS, and web targets.
- Firebase Auth supports Google sign-in and email link sign-in; Apple sign-in is planned before iOS release.
- Firestore stores tenant, member, site, violation, audit/check, training, action item, invite, library, and attachment metadata.
- Firebase Storage stores tenant/site violation attachments, inspection report copies, and FiScore library media.
- Cloud Functions own important business transitions such as tenant/team/site operations, violation lifecycle, action items, training assignments, internal check assignments, library imports, and attachment processing.
- Dashboard and action inbox rely on focused action item queries plus bounded supporting queries.
- Training and checklist execution use snapshots so completed work reflects the content that existed when the user started or was assigned the work.
- User-visible app labels are moving through Flutter localization; authored training/checklist content remains in the language it was authored in.

### FiScore Admin Console

- React and Vite application using Firebase client libraries.
- Intended for tenant owner/admin and support workflows that do not belong in staff daily operations.
- Should reuse Cloud Functions and shared Firestore contracts instead of implementing parallel business rules.
- Admin console specs must explicitly state whether an action is tenant self-service, internal support-only, or both.

### FiScore Ingestion

- Python package `fiscore-backend` with FastAPI routes, ingestion worker, source adapters, and Postgres access.
- Public inspection records are ingested into master data and stored with source artifacts.
- Tenant sites can link to master restaurant data; relevant inspections/findings are copied or synchronized into tenant-owned Firestore records for app workflows.
- Ingestion source data, investigation URLs, and raw artifacts are not tenant-owned user work unless copied into tenant scope by a defined sync path.

## Data Ownership Rules

- Tenant operational work belongs under tenant/site scope.
- Public inspection master data belongs to the ingestion/master data platform.
- Tenant-linked inspections and violations used by restaurant staff should be represented in tenant Firestore paths.
- Attachments uploaded by users belong to tenant/site context.
- Library items can be FiScore-owned or tenant-owned. Assigned training and started checks should snapshot the content needed for historical accuracy.
- Billing entitlements should be provider-neutral snapshots on tenant records, with provider-specific details behind backend integration boundaries.

## Roles And Permissions

Current app role vocabulary includes:

- `tenant_owner`
- `admin`
- `manager`
- `auditor`
- `staff`

Specs must define which roles can initiate, view, edit, approve, cancel, delete, assign, or close the affected entity. Backend functions must enforce role permissions for state-changing operations.

## Spec Scope Declaration

Every future SpecKit feature spec should include an "Affected Areas" section with one or more of:

- FiScore App
- FiScore Admin Console
- FiScore Ingestion
- Firebase Cloud Functions
- Firestore rules/schema/indexes
- Firebase Storage/rules
- GCP/Postgres backend
- Documentation only

Use this short template:

```text
Affected Areas:
- FiScore App: ...
- Firebase Cloud Functions: ...
- Firestore: ...
- FiScore Admin Console: not in V1
- FiScore Ingestion: not affected
```

## Spec Usage Guidance

Use SpecKit for:

- notifications and email
- billing and entitlements
- mobile release readiness
- roles and permissions
- backend state transitions
- shared data model changes
- action inbox/dashboard behavior
- library/versioning behavior
- admin console workflows
- ingestion sync contracts

Use normal GitHub issues for:

- small UI polish
- copy edits
- narrow bug fixes
- one-screen layout changes with no backend/data impact

## Canonical References

Before writing a spec, review the most relevant existing docs:

- Product scope: `docs/product/FEATURES.md`
- Workflows: `docs/product/WORKFLOWS.md`
- Roles: `docs/product/USER_ROLES.md`
- Firestore schema: `docs/app/FIRESTORE_SCHEMA.md`
- Notifications: `docs/product/NOTIFICATION_FLOW.md`
- Billing: `docs/product/BILLING_AND_SUBSCRIPTION_FLOW.md`
- Training: `docs/product/TRAINING_EXECUTION_FLOW.md`
- Audit execution: `docs/product/AUDIT_EXECUTION_FLOW.md`
- Violation execution: `docs/product/VIOLATION_EXECUTION_FLOW.md`
- Master data: `docs/backend/MASTER_DATA_ARCHITECTURE.md`
- Ingestion: `docs/ingestion/INGESTION_WORKFLOWS.md`
