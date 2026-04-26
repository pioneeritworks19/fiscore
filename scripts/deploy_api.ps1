param(
    [string]$ProjectId = "fiscore-dev",
    [string]$Region = "us-central1",
    [string]$Repository = "fiscore",
    [string]$ServiceName = "fiscore-api",
    [string]$ImageName = "fiscore-api",
    [string]$ImageTag = "latest",
    [string]$CloudSqlConnectionName = "fiscore-dev:us-central1:fiscore-dev-pg",
    [string]$RuntimeServiceAccount = "",
    [string]$Environment = "dev",
    [string]$WorkerUrl = "",
    [string]$WorkerAudience = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($RuntimeServiceAccount)) {
    $RuntimeServiceAccount = "fiscore-runtime@$ProjectId.iam.gserviceaccount.com"
}
if ([string]::IsNullOrWhiteSpace($WorkerUrl)) {
    throw "WorkerUrl is required so the API can dispatch manual runs to the private worker service."
}
if ([string]::IsNullOrWhiteSpace($WorkerAudience)) {
    $WorkerAudience = $WorkerUrl
}

$imageUri = "$Region-docker.pkg.dev/$ProjectId/$Repository/$ImageName`:$ImageTag"

Push-Location $repoRoot
try {
    Write-Host "Building API image: $imageUri"
    gcloud builds submit `
        --project $ProjectId `
        --config deploy/cloudbuild.api.yaml `
        --substitutions "_IMAGE_URI=$imageUri" `
        .

    Write-Host "Deploying Cloud Run service: $ServiceName"
    gcloud run deploy $ServiceName `
        --project $ProjectId `
        --region $Region `
        --image $imageUri `
        --service-account $RuntimeServiceAccount `
        --port 8080 `
        --memory 512Mi `
        --cpu 1 `
        --min-instances 0 `
        --timeout 300 `
        --ingress all `
        --no-allow-unauthenticated `
        --add-cloudsql-instances $CloudSqlConnectionName `
        --set-env-vars "APP_ENV=$Environment,GCP_PROJECT_ID=$ProjectId,GCP_REGION=$Region,DEFAULT_PARSER_VERSION=sword-v1,CLOUD_SQL_CONNECTION_NAME=$CloudSqlConnectionName,CLOUD_SQL_SOCKET_DIR=/cloudsql,RUN_DISPATCH_MODE=worker_http,WORKER_BASE_URL=$WorkerUrl,WORKER_AUDIENCE=$WorkerAudience" `
        --set-secrets "DB_HOST=DB_HOST:latest,DB_PORT=DB_PORT:latest,DB_NAME=DB_NAME:latest,DB_USER=DB_USER:latest,DB_PASSWORD=DB_PASSWORD:latest,RAW_ARTIFACT_BUCKET=RAW_ARTIFACT_BUCKET:latest"
}
finally {
    Pop-Location
}
