<#
AI-Automation-OS runtime stage: persistent worker lifecycle.

This stage converts worker execution results into durable worker state. The
output is the lifecycle source of truth used by orchestration and recovery
stages to decide whether work can be trusted or must be retried.
#>

param(
    [string]$WorkerRoot = ".\distributed-worker-runtime\execution-results",
    [string]$OutputRoot = ".\persistent-worker-lifecycle"
)

$ErrorActionPreference = "Stop"

<#
============================================================
   ARTIFACT DISCOVERY
============================================================
#>

function Get-LatestFile {
    param([string]$Root)

    # This runtime follows the repository's append-only artifact convention:
    # read the newest upstream snapshot and write a new timestamped state file.
    Get-ChildItem `
        -Path $Root `
        -Filter "*.json" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

<#
============================================================
   WORKER STATE PROJECTION
============================================================
#>

function Build-PersistentWorkers {
    param([array]$Workers)

    $state = @()

    foreach ($worker in $Workers) {

        $heartbeatState = "ACTIVE"

        $leaseState = "OWNED"

        $retryState = "NONE"

        if (
            $worker.ExecutionPriority -eq
            "CRITICAL"
        ) {
            $leaseState = "PRIORITY_OWNERSHIP"
        }

        # Degradation is inferred from latency for now. That keeps the pipeline
        # executable without a live worker pool, but it is a simulation boundary
        # rather than a definitive health signal.
        if (
            $worker.ProcessingLatencyMs -gt 150
        ) {
            $retryState = "RETRY_ELIGIBLE"
        }

        $workerState = "HEALTHY"

        if (
            $retryState -eq
            "RETRY_ELIGIBLE"
        ) {
            $workerState = "DEGRADED"
        }

        $state += [PSCustomObject]@{
            WorkerId = $worker.WorkerId
            QueueId = $worker.QueueId
            Runtime = $worker.Runtime
            WorkerState = $workerState
            HeartbeatState = $heartbeatState
            LeaseState = $leaseState
            RetryState = $retryState
            OwnershipTimestamp = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $state
}

<#
============================================================
   RUNTIME ENTRYPOINT
============================================================
#>

Write-Host ""
Write-Host "======================================="
Write-Host "PERSISTENT WORKER LIFECYCLE"
Write-Host "======================================="
Write-Host ""

$workerFile = Get-LatestFile `
    -Root $WorkerRoot

$workers = Get-Content `
    $workerFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[worker-records] $($workers.Count)"

$persistent =
Build-PersistentWorkers `
    -Workers $workers

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "worker-state\persistent-workers-$timestamp.json"

$persistent |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[persistent-workers-written] $outputFile"
Write-Host ""
