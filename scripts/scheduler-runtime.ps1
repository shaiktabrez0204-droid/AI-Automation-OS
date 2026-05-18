param(
    [string]$WorkflowName,
    [int]$DelaySeconds = 5,
    [string]$Priority = "MEDIUM"
)

$QueueFile = "runtime\queue\execution-queue.json"

Write-Host ""
Write-Host "====================================="
Write-Host " Scheduler Runtime"
Write-Host "====================================="
Write-Host ""

Write-Host "[SCHEDULED]"
Write-Host "Workflow: $WorkflowName"
Write-Host "Delay: $DelaySeconds seconds"
Write-Host "Priority: $Priority"
Write-Host ""

Start-Sleep -Seconds $DelaySeconds

Write-Host "[ENQUEUEING WORKFLOW]"
Write-Host ""

$QueueData = Get-Content $QueueFile -Raw | ConvertFrom-Json

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

Write-Host "[WORKFLOW QUEUED]"
Write-Host "Execution ID: $ExecutionId"
Write-Host ""

$QueueData.queue | Format-Table
