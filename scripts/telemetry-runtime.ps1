param(
    [string]$WorkflowFile
)

$ExecutionId = [guid]::NewGuid().ToString()

$ExecutionDir = "executions\active\$ExecutionId"

New-Item -ItemType Directory -Path $ExecutionDir -Force | Out-Null

$TelemetryFile = "$ExecutionDir\telemetry-report.txt"

$ExecutionStart = Get-Date

Write-Host ""
Write-Host "====================================="
Write-Host " Telemetry Workflow Runtime"
Write-Host "====================================="
Write-Host ""

Write-Host "[EXECUTION ID]"
Write-Host $ExecutionId
Write-Host ""

if (-not (Test-Path $WorkflowFile)) {

    Write-Host "[ERROR] Workflow file not found."

    Add-Content $TelemetryFile "STATUS: FAILED"

    exit 1
}

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

$TotalRetries = 0
$CompletedSteps = 0
$FailedSteps = 0

foreach ($Step in $ExecutionSteps) {

    $StepStart = Get-Date

    $RetryCount = 0
    $MaxRetries = 2
    $StepCompleted = $false

    while (-not $StepCompleted -and $RetryCount -le $MaxRetries) {

        Write-Host "[EXECUTING] $Step"

        Start-Sleep -Seconds 1

        $RandomNumber = Get-Random -Minimum 1 -Maximum 10

        if ($RandomNumber -le 2) {

            Write-Host "[FAILED] $Step"

            $RetryCount++
            $TotalRetries++

            if ($RetryCount -le $MaxRetries) {

                Write-Host "[RETRY] Attempt $RetryCount"

                Start-Sleep -Seconds 1
            }
            else {

                Write-Host "[ESCALATED] $Step"

                $FailedSteps++

                Add-Content $TelemetryFile "FAILED_STEP: $Step"

                Move-Item `
                    -Path $ExecutionDir `
                    -Destination "executions\failed\$ExecutionId"

                Write-Host ""
                Write-Host "[EXECUTION FAILED]"
                exit 1
            }
        }
        else {

            $StepEnd = Get-Date

            $StepDuration = ($StepEnd - $StepStart).TotalSeconds

            Write-Host "[COMPLETED] $Step"

            Add-Content $TelemetryFile "STEP: $Step"
            Add-Content $TelemetryFile "DURATION_SECONDS: $StepDuration"
            Add-Content $TelemetryFile "RETRIES: $RetryCount"
            Add-Content $TelemetryFile ""

            $CompletedSteps++

            $StepCompleted = $true
        }
    }

    Write-Host ""
}

$ExecutionEnd = Get-Date

$TotalDuration = ($ExecutionEnd - $ExecutionStart).TotalSeconds

Add-Content $TelemetryFile "================================="
Add-Content $TelemetryFile "EXECUTION SUMMARY"
Add-Content $TelemetryFile "================================="
Add-Content $TelemetryFile "EXECUTION_ID: $ExecutionId"
Add-Content $TelemetryFile "TOTAL_DURATION_SECONDS: $TotalDuration"
Add-Content $TelemetryFile "TOTAL_STEPS: $($ExecutionSteps.Count)"
Add-Content $TelemetryFile "COMPLETED_STEPS: $CompletedSteps"
Add-Content $TelemetryFile "FAILED_STEPS: $FailedSteps"
Add-Content $TelemetryFile "TOTAL_RETRIES: $TotalRetries"
Add-Content $TelemetryFile "STATUS: COMPLETED"

Move-Item `
    -Path $ExecutionDir `
    -Destination "executions\completed\$ExecutionId"

Write-Host "[SUCCESS] Execution complete."
Write-Host ""

Write-Host "[TELEMETRY GENERATED]"
Write-Host "Total Duration: $TotalDuration seconds"
Write-Host "Retries: $TotalRetries"
Write-Host "Completed Steps: $CompletedSteps"
