param(
    [string]$EventBusRoot = ".\event-driven-cognition-bus\event-streams",
    [string]$OutputRoot = ".\distributed-cognition-consensus"
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

function Build-ConsensusState {
    param([array]$Events)

    $consensus = @()

    foreach ($event in $Events) {

        $quorumState = "ACCEPTED"

        if (
            $event.EventPriority -eq "CRITICAL"
        ) {
            $quorumState = "REVIEW_REQUIRED"
        }

        $orderingState = "ORDERED"

        if (
            $event.EventSequence % 7 -eq 0
        ) {
            $orderingState = "RESEQUENCING_REQUIRED"
        }

        $conflictState = "NONE"

        if (
            ($event.EventPriority -eq "CRITICAL") -and
            ($orderingState -eq "RESEQUENCING_REQUIRED")
        ) {
            $conflictState = "SEQUENCE_CONFLICT"
        }

        $journalEpoch = (
            [math]::Floor(
                $event.EventSequence / 10
            )
        )

        $consensus += [PSCustomObject]@{
            Runtime = $event.Runtime
            EventSequence = $event.EventSequence
            EventType = $event.EventType
            QuorumState = $quorumState
            OrderingState = $orderingState
            ConflictState = $conflictState
            JournalEpoch = $journalEpoch
            ConsensusTimestamp = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $consensus
}

Write-Host ""
Write-Host "======================================="
Write-Host "DISTRIBUTED COGNITION CONSENSUS"
Write-Host "======================================="
Write-Host ""

$eventFile = Get-LatestFile `
    -Root $EventBusRoot

$events = Get-Content `
    $eventFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[event-records] $($events.Count)"

$consensus =
Build-ConsensusState `
    -Events $events

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "quorum-state\distributed-consensus-$timestamp.json"

$consensus |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[distributed-consensus-written] $outputFile"
Write-Host ""
