param(
    [string]$QueueRoot = ".\distributed-execution-queue\pending",
    [string]$OutputRoot = ".\distributed-worker-runtime"
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

function Invoke-DistributedWorkers {
    param([array]$Queue)

    $results = @()

    foreach ($task in $Queue) {

        $workerId = (
            [System.Guid]::NewGuid().Guid
        )

        $executionState = "COMPLETED"

        if (
            $task.ExecutionPriority -eq
            "CRITICAL"
        ) {
            $executionState = "PRIORITY_EXECUTED"
        }

        $processingLatency = Get-Random `
            -Minimum 20 `
            -Maximum 200

        $results += [PSCustomObject]@{
            WorkerId = $workerId
            QueueId = $task.QueueId
            Runtime = $task.Runtime
            ExecutionType = $task.ExecutionType
            ExecutionPriority = $task.ExecutionPriority
            ExecutionState = $executionState
            ProcessingLatencyMs = $processingLatency
            ProcessedAt = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $results
}

Write-Host ""
Write-Host "======================================="
Write-Host "DISTRIBUTED WORKER RUNTIME"
Write-Host "======================================="
Write-Host ""

$queueFile = Get-LatestFile `
    -Root $QueueRoot

$queue = Get-Content `
    $queueFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[queue-records] $($queue.Count)"

$workers =
Invoke-DistributedWorkers `
    -Queue $queue

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "execution-results\worker-execution-$timestamp.json"

$workers |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[worker-execution-written] $outputFile"
Write-Host ""
