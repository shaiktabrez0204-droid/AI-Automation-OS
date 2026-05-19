param(
    [string]$EventBusRoot = ".\event-driven-cognition-bus\event-streams",
    [string]$LocalGovernanceRoot = ".\runtime-local-governance\local-policy-state",
    [string]$OutputRoot = ".\runtime-local-event-journaling"
)

$ErrorActionPreference = "Stop"

function Get-LatestFile {
    param([string]$Root)

    Get-ChildItem `
        -Path $Root `
        -Filter "*.json" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

function Build-RuntimeJournals {
    param(
        [array]$Events,
        [array]$Governance
    )

    $journals = @()

    foreach ($event in $Events) {

        $governanceRecord = $Governance |
        Where-Object {
            $_.Runtime -eq $event.Runtime
        } |
        Select-Object -First 1

        $checkpointState = "ACTIVE"

        if (
            $governanceRecord.LocalExecutionState -eq
            "CONSTRAINED"
        ) {
            $checkpointState = "RESTRICTED"
        }

        if (
            $governanceRecord.LocalExecutionState -eq
            "ISOLATED"
        ) {
            $checkpointState = "LOCKED"
        }

        $replayState = "REPLAYABLE"

        if (
            $event.EventPriority -eq "CRITICAL"
        ) {
            $replayState = "REQUIRES_VALIDATION"
        }

        $journalHash = (
            [System.Guid]::NewGuid().Guid
        )

        $journals += [PSCustomObject]@{
            Runtime = $event.Runtime
            EventSequence = $event.EventSequence
            EventType = $event.EventType
            JournalHash = $journalHash
            ReplayState = $replayState
            CheckpointState = $checkpointState
            GovernanceScope = $governanceRecord.ConstraintScope
            JournalTimestamp = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $journals
}

Write-Host ""
Write-Host "======================================="
Write-Host "RUNTIME-LOCAL EVENT JOURNALING"
Write-Host "======================================="
Write-Host ""

$eventFile = Get-LatestFile `
    -Root $EventBusRoot

$governanceFile = Get-LatestFile `
    -Root $LocalGovernanceRoot

$events = Get-Content `
    $eventFile.FullName `
    -Raw |
ConvertFrom-Json

$governance = Get-Content `
    $governanceFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[event-records] $($events.Count)"
Write-Host "[governance-records] $($governance.Count)"

$journals =
Build-RuntimeJournals `
    -Events $events `
    -Governance $governance

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "event-journals\runtime-event-journal-$timestamp.json"

$journals |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[runtime-event-journal-written] $outputFile"
Write-Host ""
