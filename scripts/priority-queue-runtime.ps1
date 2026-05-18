param(
    [string]$WorkflowName,
    [string]$Priority = "MEDIUM"
)

$QueueFile = "runtime\queue\execution-queue.json"

Write-Host ""
Write-Host "====================================="
Write-Host " Priority Queue Runtime"
Write-Host "====================================="
Write-Host ""

if (-not (Test-Path $QueueFile)) {

    Write-Host "[ERROR] Queue file missing."
    exit 1
}

$QueueData = Get-Content $QueueFile -Raw | ConvertFrom-Json

# Ensure queue is always an array
if ($null -eq $QueueData.queue) {
    $QueueData.queue = @()
}

if ($QueueData.queue -isnot [System.Collections.IEnumerable]) {
    $QueueData.queue = @($QueueData.queue)
}

$ExecutionId = [guid]::NewGuid().ToString()

$ExecutionObject = [PSCustomObject]@{
    execution_id = $ExecutionId
    workflow = $WorkflowName
    priority = $Priority
    status = "PENDING"
    timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

$UpdatedQueue = @()

$UpdatedQueue += $QueueData.queue
$UpdatedQueue += $ExecutionObject

$UpdatedQueue = $UpdatedQueue | Sort-Object `
    @{Expression={
        switch ($_.priority) {
            "HIGH" {1}
            "MEDIUM" {2}
            "LOW" {3}
            default {4}
        }
    }},
    timestamp

$QueueData.queue = $UpdatedQueue

$QueueData | ConvertTo-Json -Depth 10 | Set-Content $QueueFile

Write-Host "[QUEUED]"
Write-Host "Workflow: $WorkflowName"
Write-Host "Priority: $Priority"
Write-Host ""

Write-Host "[QUEUE ORDER]"
Write-Host ""

$QueueData.queue | Format-Table
