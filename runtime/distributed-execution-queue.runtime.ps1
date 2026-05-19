<#
AI-Automation-OS runtime stage: distributed execution queue.

This stage turns runtime events into queueable execution work. It does not
dispatch work itself; it classifies intent and priority so worker runtimes can
consume a stable pending queue artifact.
#>

param(
    [string]$EventBusRoot = ".\event-driven-cognition-bus\event-streams",
    [string]$OutputRoot = ".\distributed-execution-queue"
)

$ErrorActionPreference = "Stop"

<#
============================================================
   ARTIFACT DISCOVERY
============================================================
#>

function Get-LatestFile {
    param([string]$Root)

    # All current pipeline stages bind to the newest artifact in their upstream
    # directory. That convention keeps stages composable from the terminal, but
    # it assumes operators know which artifact was just produced.
    Get-ChildItem `
        -Path $Root `
        -Filter "*.json" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

<#
============================================================
   QUEUE CONSTRUCTION
============================================================
#>

function Build-ExecutionQueue {
    param([array]$Events)

    $queue = @()

    foreach ($event in $Events) {

        $executionPriority = "NORMAL"

        # Preserve the event bus priority model while translating it into the
        # execution vocabulary used by worker and lifecycle stages.
        switch ($event.EventPriority) {

            "ELEVATED" {
                $executionPriority = "HIGH"
            }

            "CRITICAL" {
                $executionPriority = "CRITICAL"
            }
        }

        $queueState = "PENDING"

        $executionType = "STANDARD_RUNTIME"

        # Queue consumers do not need the original cognition event taxonomy.
        # They need to know which operational path should handle the work.
        switch ($event.EventType) {

            "MUTATION_EVENT" {
                $executionType = "TOPOLOGY_MUTATION"
            }

            "RECOVERY_EVENT" {
                $executionType = "RUNTIME_RECOVERY"
            }
        }

        $queue += [PSCustomObject]@{
            QueueId = (
                [System.Guid]::NewGuid().Guid
            )
            Runtime = $event.Runtime
            EventSequence = $event.EventSequence
            ExecutionType = $executionType
            ExecutionPriority = $executionPriority
            QueueState = $queueState
            EventType = $event.EventType
            QueuedAt = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $queue
}

<#
============================================================
   RUNTIME ENTRYPOINT
============================================================
#>

Write-Host ""
Write-Host "======================================="
Write-Host "DISTRIBUTED EXECUTION QUEUE"
Write-Host "======================================="
Write-Host ""

$eventFile = Get-LatestFile `
    -Root $EventBusRoot

$events = Get-Content `
    $eventFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[event-records] $($events.Count)"

$queue =
Build-ExecutionQueue `
    -Events $events

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "pending\execution-queue-$timestamp.json"

$queue |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[execution-queue-written] $outputFile"
Write-Host ""
