<#
AI-Automation-OS runtime stage: event-driven cognition bus.

This stage converts propagation deltas into ordered runtime events. It is a
snapshot-to-snapshot transform: read the newest upstream artifact, emit a new
timestamped artifact, and leave prior history untouched for later inspection.
#>

param(
    [string]$PropagationRoot = ".\incremental-cognition-propagation\delta-streams",
    [string]$OutputRoot = ".\event-driven-cognition-bus"
)

$ErrorActionPreference = "Stop"

<#
============================================================
   ARTIFACT DISCOVERY
============================================================
#>

function Get-LatestFile {
    param([string]$Root)

    # Runtime stages use "latest JSON wins" handoff to keep manual execution
    # simple. The tradeoff is operational: stale artifacts can steer a run if an
    # upstream directory contains old output that looks newer than expected.
    Get-ChildItem `
        -Path $Root `
        -Filter "*.json" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

<#
============================================================
   EVENT NORMALIZATION
============================================================
#>

function Build-CognitionEventBus {
    param([array]$Propagation)

    $events = @()

    $sequence = 0

    foreach ($delta in $Propagation) {

        $sequence++

        # Keep event categories intentionally narrow. Downstream queueing only
        # needs to know whether it is handling ordinary state, mutation, or
        # recovery pressure.
        $eventType = "STATE_UPDATE"

        switch ($delta.DeltaType) {

            "TOPOLOGY_MUTATION" {
                $eventType = "MUTATION_EVENT"
            }

            "RECOVERY_PROPAGATION" {
                $eventType = "RECOVERY_EVENT"
            }
        }

        $eventPriority = "NORMAL"

        # Priority is reduced to a small runtime vocabulary here so worker and
        # governance stages do not need to understand every propagation detail.
        switch ($delta.PropagationPriority) {

            "HIGH" {
                $eventPriority = "ELEVATED"
            }

            "CRITICAL" {
                $eventPriority = "CRITICAL"
            }
        }

        $events += [PSCustomObject]@{
            EventSequence = $sequence
            Runtime = $delta.Runtime
            EventType = $eventType
            EventPriority = $eventPriority
            DeltaHash = $delta.DeltaHash
            MutationRisk = $delta.MutationRisk
            HealingStrategy = $delta.HealingStrategy
            EventTimestamp = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $events
}

<#
============================================================
   RUNTIME ENTRYPOINT
============================================================
#>

Write-Host ""
Write-Host "======================================="
Write-Host "EVENT-DRIVEN COGNITION BUS"
Write-Host "======================================="
Write-Host ""

$propagationFile = Get-LatestFile `
    -Root $PropagationRoot

$propagation = Get-Content `
    $propagationFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[propagation-records] $($propagation.Count)"

$eventBus =
Build-CognitionEventBus `
    -Propagation $propagation

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "event-streams\cognition-event-bus-$timestamp.json"

$eventBus |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[cognition-event-bus-written] $outputFile"
Write-Host ""
