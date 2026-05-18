param(
    [string]$WorkflowFile
)

$ExecutionId = [guid]::NewGuid().ToString()

$ExecutionDir = "executions\active\$ExecutionId"

New-Item -ItemType Directory -Path $ExecutionDir -Force | Out-Null

$TelemetryFile = "$ExecutionDir\telemetry-report.txt"

$RegistryFile = "runtime\telemetry\execution-registry.csv"

$ExecutionStart = Get-Date

Write-Host ""
Write-Host "====================================="
Write-Host " Registry Workflow Runtime"
Write-Host "====================================="
Write-Host ""

Write-Host "[EXECUTION ID]"
Write-Host $ExecutionId
Write-Host ""

if (-not (Test-Path $WorkflowFile)) {

    Write-Host "[ERROR] Workflow file not found."
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
$ExecutionStatus = "COMPLETED"

foreach ($Step in $ExecutionSteps) {

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
                $ExecutionStatus = "FAILED"

                Move-Item `
                    -Path $ExecutionDir `
                    -Destination "executions\failed\$ExecutionId"

                break
            }
        }
        else {

            Write-Host "[COMPLETED] $Step"

            $CompletedSteps++

            $StepCompleted = $true
        }
    }

    if ($ExecutionStatus -eq "FAILED") {
        break
    }

    Write-Host ""
}

$ExecutionEnd = Get-Date

$TotalDuration = ($ExecutionEnd - $ExecutionStart).TotalSeconds

$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$RegistryEntry = `
"$ExecutionId,$ExecutionStatus,$($ExecutionSteps.Count),$CompletedSteps,$TotalRetries,$TotalDuration,$Timestamp"

Add-Content $RegistryFile $RegistryEntry

if ($ExecutionStatus -eq "COMPLETED") {

    Move-Item `
        -Path $ExecutionDir `
        -Destination "executions\completed\$ExecutionId"

    Write-Host ""
    Write-Host "[SUCCESS] Execution completed."
}
else {

    Write-Host ""
    Write-Host "[FAILED] Execution failed."
}

Write-Host ""
Write-Host "[REGISTRY UPDATED]"
Write-Host $RegistryFile
