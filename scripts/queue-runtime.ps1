param(
    [string]$WorkflowName
)

$QueueFile = "runtime\queue\execution-queue.json"

Write-Host ""
Write-Host "====================================="
Write-Host " Queue Runtime"
Write-Host "====================================="
Write-Host ""

if (-not (Test-Path $QueueFile)) {

    Write-Host "[ERROR] Queue file missing."
    exit 1
}

$QueueData = Get-Content $QueueFile | ConvertFrom-Json

$ExecutionId = [guid]::NewGuid().ToString()

$ExecutionObject = [PSCustomObject]@{
    execution_id = $ExecutionId
    workflow = $WorkflowName
    status = "PENDING"
    timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

$QueueData.queue += $ExecutionObject

$QueueData | ConvertTo-Json -Depth 10 | Set-Content $QueueFile

Write-Host "[QUEUED]"
Write-Host "Workflow: $WorkflowName"
Write-Host "Execution ID: $ExecutionId"
Write-Host ""

Write-Host "[CURRENT QUEUE]"
Write-Host ""

$QueueData.queue | Format-Table
