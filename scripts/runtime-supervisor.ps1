$QueueFile = "runtime\queue\execution-queue.json"

Write-Host ""
Write-Host "====================================="
Write-Host " Runtime Supervisor"
Write-Host "====================================="
Write-Host ""

if (-not (Test-Path $QueueFile)) {

    Write-Host "[ERROR] Queue file missing."
    exit 1
}

$QueueData = Get-Content $QueueFile -Raw | ConvertFrom-Json

$FailedExecutions = $QueueData.queue | Where-Object {
    $_.status -eq "FAILED"
}

$RunningExecutions = $QueueData.queue | Where-Object {
    $_.status -eq "RUNNING"
}

$PendingExecutions = $QueueData.queue | Where-Object {
    $_.status -eq "PENDING"
}

$CompletedExecutions = $QueueData.queue | Where-Object {
    $_.status -eq "COMPLETED"
}

Write-Host "[SYSTEM STATUS]"
Write-Host ""

Write-Host "Pending:"
Write-Host $PendingExecutions.Count
Write-Host ""

Write-Host "Running:"
Write-Host $RunningExecutions.Count
Write-Host ""

Write-Host "Completed:"
Write-Host $CompletedExecutions.Count
Write-Host ""

Write-Host "Failed:"
Write-Host $FailedExecutions.Count
Write-Host ""

if ($FailedExecutions.Count -gt 0) {

    Write-Host "[FAILED EXECUTIONS DETECTED]"
    Write-Host ""

    $FailedExecutions | Format-Table
}

if ($RunningExecutions.Count -gt 5) {

    Write-Host "[ALERT] High runtime load detected."
}

if ($PendingExecutions.Count -gt 10) {

    Write-Host "[ALERT] Queue backlog detected."
}

Write-Host ""
Write-Host "[SUPERVISION COMPLETE]"
