# FiScore GCP Deployment Runbook

## Purpose

This runbook defines the practical rollout order for moving the FiScore backend from local development to Google Cloud.

It focuses on:

- `fiscore-worker` on Cloud Run
- scheduled runs through Cloud Scheduler
- `fiscore-api` on Cloud Run
- the ops console hosted by the API service

This is written for the current `dev` environment:

- project: `fiscore-dev`
- region: `us-central1`
- artifact registry repo: `fiscore`
- bucket: `fiscore-dev-raw-artifacts`

## What Codex Can Prepare

Codex can prepare and maintain:

- deployment scripts
- Cloud Build configs
- backend documentation and rollout checklists
- Cloud Run environment variable and secret mappings
- scheduler job payload definitions
- code changes needed for deploy readiness

## What You Need To Do

You need to execute the GCP-facing steps:

- apply database migrations against Cloud SQL
- run `gcloud` deployment commands
- verify Secret Manager values
- create and validate Cloud Scheduler jobs
- test the deployed services
- restrict ops console access

## Deployment Order

Follow these steps in order.

### Step 1: Apply Database Migrations

Run the pending migrations against the `fiscore` database before deploying new services.

Minimum required migrations for the current stack:

- `sql/migrations/001_add_finding_detail_and_comments.sql`
- `sql/migrations/002_add_master_inspection_report.sql`
- `sql/migrations/003_add_finding_detail_json.sql`
- `sql/migrations/004_add_scrape_run_context_columns.sql`
- `sql/migrations/005_add_platform_registry.sql`

You can run them in Cloud SQL Studio or your preferred SQL client.

### Step 2: Confirm Secret Manager Values

These secrets should exist and be correct:

- `DB_HOST`
- `DB_PORT`
- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`
- `RAW_ARTIFACT_BUCKET`

These non-secret runtime values are also required:

- `APP_ENV=dev`
- `GCP_PROJECT_ID=fiscore-dev`
- `GCP_REGION=us-central1`
- `DEFAULT_PARSER_VERSION=sword-v1`
- `RUN_DISPATCH_MODE=worker_http` on the API service
- `CLOUD_SQL_CONNECTION_NAME=fiscore-dev:us-central1:fiscore-dev-pg`
- `CLOUD_SQL_SOCKET_DIR=/cloudsql`

The API service also needs the private worker target:

- `WORKER_BASE_URL=https://your-worker-url`
- `WORKER_AUDIENCE=https://your-worker-url`

### Step 3: Deploy `fiscore-worker`

Deploy the worker first. It is the service that performs ingestion, parsing, and normalization.

Use:

```powershell
.\scripts\deploy_worker.ps1
```

What this does:

1. builds the worker container with Cloud Build
2. pushes the image to Artifact Registry
3. deploys `fiscore-worker` to Cloud Run
4. wires env vars and secrets into the service
5. keeps the worker in local execution mode with `RUN_DISPATCH_MODE=local`

### Step 4: Test One Manual Worker Run

Once the worker is deployed, send one test request directly to the worker.

Use an authenticated HTTP request to:

- `POST /jobs/run`

Request body example:

```json
{
  "source_slug": "sword_mi_wayne",
  "run_mode": "incremental",
  "trigger_type": "api"
}
```

Success criteria:

- response accepted
- `ops.scrape_run` row created
- artifacts written
- parse results written
- normalization written

### Step 5: Create One Scheduler Job

Create one real scheduled run first before adding the rest.

Recommended first job:

- `sword_mi_wayne`
- `incremental`

Use:

```powershell
.\scripts\create_scheduler_jobs.ps1 -WorkerUrl "https://your-worker-url"
```

This script creates one scheduler job per source slug that you specify.

### Step 6: Verify Scheduled Run

Confirm that the scheduler-triggered run:

- reaches the worker
- appears in `ops.scrape_run`
- shows `trigger_type = scheduler`
- writes artifacts and parse results

Also check Cloud Run logs for the worker service.

### Step 7: Deploy `fiscore-api`

After the worker path is proven, deploy the API service.

Use:

```powershell
.\scripts\deploy_api.ps1 -WorkerUrl "https://your-worker-url"
```

What this does:

1. builds the API container with Cloud Build
2. pushes the image to Artifact Registry
3. deploys `fiscore-api` to Cloud Run
4. wires env vars and secrets into the service
5. configures the API to dispatch manual runs to the private worker with Google ID tokens

### Step 8: Test the Ops Console on GCP

Open the deployed API URL and verify:

- `/ready`
- `/ops/control-panel`
- `/ops/control-panel/platforms`
- `/ops/control-panel/sources`
- `/ops/control-panel/runs`

Success criteria:

- pages load
- platform grouping appears
- pagination and search work
- recent source/run data appears

### Step 9: Restrict Access to the Ops Console

Do not leave the ops console broadly public.

Recommended internal-only setup:

- require authenticated access on Cloud Run for `fiscore-api`
- create a Google Group such as `fiscore-ops@pioneeritworks.com`
- grant `roles/run.invoker` on `fiscore-api` only to that group
- do not grant browser users access to `fiscore-worker`
- grant `roles/run.invoker` on `fiscore-worker` only to trusted service accounts

Recommended service account split:

- `fiscore-runtime@...` for the API runtime
- `fiscore-scheduler@...` for scheduler jobs

Required worker access grants:

- `serviceAccount:fiscore-runtime@...` -> `roles/run.invoker` on `fiscore-worker`
- `serviceAccount:fiscore-scheduler@...` -> `roles/run.invoker` on `fiscore-worker`

Required API access grant:

- `group:fiscore-ops@pioneeritworks.com` -> `roles/run.invoker` on `fiscore-api`

This keeps the console and ingestion entirely inside company-managed Google identity.

### Step 10: Add Remaining Scheduler Jobs

Once the first job is healthy, add the remaining jobs one source at a time.

Recommended pattern:

- one scheduler job per source slug
- one clear cadence per job
- start with `incremental`
- add `reconciliation` jobs later where useful

## Runtime Contracts

### Worker Endpoint

- `POST /jobs/run`

Request body:

```json
{
  "source_slug": "sword_mi_wayne",
  "run_mode": "incremental",
  "trigger_type": "scheduler"
}
```

Allowed `run_mode` values:

- `incremental`
- `reconciliation`
- `backfill`

Allowed `trigger_type` values:

- `manual`
- `scheduler`
- `api`

### API Console

The current control panel is served from the API service itself:

- `/ops/control-panel`

## Service Settings

### `fiscore-worker`

Recommended starting settings:

- CPU: `1`
- Memory: `1Gi`
- Timeout: `900s`
- Min instances: `0`
- Authentication: required
- Service account: `fiscore-runtime`
- Invocation allowed only for trusted service accounts

### `fiscore-api`

Recommended starting settings:

- CPU: `1`
- Memory: `512Mi`
- Timeout: default or modestly increased
- Min instances: `0`
- Authentication: required
- Service account: `fiscore-runtime`
- Invocation allowed only for the internal Google Group

## Current Architecture Note

Today, the ops console manual run action still dispatches work through the API process in local development.

For GCP operations, the current deployment flow is:

- browser users access only `fiscore-api`
- manual runs from the ops console hit the API service
- the API service calls the private worker service with an ID token
- scheduled runs target the worker service directly with OIDC

The worker is the execution service and should not be directly exposed to browser users.

## Cloud SQL Access From Cloud Run

Cloud Run should connect to Cloud SQL through the attached Cloud SQL instance path, not by relying on raw public-IP access from the container.

This runbook and the deploy scripts now assume:

- the Cloud SQL instance is attached to the Cloud Run service
- `CLOUD_SQL_CONNECTION_NAME` is set
- `CLOUD_SQL_SOCKET_DIR=/cloudsql`

Local development can still continue using:

- `DB_HOST`
- `DB_PORT`

## Recommended Immediate Execution Sequence

Use this exact sequence:

1. apply SQL migrations
2. confirm Secret Manager values
3. deploy `fiscore-worker`
4. test one worker run
5. create one scheduler job
6. verify one scheduled run
7. deploy `fiscore-api`
8. test the ops console on GCP
9. restrict API and worker access with IAM
10. add remaining scheduler jobs

## Files That Support This Runbook

- `scripts/deploy_worker.ps1`
- `scripts/deploy_api.ps1`
- `scripts/create_scheduler_jobs.ps1`
- `deploy/cloudbuild.worker.yaml`
- `deploy/cloudbuild.api.yaml`
