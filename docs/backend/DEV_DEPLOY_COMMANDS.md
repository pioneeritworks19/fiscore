# DevDeploy Commands


## Dev Worker Deploy

```cmd
powershell -ExecutionPolicy Bypass -File .\scripts\deploy_worker.ps1 ^
  -ProjectId "fiscore-dev" ^
  -Region "us-central1" ^
  -Repository "fiscore" ^
  -ServiceName "fiscore-worker" ^
  -ImageName "fiscore-worker" ^
  -CloudSqlConnectionName "fiscore-dev:us-central1:fiscore-dev-pg" ^
  -RuntimeServiceAccount "fiscore-runtime@fiscore-dev.iam.gserviceaccount.com" ^
  -Environment "dev"
```

## DevAPI Deploy

```cmd
powershell -ExecutionPolicy Bypass -File .\scripts\deploy_api.ps1 ^
  -ProjectId "fiscore-dev" ^
  -Region "us-central1" ^
  -Repository "fiscore" ^
  -ServiceName "fiscore-api" ^
  -ImageName "fiscore-api" ^
  -CloudSqlConnectionName "fiscore-dev:us-central1:fiscore-dev-pg" ^
  -RuntimeServiceAccount "fiscore-runtime@fiscore-dev.iam.gserviceaccount.com" ^
  -Environment "dev" ^
  -WorkerUrl "https://fiscore-worker-558552038453.us-central1.run.app"

```
