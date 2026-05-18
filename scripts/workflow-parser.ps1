param(
    [string]$WorkflowFile
)

Write-Host ""
Write-Host "====================================="
Write-Host " Workflow Parser"
Write-Host "====================================="
Write-Host ""

if (-not (Test-Path $WorkflowFile)) {
    Write-Host "[ERROR] Workflow file not found."
    exit 1
}

$Content = Get-Content $WorkflowFile

Write-Host "[INFO] Parsing workflow metadata..."
Write-Host ""

foreach ($Line in $Content) {

    if ($Line -match "id:") {
        Write-Host "[WORKFLOW ID] $Line"
    }

    if ($Line -match "name:") {
        Write-Host "[WORKFLOW NAME] $Line"
    }

    if ($Line -match "version:") {
        Write-Host "[VERSION] $Line"
    }

    if ($Line -match "- load_profiles") {
        Write-Host "[STEP DETECTED] load_profiles"
    }

    if ($Line -match "- retrieve_memory") {
        Write-Host "[STEP DETECTED] retrieve_memory"
    }

    if ($Line -match "- assemble_context") {
        Write-Host "[STEP DETECTED] assemble_context"
    }
}

Write-Host ""
Write-Host "[SUCCESS] Workflow parsing completed."
