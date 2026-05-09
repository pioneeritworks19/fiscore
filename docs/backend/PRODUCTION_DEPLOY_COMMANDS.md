# Production Deploy Commands

Use this file for quick copy-paste production deploys.

For the full rollout and validation checklist, also see:

- `docs/backend/PRODUCTION_ROLLOUT_CHECKLIST.md`
- `docs/backend/GCP_DEPLOYMENT_RUNBOOK.md`

## Important Notes

- Deploy from a clean working tree that has already been committed and pushed.
- For API-only UI or console changes, deploy only the API.
- For ingestion/fetcher/parser/worker changes, deploy the worker first.
- If both services changed, deploy the worker first and the API second.

## Production Worker Deploy

powershell -ExecutionPolicy Bypass -File .\scripts\deploy_worker.ps1 `
  -ProjectId "fiscore-prod" `
  -Region "us-central1" `
  -Repository "fiscore" `
  -ServiceName "fiscore-worker" `
  -ImageName "fiscore-worker" `
  -CloudSqlConnectionName "fiscore-prod:us-central1:fiscore-prod-pg" `
  -RuntimeServiceAccount "fiscore-runtime@fiscore-prod.iam.gserviceaccount.com" `
  -Environment "prod"


```cmd
powershell -ExecutionPolicy Bypass -File .\scripts\deploy_worker.ps1 ^
  -ProjectId "fiscore-prod" ^
  -Region "us-central1" ^
  -Repository "fiscore" ^
  -ServiceName "fiscore-worker" ^
  -ImageName "fiscore-worker" ^
  -CloudSqlConnectionName "fiscore-prod:us-central1:fiscore-prod-pg" ^
  -RuntimeServiceAccount "fiscore-runtime@fiscore-prod.iam.gserviceaccount.com" ^
  -Environment "prod"
```

## Production API Deploy

powershell -ExecutionPolicy Bypass -File .\scripts\deploy_api.ps1 `
  -ProjectId "fiscore-prod" `
  -Region "us-central1" `
  -Repository "fiscore" `
  -ServiceName "fiscore-api" `
  -ImageName "fiscore-api" `
  -CloudSqlConnectionName "fiscore-prod:us-central1:fiscore-prod-pg" `
  -RuntimeServiceAccount "fiscore-runtime@fiscore-prod.iam.gserviceaccount.com" `
  -Environment "prod" `
  -WorkerUrl "https://fiscore-worker-486523213378.us-central1.run.app"


```cmd
powershell -ExecutionPolicy Bypass -File .\scripts\deploy_api.ps1 ^
  -ProjectId "fiscore-prod" ^
  -Region "us-central1" ^
  -Repository "fiscore" ^
  -ServiceName "fiscore-api" ^
  -ImageName "fiscore-api" ^
  -CloudSqlConnectionName "fiscore-prod:us-central1:fiscore-prod-pg" ^
  -RuntimeServiceAccount "fiscore-runtime@fiscore-prod.iam.gserviceaccount.com" ^
  -Environment "prod" ^
  -WorkerUrl "https://fiscore-worker-486523213378.us-central1.run.app"
```

## Typical Release Order

### API-only changes

1. Confirm `git status` is clean.
2. Deploy the API.
3. Smoke test the Ops/Admin console.

### Worker-only changes

1. Confirm `git status` is clean.
2. Deploy the worker.
3. Run one controlled ingestion smoke test.

### API + worker changes

1. Confirm `git status` is clean.
2. Deploy the worker.
3. Deploy the API.
4. Smoke test both console and ingestion flow.
