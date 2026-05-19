param(
    [string]$QueueRoot = ".\distributed-execution-queue\pending",
    [string]$WorkerStateRoot = ".\persistent-worker-lifecycle\worker-state",
    [string]$OutputRoot = ".\execution-lifecycle-orchestration"
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
