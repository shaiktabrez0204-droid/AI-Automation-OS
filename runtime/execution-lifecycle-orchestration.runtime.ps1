<#
AI-Automation-OS runtime stage: execution lifecycle orchestration.

This stage reconciles pending queue entries with persistent worker state. It
does not perform recovery directly; it marks queue transitions and retry intent
so the recovery engine can make the next decision from explicit state.
#>

param(
    [string]$QueueRoot = ".\distributed-execution-queue\pending",
    [string]$WorkerStateRoot = ".\persistent-worker-lifecycle\worker-state",
    [string]$OutputRoot = ".\execution-lifecycle-orchestration"
)

$ErrorActionPreference = "Stop"

<#
============================================================
   ARTIFACT DISCOVERY
============================================================
#>

function Get-LatestFile {
    param([string]$Root)

    # Lifecycle orchestration depends on queue and worker snapshots from the
    # same recent run. The current convention picks newest files independently,
    # so mismatched timestamps are possible if stages are rerun out of order.
    Get-ChildItem `
        -Path $Root `
        -Filter "*.json" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

<#
============================================================
   LIFECYCLE RECONCILIATION
============================================================
#>

function Invoke-LifecycleOrchestration {
    param(
        [array]$Queue,
        [array]$Workers
    )

    $lifecycle = @()

    foreach ($task in $Queue) {

        $worker = $Workers |
        Where-Object {
            $_.QueueId -eq $task.QueueId
        } |
        Select-Object -First 1

        $queueTransition = "COMPLETED"

        if (
            $worker.WorkerState -eq
            "DEGRADED"
        ) {
            $queueTransition = "REQUEUE_REQUIRED"
        }

        $recoveryState = "NONE"

        # Recovery is expressed as intent, not action. The recovery engine owns
        # the decision to requeue so this stage stays a pure reconciliation pass.
        if (
            $queueTransition -eq
            "REQUEUE_REQUIRED"
        ) {
            $recoveryState = "RETRY_PENDING"
        }

        $executionLineage = (
            [System.Guid]::NewGuid().Guid
        )

        $lifecycle += [PSCustomObject]@{
            QueueId = $task.QueueId
            Runtime = $task.Runtime
            WorkerId = $worker.WorkerId
            QueueTransition = $queueTransition
            RecoveryState = $recoveryState
            ExecutionLineage = $executionLineage
            LifecycleTimestamp = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $lifecycle
}

<#
============================================================
   RUNTIME ENTRYPOINT
============================================================
#>

Write-Host ""
Write-Host "======================================="
Write-Host "EXECUTION LIFECYCLE ORCHESTRATION"
Write-Host "======================================="
Write-Host ""

$queueFile = Get-LatestFile `
    -Root $QueueRoot

$workerFile = Get-LatestFile `
    -Root $WorkerStateRoot

$queue = Get-Content `
    $queueFile.FullName `
    -Raw |
ConvertFrom-Json

$workers = Get-Content `
    $workerFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[queue-records] $($queue.Count)"
Write-Host "[worker-records] $($workers.Count)"

$lifecycle =
Invoke-LifecycleOrchestration `
    -Queue $queue `
    -Workers $workers

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "execution-transitions\execution-lifecycle-$timestamp.json"

$lifecycle |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[execution-lifecycle-written] $outputFile"
Write-Host ""
