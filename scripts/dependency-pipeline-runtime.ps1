param(
    [string]$PipelineFile
)

Write-Host ""
Write-Host "====================================="
Write-Host " Dependency Pipeline Runtime"
Write-Host "====================================="
Write-Host ""

if (-not (Test-Path $PipelineFile)) {

    Write-Host "[ERROR] Pipeline file not found."
    exit 1
}

$Content = Get-Content $PipelineFile

$Workflows = @()

$Capture = $false

foreach ($Line in $Content) {

    if ($Line -match "workflows:") {
        $Capture = $true
        continue
    }

    if ($Capture -and $Line -match "execution_order:") {
        $Capture = $false
    }

    if ($Capture -and $Line.Trim().StartsWith("-")) {

        $Workflow = $Line.Trim().Replace("- ", "")

        $Workflows += $Workflow
    }
}

Write-Host "[PIPELINE VALIDATION]"
Write-Host ""

foreach ($Workflow in $Workflows) {

    $WorkflowPath = "workflows\templates\$Workflow.yaml"

    if (Test-Path $WorkflowPath) {

        Write-Host "[VALID] $Workflow"

    }
    else {

        Write-Host "[MISSING] $Workflow"

        Write-Host ""
        Write-Host "[PIPELINE STOPPED]"
        exit 1
    }
}

Write-Host ""
Write-Host "[PIPELINE EXECUTION]"
Write-Host ""

foreach ($Workflow in $Workflows) {

    Write-Host "[EXECUTING] $Workflow"

    Start-Sleep -Seconds 1

    $RandomNumber = Get-Random -Minimum 1 -Maximum 10

    if ($RandomNumber -le 2) {

        Write-Host "[FAILED] $Workflow"

        Write-Host ""
        Write-Host "[PIPELINE ESCALATED]"
        exit 1
    }

    Write-Host "[COMPLETED] $Workflow"
    Write-Host ""
}

Write-Host "[SUCCESS] Pipeline completed successfully."
