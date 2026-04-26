param(
    [Parameter(Mandatory = $true)]
    [string]$WorkerUrl,
    [string]$ProjectId = "fiscore-dev",
    [string]$Region = "us-central1",
    [string]$SchedulerServiceAccount = "",
    [string]$Schedule = "0 9 * * 1",
    [string]$TimeZone = "America/New_York",
    [string[]]$SourceSlugs = @("sword_mi_wayne"),
    [string]$RunMode = "incremental"
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($SchedulerServiceAccount)) {
    $SchedulerServiceAccount = "fiscore-scheduler@$ProjectId.iam.gserviceaccount.com"
}

function Get-JobName([string]$sourceSlug, [string]$runMode) {
    $safeSource = $sourceSlug -replace "_", "-"
    return "fiscore-$safeSource-$runMode"
}

foreach ($sourceSlug in $SourceSlugs) {
    $jobName = Get-JobName -sourceSlug $sourceSlug -runMode $RunMode
    $payload = @{
        source_slug = $sourceSlug
        run_mode = $RunMode
        trigger_type = "scheduler"
    } | ConvertTo-Json -Compress
    $targetUrl = "$WorkerUrl/jobs/run"
    $payloadFile = Join-Path ([System.IO.Path]::GetTempPath()) "$jobName-payload.json"
    Set-Content -LiteralPath $payloadFile -Value $payload -Encoding utf8

    $existing = $null
    try {
        $existing = gcloud scheduler jobs describe $jobName `
            --project $ProjectId `
            --location $Region `
            --format "value(name)" 2>$null
    }
    catch {
        $existing = $null
    }

    try {
        if ($existing) {
            Write-Host "Updating scheduler job: $jobName"
            gcloud scheduler jobs update http $jobName `
                --project $ProjectId `
                --location $Region `
                --schedule $Schedule `
                --time-zone $TimeZone `
                --uri $targetUrl `
                --http-method POST `
                --update-headers "Content-Type=application/json" `
                --message-body-from-file $payloadFile `
                --oidc-service-account-email $SchedulerServiceAccount `
                --oidc-token-audience $WorkerUrl
        }
        else {
            Write-Host "Creating scheduler job: $jobName"
            gcloud scheduler jobs create http $jobName `
                --project $ProjectId `
                --location $Region `
                --schedule $Schedule `
                --time-zone $TimeZone `
                --uri $targetUrl `
                --http-method POST `
                --headers "Content-Type=application/json" `
                --message-body-from-file $payloadFile `
                --oidc-service-account-email $SchedulerServiceAccount `
                --oidc-token-audience $WorkerUrl
        }
    }
    finally {
        Remove-Item -LiteralPath $payloadFile -ErrorAction SilentlyContinue
    }
}
