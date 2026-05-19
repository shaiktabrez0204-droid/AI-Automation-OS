param(
    [string]$PropagationRoot = ".\incremental-cognition-propagation\delta-streams",
    [string]$OutputRoot = ".\event-driven-cognition-bus"
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

function Build-CognitionEventBus {
    param([array]$Propagation)

    $events = @()

    $sequence = 0

    foreach ($delta in $Propagation) {

        $sequence++

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
