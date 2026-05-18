$QueueFile = "runtime\queue\execution-queue.json"

Write-Host ""
Write-Host "====================================="
Write-Host " Execution Dispatcher"
Write-Host "====================================="
Write-Host ""

if (-not (Test-Path $QueueFile)) {

    Write-Host "[ERROR] Queue file missing."
    exit 1
}

$QueueData = Get-Content $QueueFile -Raw | ConvertFrom-Json

if ($QueueData.queue.Count -eq 0) {

    Write-Host "[INFO] Queue empty."
    exit 0
}

$PendingExecutions = $QueueData.queue | Where-Object {
    $_.status -eq "PENDING"
}

if ($PendingExecutions.Count -eq 0) {

    Write-Host "[INFO] No pending executions."
    exit 0
}

$NextExecution = $PendingExecutions | Sort-Object `
    @{Expression={
        switch ($_.priority) {
            "HIGH" {1}
            "MEDIUM" {2}
            "LOW" {3}
            default {4}
        }
    }},
    timestamp | Select-Object -First 1

Write-Host "[DISPATCHED EXECUTION]"
Write-Host ""

$NextExecution | Format-List

Write-Host ""

Write-Host "[UPDATING STATUS → RUNNING]"
Write-Host ""

foreach ($Execution in $QueueData.queue) {

    if ($Execution.execution_id -eq $NextExecution.execution_id) {

        $Execution.status = "RUNNING"
    }
}

$QueueData | ConvertTo-Json -Depth 10 | Set-Content $QueueFile

Start-Sleep -Seconds 2

$RandomNumber = Get-Random -Minimum 1 -Maximum 10

foreach ($Execution in $QueueData.queue) {

    if ($Execution.execution_id -eq $NextExecution.execution_id) {

        if ($RandomNumber -le 2) {

            $Execution.status = "FAILED"

            Write-Host "[EXECUTION FAILED]"
        }
        else {

            $Execution.status = "COMPLETED"

            Write-Host "[EXECUTION COMPLETED]"
        }
    }
}

$QueueData | ConvertTo-Json -Depth 10 | Set-Content $QueueFile

Write-Host ""
Write-Host "[QUEUE UPDATED]"
