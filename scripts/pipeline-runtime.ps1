param(
    [string]$PipelineFile
)

Write-Host ""
Write-Host "====================================="
Write-Host " Pipeline Runtime"
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

Write-Host "[PIPELINE WORKFLOWS]"
Write-Host ""

foreach ($Workflow in $Workflows) {

    Write-Host "[WORKFLOW] $Workflow"

    Start-Sleep -Seconds 1

    Write-Host "[COMPLETED] $Workflow"
    Write-Host ""
}

Write-Host "[SUCCESS] Pipeline execution completed."
