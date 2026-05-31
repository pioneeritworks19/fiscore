# FiScore Spec Constitution

## Core Principles

### I. Tenant-First SaaS Boundaries

FiScore is a multi-tenant restaurant safety SaaS. Every material feature must state how data is scoped by tenant, site, user role, and environment. Tenant-owned operational work belongs under tenant/site boundaries. Master public-inspection data and ingestion artifacts are shared platform assets and must not be treated as tenant-owned records until deliberately copied or linked through a defined sync path.

### II. Server-Owned Business Transitions

Important state changes must be owned by backend business functions, not by client-only multi-step writes. This includes tenant creation, site creation/linking/deletion, team invitation and access changes, violation assignment/status transitions, internal check assignment/completion/cancelation, training assignment/progress/completion/cancelation, billing entitlement updates, and future notification delivery. Clients may render and request actions, but the backend must validate permissions, update counters/summaries, write audit/activity records, and create action items atomically where practical.

### III. Mobile-First, No-Training Operations

The FiScore App is optimized for restaurant staff who should be able to complete common work without training. Specs affecting the tenant app must prefer clear daily actions, compact mobile layouts, low cognitive load, direct wording, and obvious next steps. Dense admin or investigative workflows belong in the Admin Console unless staff need them during daily restaurant work.

### IV. Three-Surface System Awareness

Every spec must identify affected FiScore surfaces: FiScore App, FiScore Admin Console, FiScore Ingestion, shared Firebase backend, shared GCP/Postgres backend, or documentation-only. Cross-surface changes must define ownership and handoff contracts so the Flutter app, React admin console, Cloud Functions, and ingestion services do not develop incompatible interpretations of the same business concept.

### V. Scalable Reads, Snapshots, and Action Items

Common screens must avoid unbounded collection reads. List and dashboard features should use query-specific reads, pagination or bounded limits, summary counters, and action items where appropriate. Assignments, checks, training, and violation workflows should snapshot user-facing content at execution time when historical accuracy matters, rather than depending on mutable library/template records.

### VI. Product-Safe Notifications

Notifications and email must be helpful, sparse, and explain why the recipient is receiving them. The app should not send email directly. Specs that introduce notifications must define channel, recipient, trigger, dedupe behavior, audit log expectations, and whether in-app action items are sufficient before adding email or push.

### VII. Evolution Without Legacy Drag

FiScore is still pre-pilot. We should preserve important user-created or operational history, but we should not overbuild compatibility for disposable early-development test data. Specs must explicitly distinguish migration requirements for production data from cleanup or reseeding choices that are acceptable in development.

## Architecture Constraints

FiScore currently has three bodies of work in one repository:

- FiScore App: Flutter mobile/web app in `apps/fiscore_app`, backed by Firebase Auth, Firestore, Storage, and Cloud Functions.
- FiScore Admin Console: React/Vite/Firebase app in `apps/tenant_admin_web` for owner/admin/support workflows.
- FiScore Ingestion: Python/FastAPI/GCP/Postgres services in `src/fiscore_backend` for public inspection ingestion and master data.

Specs must use the current architecture snapshot at `docs/product/SPECKIT_PROJECT_CONTEXT.md` as baseline context unless a newer accepted spec supersedes it.

## Development Workflow

Material changes should use GitHub issues, issue-scoped branches, pull requests, and focused validation. Specs are required for cross-cutting features, backend state transitions, data model changes, billing, notifications, permissions, release readiness, and other decisions that affect more than one screen or service. Small UI polish, copy tweaks, and narrow bug fixes may remain normal issues without a SpecKit spec.

Specs must include:

- affected surfaces
- user journeys and non-goals
- role and permission expectations
- data ownership and storage impact
- backend/API/function contracts when applicable
- validation strategy
- rollout or migration notes when applicable

## Governance

This constitution guides future SpecKit specs and implementation plans. If a spec conflicts with this constitution, the spec must explicitly call out the conflict and include a decision to amend the constitution or change the feature approach. Amendments require a pull request and a short rationale.

**Version**: 1.0.0 | **Ratified**: 2026-05-31 | **Last Amended**: 2026-05-31
