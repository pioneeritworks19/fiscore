# FiScore Admin App

## Purpose

This document defines the role, scope, architecture boundary, and version 1 product shape for the FiScore Admin App.

The FiScore Admin App should be treated as a distinct internal product surface from the Ops Console.

Its main responsibility is managing FiScore-owned product content and tenant-facing configuration that belongs to the application domain, especially:

- checklist library content
- training library content
- publishing and version governance
- tenant content support workflows
- future product configuration and internal support tooling

The Admin App should not be the place where ingestion runs, scrape errors, source health, or master data operations are managed. Those remain part of the Ops Console.

## High-Level Product Boundary

FiScore should be treated as four product surfaces:

1. Tenant Mobile App
2. Tenant Web App
3. FiScore Admin App
4. Ops Console

These should remain separate logically even if some shared code, shared auth infrastructure, or shared deployment conventions are used internally.

## Relationship to Ops Console

The FiScore Admin App and Ops Console should remain separate products because they serve different jobs.

### FiScore Admin App

Primary job:

- manage FiScore Library content
- manage product-level tenant content governance
- support tenant-facing product administration
- publish and version centrally-managed content

Primary data domain:

- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- selected backend/admin workflows connected to Firebase-backed product data

### Ops Console

Primary job:

- operate ingestion
- monitor source health
- inspect scrape runs
- manage retries and refreshes
- diagnose parser and normalization issues

Primary data domain:

- Cloud Run services
- PostgreSQL ingestion/master data
- raw artifacts
- operational GCP infrastructure

## Architecture Confirmation

Yes: the FiScore Admin App should primarily work against the Firebase-oriented tenant/product stack, while the Ops Console should primarily work against the GCP-oriented ingestion and master-data stack.

That distinction is important and should remain explicit.

However, the Admin App should not be thought of as a pure client-only Firebase surface. Some important internal workflows will still benefit from controlled backend logic, for example:

- publishing a new library version
- applying tenant library updates safely
- recording audit logs for internal changes
- protecting admin-only mutation paths
- running internal support actions with stronger authorization checks

So the practical model should be:

- Admin App is mostly Firebase/product-data oriented
- Ops Console is mostly GCP/ingestion-data oriented
- some Admin App actions may still go through backend or server-side admin endpoints

## Core Goals

The FiScore Admin App should allow the internal team to:

- author and manage FiScore Library checklist content
- author and manage FiScore Library training content
- publish new governed versions of library content
- review where tenant content is linked to library content
- support tenant adoption flows such as synced vs copied content
- manage selected product configuration without touching ingestion systems

## Non-Goals

The FiScore Admin App should not be the primary surface for:

- scrape run monitoring
- source activation/deactivation
- source health review
- raw artifact inspection
- manual restaurant refresh
- stuck ingestion run handling
- parser or normalization debugging

Those remain Ops Console concerns.

## Primary Users

The Admin App is an internal-only application for:

- FiScore product administrators
- FiScore content administrators
- FiScore operations/support staff for tenant-facing product support

It is not a tenant-facing app.

## Authentication and Access Model

The Admin App should use the same internal identity model as the Ops Console wherever practical.

Recommended model:

- Google Sign-In only
- group-based access control for approved Pioneer IT Works internal users
- optional `@pioneeritworks.com` domain check as a guardrail
- Firebase custom claims for Admin App roles and downstream authorization

The primary gate should be internal Google Group membership, not domain-only restriction.

See:

- [FISCORE_ADMIN_AUTH.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\FISCORE_ADMIN_AUTH.md)

## Version 1 Scope

Version 1 of the Admin App should focus on:

1. Checklist Library management
2. Training Library management
3. Content versioning and publishing
4. Tenant library adoption visibility
5. Limited tenant support workflows tied to product content

Version 1 does not need to become a giant internal admin suite. It should start as a focused content and governance app.

## Core Modules

### 1. Admin Dashboard

The Admin dashboard should provide a practical starting view for internal users.

Recommended content:

- unpublished checklist drafts
- unpublished training drafts
- recently published library versions
- tenant content with update available
- recent admin activity

This should be an operational content dashboard, not an ingestion monitoring dashboard.

### 2. Checklist Library

This module should let internal users:

- create library checklist templates
- edit checklist metadata
- define sections and questions
- define scoring behavior and checklist structure
- preview checklist versions
- publish new checklist versions
- archive or retire old library items where appropriate

This should use the same underlying checklist authoring capability as tenant checklist setup, but with library governance rules.

### 3. Training Library

This module should let internal users:

- create library training modules
- edit metadata and content blocks
- define quick checks or knowledge checks
- preview training versions
- publish new training versions
- archive or retire old library items where appropriate

This should use the same underlying training authoring capability as tenant training setup, but with library governance rules.

### 4. Publishing and Version Control

The Admin App should make versioning explicit.

Publishing a checklist or training update should:

- create a new library version
- preserve prior published versions
- mark the new version as the latest library version
- enable tenant-facing update availability for synced tenants
- avoid mutating past tenant execution history directly

This is a governed publish action, not a silent live edit.

### 5. Tenant Library Adoption Visibility

The Admin App should let internal users see:

- which tenants adopted a library item
- whether the tenant adopted it as `Synced from Library`
- whether the tenant adopted it as `Created from Library`
- which tenant versions are behind the newest library version
- whether updates are available but not yet applied

This is especially valuable for support, rollout tracking, and library governance.

### 6. Tenant Content Support

Version 1 tenant support tooling should stay modest.

Useful capabilities:

- view tenant checklist/training items derived from library content
- view sync state
- view current linked library version
- view whether the tenant detached from library

Potential later capabilities:

- internal assist tools for content migration
- internal support actions to re-trigger update metadata
- tenant troubleshooting for library-linked content

## Shared Authoring Model

The Admin App and tenant setup should use the same base authoring model for checklist and training content wherever possible.

That means the underlying editor capabilities should largely be shared for:

- metadata editing
- section and question structure
- scoring configuration
- training content composition
- quick checks
- version preview

The difference should come from governance rules, not from maintaining two completely different editing systems.

### Library Context

On the FiScore Admin side, the editor should behave as a library authoring and publishing tool.

Key traits:

- internal-only ownership
- publish-governed versions
- reusable across tenants
- update propagation metadata

### Tenant Context

On the tenant side, the same editor engine should behave as a tenant-owned content tool.

Key traits:

- tenant-scoped ownership
- `Synced from Library` or `Created from Library` behavior
- tenant overrides and local edits
- detach and update adoption flows

## Suggested Navigation

Recommended version 1 navigation:

- Dashboard
- Checklist Library
- Training Library
- Library Updates
- Tenant Content Support
- Product Configuration
- Admin Activity Log

This should be separate from Ops Console navigation.

## Suggested Internal Roles

Version 1 internal roles can stay simple.

Recommended roles:

- `content_admin`
- `product_admin`
- `support_admin`
- `super_admin`

### content_admin

Can:

- create and edit library drafts
- publish checklist and training updates
- review library adoption status

### product_admin

Can:

- do everything `content_admin` can do
- manage broader product configuration
- manage internal app settings related to content governance

### support_admin

Can:

- view tenant-linked content state
- inspect update availability
- help diagnose tenant library-content questions

### super_admin

Can:

- perform all Admin App actions
- manage internal access and critical configuration

## Data Architecture Expectations

### Primary Systems

The Admin App should primarily operate on the Firebase-oriented product data layer:

- Firebase Authentication for internal admin identity
- Cloud Firestore for library records, tenant-linked content metadata, and admin read models
- Firebase Storage for library assets where needed

### Backend-Assisted Admin Actions

Some mutations should still be server-mediated or use privileged backend logic:

- publish a library version
- generate or update tenant library adoption metadata
- enforce admin-only permissions
- write internal audit logs
- run support-safe mutation workflows

These can be implemented through:

- Cloud Functions
- server-side admin endpoints
- a small admin backend layer if needed

### Data Boundary with Ops Console

The Admin App should not use PostgreSQL ingestion/master-data tables as its primary working store.

If the Admin App needs restaurant or inspection context, it should prefer:

- tenant-facing projections
- support-safe read models
- purpose-built product-facing documents

It should not become a thin wrapper over ingestion tables.

## Relationship to Firestore Schema

The Admin App should align with the product-side model documented in:

- [FIRESTORE_SCHEMA.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\app\FIRESTORE_SCHEMA.md)
- [DATA_MODEL.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\DATA_MODEL.md)
- [LIBRARY_CONTENT_SYNC_FLOW.md](C:\Users\Kannappan\Documents\Projects\FiScore\docs\product\LIBRARY_CONTENT_SYNC_FLOW.md)

Version 1 does not need every Admin App record to live in the same exact collections the tenant apps use. But it should respect the same conceptual model:

- library items are FiScore-owned
- tenant items are tenant-owned
- linked items carry library metadata
- published versions are explicit

## Suggested Version 1 Screens

### Dashboard

- draft content queue
- recently published content
- tenants with update available

### Checklist Library List

- filters by status, type, version, last updated
- draft vs published indicators

### Checklist Editor

- metadata
- sections/questions
- preview
- version history
- publish action

### Training Library List

- filters by status, type, last updated
- draft vs published indicators

### Training Editor

- metadata
- content modules
- quick checks
- preview
- version history
- publish action

### Library Update Visibility

- list of tenant-linked checklist/training records with update available
- linked version vs latest version
- sync mode

### Tenant Content Detail

- library link metadata
- tenant current version
- sync mode
- detach state
- update availability

## Version 1 Operational Rules

The Admin App should follow these rules:

1. library content changes create new versions rather than mutating history
2. synced tenant items should surface update availability rather than auto-changing silently
3. created-from-library tenant items should remain detached from future sync behavior
4. completed audits and training history must remain pinned to the tenant version originally used
5. Admin App actions should be auditable

## Implementation Recommendation

The FiScore Admin App should be built as a separate internal app surface with its own navigation, permissions, and product identity, but it can still share implementation pieces with the Tenant Web App where that is efficient.

Recommended shared pieces:

- checklist editor components
- training editor components
- version history UI patterns
- diff/preview patterns
- common auth/session plumbing where appropriate

Recommended distinct pieces:

- library publishing workflows
- tenant support views
- internal-only admin permissions
- admin activity log

## Final Recommendation

FiScore Admin App should remain separate from the Ops Console.

The Admin App should primarily operate in the Firebase-oriented product domain, while the Ops Console should remain focused on GCP-oriented ingestion and master-data operations.

That is the correct separation for FiScore:

- Admin App for product content and tenant governance
- Ops Console for ingestion and operational data pipeline management
