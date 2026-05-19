<#
AI-Automation-OS runtime stage: runtime-local event journaling.

This stage attaches local governance context to event bus records. It creates
runtime-scoped replay checkpoints before the execution journal commits broader
queue and recovery state.
#>

param(
    [string]$EventBusRoot = ".\event-driven-cognition-bus\event-streams",
    [string]$LocalGovernanceRoot = ".\runtime-local-governance\local-policy-state",
    [string]$OutputRoot = ".\runtime-local-event-journaling"
)

$ErrorActionPreference = "Stop"

<#
============================================================
   ARTIFACT DISCOVERY
============================================================
#>

function Get-LatestFile {
    param([string]$Root)

    # Event and governance snapshots are paired by "latest file" convention.
    # That keeps this stage terminal-friendly, but a future runner should pass
    # explicit artifact ids when strict causality is required.
    Get-ChildItem `
        -Path $Root `
        -Filter "*.json" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

<#
============================================================
   LOCAL EVENT JOURNALING
============================================================
#>

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

        # Local governance affects replay posture. A constrained runtime can
        # still journal events, but consumers need to know the checkpoint was
        # created under restricted execution.
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

        # Critical events stay replayable but require validation because their
        # downstream consequences are allowed to affect recovery decisions.
        if (
            $event.EventPriority -eq "CRITICAL"
        ) {
            $replayState = "REQUIRES_VALIDATION"
        }

        $journalHash = (
            [System.Guid]::NewGuid().Guid
        )

        # JournalHash is a generated lineage marker in the current system, not
        # a content hash. Treat it as identity, not integrity verification.
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

<#
============================================================
   RUNTIME ENTRYPOINT
============================================================
#>

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
