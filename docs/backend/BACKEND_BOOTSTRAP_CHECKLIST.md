# FiScore Backend Bootstrap Checklist

## Purpose

This document defines the practical first steps for bootstrapping the FiScore backend on Google Cloud.

It is written from the ingestion/platform perspective, not from a single source-specific perspective. The goal is to set up the minimum backend foundation needed to support:

- `ops` schema
- `ingestion` schema
- `master` schema
- raw source artifact storage
- backend service deployment
- recurring ingestion jobs

This checklist focuses on the minimum healthy starting point rather than the final fully scaled platform.

## Bootstrap Principles

### 1. Start Small but Structurally Correct

Do not overbuild the backend at the beginning. Use the minimum services that still align with the long-term platform architecture.

### 2. Build for the Platform, Not Just the First Source

The initial setup should support:

- multiple sources
- shared operational tracking
- shared ingestion storage
- canonical master data

It should not be shaped only around Sword Solutions or any one source.

### 3. Separate Provisioning from Product Code

Google Cloud resources should be bootstrapped first, then connected to the backend codebase and database schema.

## Recommended Minimum Google Cloud Services

The minimum healthy backend foundation is:

- `Cloud Run`
- `Cloud SQL for PostgreSQL`
- `Cloud Storage`
- `Cloud Scheduler`
- `Secret Manager`

## What This Checklist Covers

- what to create manually in Google Cloud first
- what the Codex/backend workstream can prepare locally
- the recommended order of execution

## Phase 1: Google Cloud Project Setup

These steps are usually done manually through Google Cloud Console or `gcloud`.

### 1. Create a Google Cloud Project

Create a dedicated project for FiScore backend work.

Recommended direction:

- use a separate project for backend/platform resources
- keep naming clean and environment-oriented

Example naming direction:

- `fiscore-dev`
- `fiscore-staging`
- `fiscore-prod`

### 2. Enable Billing

Enable billing for the project.

### 3. Enable Required APIs

Enable at least:

- Cloud Run API
- Cloud SQL Admin API
- Cloud Storage API
- Cloud Scheduler API
- Secret Manager API
- IAM API if needed through setup flows

## Phase 2: Core Infrastructure Bootstrap

## 4. Create Cloud SQL PostgreSQL Instance

Create one PostgreSQL instance for the backend platform.

This should host:

- `ops` schema
- `ingestion` schema
- `master` schema

### Recommended Notes

- start with one instance
- keep it simple early on
- use one database instance for all backend schemas in the first environment

### Minimum follow-up actions

- create the initial database
- create an application user
- store credentials securely

## 5. Create Cloud Storage Bucket

Create a Cloud Storage bucket for raw source artifacts.

Use this for:

- raw HTML
- source PDFs when available
- future extracted text artifacts if needed

### Recommended naming direction

- `fiscore-dev-raw-artifacts`

### Recommended path prefixes

- `raw/html/`
- `raw/pdf/`
- `raw/clause/`

You can keep one bucket with path prefixes in version 1.

## 6. Create Secret Manager Entries

Create secrets for:

- PostgreSQL connection string or DB password
- app config values that should not be hardcoded

Recommended minimum secrets:

- `DB_HOST`
- `DB_PORT`
- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`

You may later collapse these into a single connection secret if preferred.

## 7. Create Cloud Run Services

Create the minimum Cloud Run service layout.

### Service A: Backend API

Purpose:

- health checks
- internal APIs
- admin/backend endpoints
- future ops console API support

### Service B: Ingestion Worker

Purpose:

- run ingestion jobs
- fetch source pages
- parse content
- normalize records
- publish tenant projections

### Recommendation

Keep these as two services even if the codebase starts in one repository.

This creates cleaner operational separation early on.

## 8. Create Cloud Scheduler Jobs

Create scheduler jobs for backend task triggering.

At minimum, prepare for:

- weekly ingestion jobs
- manual testing hooks

### Initial recommendation

You do not need to wire every source immediately.

Start with:

- one scheduler job pattern that can trigger a source run
- source-specific scheduling data can be driven from `ops.source_registry`

## Phase 3: Database Bootstrap

These tasks can be prepared by Codex and then executed against Cloud SQL.

## 9. Initialize Postgres Schemas

Create the initial schemas:

- `ops`
- `ingestion`
- `master`

### Recommendation

This should be done from version-controlled SQL or migrations, not by ad hoc manual editing.

## 10. Create Initial Core Tables

At minimum, bootstrap the first operational and master tables needed for the backend.

Recommended initial table groups:

### `ops`

- `source_registry`
- `scrape_run`
- `source_health`
- `operational_alert`
- `rerun_request`

### `ingestion`

- `raw_artifact_index`
- `parse_result`
- `parser_warning`

### `master`

- `master_restaurant`
- `master_restaurant_identifier`
- `master_restaurant_source_link`
- `master_inspection`
- `master_inspection_finding`
- `source_clause_reference`
- `source_version`

## Phase 4: Backend Code Bootstrap

These tasks are ideal for Codex to help generate and scaffold.

## 11. Create Backend Repository Structure

Recommended major areas:

- API service
- ingestion worker
- schema/migrations
- source adapters
- shared models/config

## 12. Add Environment and Config Management

Prepare:

- environment variable loading
- secret injection strategy
- local dev config
- Cloud Run runtime config

## 13. Add Database Connection Layer

Prepare:

- Postgres connection setup
- schema initialization path
- migration strategy

## 14. Add Cloud Storage Integration

Prepare:

- bucket config
- raw artifact write path
- metadata persistence strategy

## Phase 5: Operational Bootstrap

## 15. Seed Source Registry

Before the first pipeline runs, seed `ops.source_registry` with initial source records.

For the Sword example, this would mean:

- one source per county
- all under the Sword platform family

Example direction:

- `sword_mi_wayne`
- `sword_mi_washtenaw`
- `sword_mi_oakland`

## 16. Add Health Check Endpoints

Add simple health endpoints to:

- backend API
- ingestion worker

This helps with Cloud Run monitoring and sanity checks.

## 17. Add Minimal Run Logging

Before the first real ingestion, ensure the worker can:

- create a `scrape_run`
- write logs
- mark success/failure
- record warnings

## Phase 6: First Source Readiness

## 18. Connect the First Source Adapter

At this point, the backend should be ready for the first real source-specific adapter, such as Sword Solutions.

That work should then happen in the source-specific workstream and use:

- `ops` for source tracking
- `ingestion` for raw and parsed results
- `master` for normalized records

## What Should Be Done Manually vs With Codex

## Usually Manual or Cloud-Account Driven

These typically require Google Cloud access and should be done manually or through authenticated CLI/IaC execution:

- create GCP project
- enable billing
- enable APIs
- create Cloud SQL instance
- create Cloud Storage bucket
- create Secret Manager secrets
- create Cloud Run services
- create Cloud Scheduler jobs

## Well Suited for Codex

These are excellent Codex tasks:

- write SQL schema initialization files
- write migration files
- scaffold backend repo
- scaffold FastAPI app
- scaffold ingestion worker structure
- write Dockerfiles
- write deployment scripts
- write configuration templates
- write source registry seed scripts
- write backend README/runbooks

## Recommended Order of Execution

The practical order should be:

1. create GCP project
2. enable billing and APIs
3. create Cloud SQL
4. create Cloud Storage bucket
5. create secrets
6. create Cloud Run services
7. create Cloud Scheduler baseline
8. initialize `ops`, `ingestion`, and `master` schemas
9. scaffold backend codebase
10. seed first sources
11. integrate first source adapter

## Suggested Bootstrap Output

At the end of backend bootstrap, you should have:

- one Google Cloud project
- one Postgres instance
- one raw artifact bucket
- two Cloud Run services
- one scheduler baseline
- initialized backend schemas
- backend code scaffold ready for source adapters

## Good Stopping Point for Bootstrap

Bootstrap is complete when:

- Cloud SQL is reachable from the backend
- schemas exist
- Cloud Storage is writable
- backend API runs
- ingestion worker runs
- one source can be registered in `ops.source_registry`

At that point, you are ready to begin real source implementation.

## Recommended Next Artifacts

After this checklist, the most practical next documents would be:

- `GCP_MINIMUM_BACKEND.md`
- `OPS_SCHEMA.md`
- `POSTGRES_SCHEMA_STRATEGY.md`
- backend code scaffold plan

## Summary

The FiScore backend should be bootstrapped from the ingestion/platform perspective using a minimal Google Cloud foundation: Cloud Run, Cloud SQL, Cloud Storage, Cloud Scheduler, and Secret Manager. The first backend environment should support three Postgres schemas: `ops`, `ingestion`, and `master`, so the platform is ready for source onboarding, operational tracking, and canonical public-data storage from the beginning.

