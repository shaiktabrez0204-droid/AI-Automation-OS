$QueueFile = "runtime\queue\execution-queue.json"

Write-Host ""
Write-Host "====================================="
Write-Host " Queue Processor"
Write-Host "====================================="
Write-Host ""

if (-not (Test-Path $QueueFile)) {

    Write-Host "[ERROR] Queue file missing."
    exit 1
}

$QueueData = Get-Content $QueueFile | ConvertFrom-Json

if ($QueueData.queue.Count -eq 0) {

    Write-Host "[INFO] Queue is empty."
    exit 0
}

foreach ($Execution in $QueueData.queue) {

    if ($Execution.status -eq "PENDING") {

        Write-Host "[PROCESSING]"
        Write-Host "Workflow: $($Execution.workflow)"
        Write-Host "Execution ID: $($Execution.execution_id)"
        Write-Host ""

        $Execution.status = "RUNNING"

        $QueueData | ConvertTo-Json -Depth 10 | Set-Content $QueueFile

        Start-Sleep -Seconds 2

        $RandomNumber = Get-Random -Minimum 1 -Maximum 10

        if ($RandomNumber -le 2) {

            $Execution.status = "FAILED"

            Write-Host "[FAILED]"
            Write-Host $Execution.workflow
        }
        else {

            $Execution.status = "COMPLETED"

            Write-Host "[COMPLETED]"
            Write-Host $Execution.workflow
        }

        Write-Host ""

        $QueueData | ConvertTo-Json -Depth 10 | Set-Content $QueueFile
    }
}

Write-Host "[QUEUE PROCESSING COMPLETE]"
