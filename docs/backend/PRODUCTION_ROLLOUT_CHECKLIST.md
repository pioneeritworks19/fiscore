# FiScore Production Rollout Checklist

## Purpose

This checklist defines how to promote FiScore from `dev` into a production environment for the first time, and how to repeat that promotion safely for future releases.

It is written for the current FiScore architecture:

- `fiscore-api` is the internal browser-facing console
- `fiscore-worker` is the private execution service for ingestion
- Cloud Scheduler triggers recurring ingestion runs
- production access remains internal-only through Google identity

Use this document together with:

- `docs/backend/GCP_DEPLOYMENT_RUNBOOK.md`

## Production Principles

Follow these principles for the first production rollout:

- keep `dev` and `prod` fully separate
- deploy into a dedicated production GCP project
- protect production before running any real ingestion
- validate with one source before enabling broader rollout
- backfill gradually in waves
- treat release approval and production rollout as manual checkpoints

## Scope Split

### Manual First-Time Tasks

These tasks should be handled manually the first time:

- creating the production GCP project and infrastructure
- setting production secrets
- applying database migrations
- enabling IAP and IAM access controls
- first deploy of API and worker
- first scheduler job
- first production smoke test
- first backfill wave
- release go/no-go decisions

### Automated or Script-Assisted Tasks

These tasks can be script-assisted now and should become more automated over time:

- deploying `fiscore-worker`
- deploying `fiscore-api`
- configuring API-to-worker runtime env vars
- creating or updating scheduler jobs
- repeating the deployment sequence for later releases

## Phase 1: Production Environment Setup

### 1. Create the production GCP project

Manual:

- create the production project, for example `fiscore-prod`
- confirm billing is attached
- confirm you have the right admin permissions

### 2. Enable required GCP APIs

Manual:

- Cloud Run
- Cloud Build
- Artifact Registry
- Cloud Scheduler
- Secret Manager
- Cloud SQL Admin
- Identity-Aware Proxy (IAP)

### 3. Create production infrastructure

Manual:

- create Artifact Registry repository
- create Cloud SQL Postgres instance
- create raw artifact bucket
- create service accounts:
  - `fiscore-runtime@fiscore-prod.iam.gserviceaccount.com`
  - `fiscore-scheduler@fiscore-prod.iam.gserviceaccount.com`

### 4. Create production secrets

Manual:

- create Secret Manager secrets for:
  - `DB_HOST`
  - `DB_PORT`
  - `DB_NAME`
  - `DB_USER`
  - `DB_PASSWORD`
  - `RAW_ARTIFACT_BUCKET`

Verify:

- all secrets point to production resources only
- no `dev` bucket, DB, or host values appear in production secrets

## Phase 2: Database Preparation

### 5. Apply production schema

Manual:

- run all required SQL migrations against the production database

Verify:

- required ops tables exist
- required master data tables exist
- required report/finding fields exist
- migration history is complete

### 6. Confirm source/platform readiness

Manual:

- verify Georgia and Sword source definitions are present in production
- verify platform/source registry data is available if any DB-backed setup is required

## Phase 3: First Production Deployment

### 7. Choose the release commit

Manual:

- choose a specific Git commit that has already been validated in `dev`
- record the commit SHA used for production

Do not:

- deploy directly from an untracked local state
- treat production as “whatever is currently on the laptop”

### 8. Deploy `fiscore-worker` first

Script-assisted:

- deploy the worker to the production project
- configure:
  - production Cloud SQL connection
  - production secrets
  - production runtime service account
  - `RUN_DISPATCH_MODE=local`

Verify:

- deployment succeeds
- service revision becomes healthy
- worker logs show clean startup

### 9. Deploy `fiscore-api` second

Script-assisted:

- deploy the API to the production project
- configure:
  - production Cloud SQL connection
  - production secrets
  - production runtime service account
  - `RUN_DISPATCH_MODE=worker_http`
  - `WORKER_BASE_URL`
  - `WORKER_AUDIENCE`

Verify:

- deployment succeeds
- API is targeting the production worker URL
- service revision becomes healthy

## Phase 4: Production Security

### 10. Configure internal user access

Manual:

- create or reuse Google Group:
  - `fiscore-ops@pioneeritworks.com`
- add only approved production users

### 11. Protect `fiscore-api`

Manual:

- enable IAP on `fiscore-api`
- grant IAP access to `fiscore-ops@pioneeritworks.com`
- grant Cloud Run Invoker on `fiscore-api` to the IAP service agent

Verify:

- approved users can open the console
- unapproved users cannot access it

### 12. Protect `fiscore-worker`

Manual:

- keep `fiscore-worker` on IAM only
- do not enable IAP on the worker
- grant Cloud Run Invoker only to:
  - `fiscore-runtime@fiscore-prod...`
  - `fiscore-scheduler@fiscore-prod...`

Verify:

- browser access to worker is denied
- service-to-service invocation is allowed

## Phase 5: First Production Validation

### 13. Run one manual incremental test

Manual:

- open the production ops console
- trigger one manual incremental run for one small, known source

Recommended first source:

- `sword_mi_wayne`

Verify:

- run appears in production ops console
- `trigger_type = manual`
- artifacts land in production bucket
- rows land in production database
- worker logs show success

### 14. Create one production scheduler job

Script-assisted, manually approved:

- create one scheduler job only
- start with:
  - `sword_mi_wayne`
  - `incremental`

Verify:

- job is created in the production project
- OIDC service account is `fiscore-scheduler`
- target is the production worker

### 15. Force-run the scheduler job

Manual:

- use `Force run` in Cloud Scheduler

Verify:

- job succeeds
- worker receives the request
- run appears in ops console
- `trigger_type = scheduler`

## Phase 6: Initial Backfill Rollout

### 16. Start a very small backfill wave

Manual:

- choose one limited batch of sources
- do not backfill everything at once

Examples:

- one Sword jurisdiction
- a small Georgia subset

Verify:

- runtime is acceptable
- DB growth is acceptable
- artifact storage is acceptable
- parsing quality is acceptable

### 17. Review quality before expanding

Manual:

- inspect `Master Data` explorer
- inspect `Admin > Restaurants`
- inspect restaurant details and inspections

Look specifically for:

- duplicate restaurants
- missing reports
- weak source linkage
- suspicious parsing
- unexpected finding detail issues

### 18. Expand backfill in waves

Manual:

- add more sources in controlled batches
- monitor each wave before moving on

Recommended progression:

1. one source
2. a few sources
3. one platform slice
4. broader rollout

## Phase 7: Recurring Production Scheduling

### 19. Define production cadence

Manual:

- decide actual recurring cadence per source family

Recommended initial approach:

- Sword: weekly incremental
- Georgia: weekly incremental
- reconciliation jobs later if needed

Start simple:

- weekly incrementals are enough for the first production phase

### 20. Add remaining scheduler jobs gradually

Script-assisted, manually approved:

- add jobs source-by-source
- validate each set before broadening

Do not:

- create every production job at once without observation

## Ongoing Dev-to-Prod Promotion

### 21. Standard release flow

Use this flow for each future production release:

1. finish feature work in `dev`
2. validate behavior in `dev`
3. commit and push code
4. choose the release commit
5. apply required migrations to `prod`
6. deploy `fiscore-worker`
7. deploy `fiscore-api`
8. verify IAP and IAM remain correct
9. run one manual smoke test
10. run one scheduler smoke test if relevant
11. monitor logs and ops data

### 22. What remains manual in ongoing releases

Keep these manual:

- release approval
- migration approval
- first production smoke test
- scheduler rollout decisions
- backfill expansion decisions
- rollback decision

### 23. What should become more automated

Over time, automate:

- environment-specific deploy commands
- release checklist execution
- scheduler synchronization
- post-deploy health validation
- infrastructure provisioning through Terraform or equivalent

## Rollback Expectations

### 24. Prepare rollback before broad rollout

Manual:

- know the last good API revision
- know the last good worker revision
- know how to pause scheduler jobs

Important:

- Cloud Run revision rollback is straightforward
- database rollback is not
- be cautious with schema changes and large backfills

## First Production Launch Sequence

Use this exact sequence for the first launch:

1. create `fiscore-prod`
2. provision prod DB, bucket, secrets, service accounts
3. apply migrations to prod
4. deploy worker
5. deploy API
6. configure IAP and IAM
7. run one manual incremental test
8. create one scheduler job and force-run it
9. backfill a very small batch
10. inspect quality in ops and admin
11. expand backfill gradually
12. enable broader weekly schedules

## Future Improvement Ideas

After the first successful production rollout, consider:

- production-specific deploy wrappers
- explicit prod runbooks for weekly scheduler rollout
- a release checklist template
- infrastructure as code for GCP resources
- automated smoke tests after deployment
