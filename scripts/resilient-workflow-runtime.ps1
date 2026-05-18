param(
    [string]$WorkflowFile
)

Write-Host ""
Write-Host "====================================="
Write-Host " Resilient Workflow Runtime"
Write-Host "====================================="
Write-Host ""

if (-not (Test-Path $WorkflowFile)) {
    Write-Host "[ERROR] Workflow file not found."
    exit 1
}

$ExecutionId = [guid]::NewGuid().ToString()

$ExecutionDir = "executions\active\$ExecutionId"

New-Item -ItemType Directory -Path $ExecutionDir -Force | Out-Null

$LogFile = "$ExecutionDir\runtime-log.txt"

$Content = Get-Content $WorkflowFile

$ExecutionSteps = @()

$CaptureSteps = $false

foreach ($Line in $Content) {

    if ($Line -match "steps:") {
        $CaptureSteps = $true
        continue
    }

    if ($CaptureSteps -and $Line -match "validations:") {
        $CaptureSteps = $false
    }

    if ($CaptureSteps -and $Line.Trim().StartsWith("-")) {

        $Step = $Line.Trim().Replace("- ", "")

        $ExecutionSteps += $Step
    }
}

Write-Host "[INFO] Execution ID:"
Write-Host $ExecutionId
Write-Host ""

Add-Content $LogFile "EXECUTION_ID: $ExecutionId"

foreach ($Step in $ExecutionSteps) {

    $RetryCount = 0
    $MaxRetries = 2
    $StepCompleted = $false

    while (-not $StepCompleted -and $RetryCount -le $MaxRetries) {

        Write-Host "[EXECUTING] $Step"

        Add-Content $LogFile "STEP_EXECUTING: $Step"

        Start-Sleep -Seconds 1

        # Simulated failure condition
        $RandomNumber = Get-Random -Minimum 1 -Maximum 10

        if ($RandomNumber -le 2) {

            Write-Host "[FAILED] $Step"

            Add-Content $LogFile "STEP_FAILED: $Step"

            $RetryCount++

            if ($RetryCount -le $MaxRetries) {

                Write-Host "[RETRY] Attempt $RetryCount for $Step"

                Add-Content $LogFile "STEP_RETRY: $Step"

                Start-Sleep -Seconds 1
            }
            else {

                Write-Host "[ESCALATED] $Step exceeded retry threshold"

                Add-Content $LogFile "STEP_ESCALATED: $Step"

                Move-Item `
                    -Path $ExecutionDir `
                    -Destination "executions\failed\$ExecutionId"

                Write-Host ""
                Write-Host "[EXECUTION FAILED]"
                exit 1
            }
        }
        else {

            Write-Host "[COMPLETED] $Step"

            Add-Content $LogFile "STEP_COMPLETED: $Step"

            $StepCompleted = $true
        }

        Write-Host ""
    }
}

Write-Host "[VALIDATION] Workflow execution complete."

Add-Content $LogFile "STATUS: COMPLETED"

Move-Item `
    -Path $ExecutionDir `
    -Destination "executions\completed\$ExecutionId"

Write-Host ""
Write-Host "[SUCCESS] Resilient execution completed."
