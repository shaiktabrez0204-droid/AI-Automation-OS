param(
    [string]$WorkerRoot = ".\distributed-worker-runtime\execution-results",
    [string]$OutputRoot = ".\persistent-worker-lifecycle"
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
