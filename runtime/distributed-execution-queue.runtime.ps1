param(
    [string]$EventBusRoot = ".\event-driven-cognition-bus\event-streams",
    [string]$OutputRoot = ".\distributed-execution-queue"
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

function Build-ExecutionQueue {
    param([array]$Events)

    $queue = @()

    foreach ($event in $Events) {

        $executionPriority = "NORMAL"

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
