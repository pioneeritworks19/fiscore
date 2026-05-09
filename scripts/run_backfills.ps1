[CmdletBinding()]
param(
    [ValidateSet('All', 'Sword', 'Georgia')]
    [string]$Platform = 'All',

    [string[]]$SourceSlugs = @(),

    [string]$RunMode = 'backfill',

    [string]$PythonPath = 'C:\Users\Kannappan\AppData\Local\Programs\Python\Python313\python.exe',

    [switch]$StopOnFailure
)

$ErrorActionPreference = 'Stop'

$script:Root = Split-Path -Parent $PSScriptRoot
$script:Runner = Join-Path $PSScriptRoot 'run_source_job.py'

function Get-SwordSourceSlugs {
    return @(
        'sword_mi_allegan',
        'sword_mi_grand_traverse',
        'sword_mi_livingston',
        'sword_mi_marquette',
        'sword_mi_muskegon',
        'sword_mi_oakland',
        'sword_mi_washtenaw',
        'sword_mi_wayne'
    )
}

function Get-GeorgiaSourceSlugs {
    $counties = @(
        'Appling',
        'Atkinson',
        'Bacon',
        'Baker',
        'Baldwin',
        'Banks',
        'Barrow',
        'Bartow',
        'Ben Hill',
        'Berrien',
        'Bibb',
        'Bleckley',
        'Brantley',
        'Brooks',
        'Bryan',
        'Bulloch',
        'Burke',
        'Butts',
        'Calhoun',
        'Camden',
        'Candler',
        'Carroll',
        'Catoosa',
        'Charlton',
        'Chatham',
        'Chattahoochee',
        'Chattooga',
        'Cherokee',
        'Clarke',
        'Clay',
        'Clayton',
        'Clinch',
        'Cobb',
        'Coffee',
        'Colquitt',
        'Columbia',
        'Cook',
        'Coweta',
        'Crawford',
        'Crisp',
        'Dade',
        'Dawson',
        'Decatur',
        'DeKalb',
        'Dodge',
        'Dooly',
        'Dougherty',
        'Douglas',
        'Early',
        'Echols',
        'Effingham',
        'Elbert',
        'Emanuel',
        'Evans',
        'Fannin',
        'Fayette',
        'Floyd',
        'Forsyth',
        'Franklin',
        'Fulton',
        'Gilmer',
        'Glascock',
        'Glynn',
        'Gordon',
        'Grady',
        'Greene',
        'Gwinnett',
        'Habersham',
        'Hall',
        'Hancock',
        'Haralson',
        'Harris',
        'Hart',
        'Heard',
        'Henry',
        'Houston',
        'Irwin',
        'Jackson',
        'Jasper',
        'Jeff Davis',
        'Jefferson',
        'Jenkins',
        'Johnson',
        'Jones',
        'Lamar',
        'Lanier',
        'Laurens',
        'Lee',
        'Liberty',
        'Lincoln',
        'Long',
        'Lowndes',
        'Lumpkin',
        'Macon',
        'Madison',
        'Marion',
        'McDuffie',
        'McIntosh',
        'Meriwether',
        'Miller',
        'Mitchell',
        'Monroe',
        'Montgomery',
        'Morgan',
        'Murray',
        'Muscogee',
        'Newton',
        'Oconee',
        'Oglethorpe',
        'Paulding',
        'Peach',
        'Pickens',
        'Pierce',
        'Pike',
        'Polk',
        'Pulaski',
        'Putnam',
        'Quitman',
        'Rabun',
        'Randolph',
        'Richmond',
        'Rockdale',
        'Schley',
        'Screven',
        'Seminole',
        'Spalding',
        'Stephens',
        'Stewart',
        'Sumter',
        'Talbot',
        'Taliaferro',
        'Tattnall',
        'Taylor',
        'Telfair',
        'Terrell',
        'Thomas',
        'Tift',
        'Toombs',
        'Towns',
        'Treutlen',
        'Troup',
        'Turner',
        'Twiggs',
        'Union',
        'Upson',
        'Walker',
        'Walton',
        'Ware',
        'Warren',
        'Washington',
        'Wayne',
        'Webster',
        'Wheeler',
        'White',
        'Whitfield',
        'Wilcox',
        'Wilkes',
        'Wilkinson',
        'Worth'
    )

    return $counties | ForEach-Object {
        'ga_{0}_food_service' -f ($_.ToLowerInvariant() -replace ' ', '_')
    }
}

function Get-SelectedSourceSlugs {
    if ($SourceSlugs.Count -gt 0) {
        return $SourceSlugs
    }

    switch ($Platform) {
        'Sword' { return Get-SwordSourceSlugs }
        'Georgia' { return Get-GeorgiaSourceSlugs }
        default { return @(Get-SwordSourceSlugs) + @(Get-GeorgiaSourceSlugs) }
    }
}

if (-not (Test-Path -LiteralPath $PythonPath)) {
    throw "Python executable not found: $PythonPath"
}

if (-not (Test-Path -LiteralPath $script:Runner)) {
    throw "Runner script not found: $script:Runner"
}

$selectedSourceSlugs = Get-SelectedSourceSlugs
if ($selectedSourceSlugs.Count -eq 0) {
    throw 'No source slugs selected.'
}

$results = New-Object System.Collections.Generic.List[object]
$startedAt = Get-Date

Write-Host "Starting $RunMode runs for $($selectedSourceSlugs.Count) source(s)..." -ForegroundColor Cyan

foreach ($sourceSlug in $selectedSourceSlugs) {
    $runStartedAt = Get-Date
    Write-Host ""
    Write-Host "[$($runStartedAt.ToString('u'))] Starting $sourceSlug ($RunMode)" -ForegroundColor Yellow

    $rawOutput = $null
    $parsedResponse = $null
    $success = $false
    $errorMessage = $null

    try {
        $rawOutput = & $PythonPath $script:Runner $sourceSlug $RunMode 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "run_source_job.py exited with code $LASTEXITCODE"
        }

        $rawText = ($rawOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        $parsedResponse = $rawText | ConvertFrom-Json
        $success = [bool]$parsedResponse.accepted

        if (-not $success) {
            $errorMessage = if ($parsedResponse.warnings) {
                ($parsedResponse.warnings -join '; ')
            }
            else {
                $parsedResponse.message
            }
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
    }

    $completedAt = Get-Date
    $duration = New-TimeSpan -Start $runStartedAt -End $completedAt

    $results.Add([pscustomobject]@{
        source_slug              = $sourceSlug
        run_mode                 = $RunMode
        success                  = $success
        scrape_run_id            = if ($parsedResponse) { $parsedResponse.scrape_run_id } else { $null }
        artifact_count           = if ($parsedResponse) { $parsedResponse.artifact_count } else { $null }
        parse_result_count       = if ($parsedResponse) { $parsedResponse.parse_result_count } else { $null }
        normalized_record_count  = if ($parsedResponse) { $parsedResponse.normalized_record_count } else { $null }
        duration_seconds         = [math]::Round($duration.TotalSeconds, 0)
        error_message            = $errorMessage
    }) | Out-Null

    if ($success) {
        Write-Host "Completed $sourceSlug in $([math]::Round($duration.TotalMinutes, 1)) min. scrape_run_id=$($parsedResponse.scrape_run_id)" -ForegroundColor Green
    }
    else {
        Write-Host "Failed $sourceSlug after $([math]::Round($duration.TotalMinutes, 1)) min. $errorMessage" -ForegroundColor Red
        if ($StopOnFailure) {
            break
        }
    }
}

$endedAt = Get-Date
$totalDuration = New-TimeSpan -Start $startedAt -End $endedAt
$successCount = ($results | Where-Object { $_.success }).Count
$failureCount = ($results | Where-Object { -not $_.success }).Count

Write-Host ""
Write-Host "Run summary: $successCount succeeded, $failureCount failed in $([math]::Round($totalDuration.TotalMinutes, 1)) min." -ForegroundColor Cyan
$results | Format-Table -AutoSize
