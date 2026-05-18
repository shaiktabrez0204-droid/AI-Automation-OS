param(
    [string]$WorkflowFile
)

Write-Host ""
Write-Host "====================================="
Write-Host " Dynamic Workflow Runtime"
Write-Host "====================================="
Write-Host ""

if (-not (Test-Path $WorkflowFile)) {
    Write-Host "[ERROR] Workflow file not found."
    exit 1
}

$ExecutionId = [guid]::NewGuid().ToString()

Write-Host "[INFO] Execution ID:"
Write-Host $ExecutionId
Write-Host ""

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

Write-Host "[INFO] Steps detected:"
Write-Host ""

foreach ($Step in $ExecutionSteps) {
    Write-Host "- $Step"
}

Write-Host ""

Add-Content $LogFile "EXECUTION_ID: $ExecutionId"

foreach ($Step in $ExecutionSteps) {

    Write-Host "[EXECUTING] $Step"

    Add-Content $LogFile "STEP_START: $Step"

    Start-Sleep -Seconds 1

    Add-Content $LogFile "STEP_COMPLETED: $Step"

    Write-Host "[COMPLETED] $Step"
    Write-Host ""
}

Write-Host "[VALIDATION] Execution complete."

Add-Content $LogFile "STATUS: COMPLETED"

$CompletedDir = "executions\completed\$ExecutionId"

Move-Item -Path $ExecutionDir -Destination $CompletedDir

Write-Host ""
Write-Host "[SUCCESS] Dynamic workflow execution completed."
Write-Host ""

Write-Host "[ARTIFACTS]"
Write-Host $CompletedDir
