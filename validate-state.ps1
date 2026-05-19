$ErrorActionPreference = "Stop"

# =========================================================
# AI-Automation-OS
# State Schema Validation Engine
# =========================================================

$STATE_PATH = ".\state\project-state.json"

if (!(Test-Path $STATE_PATH)) {

    Write-Host ""
    Write-Host "[ERROR] project-state.json not found"
    Write-Host ""

    exit 1
}

try {
    $state = Get-Content $STATE_PATH -Raw | ConvertFrom-Json
}
catch {

    Write-Host ""
    Write-Host "[ERROR] Failed to parse project-state.json"
    Write-Host ""

    exit 1
}

# -----------------------------
# REQUIRED FIELDS
# -----------------------------
$requiredFields = @(
    "project",
    "phase",
    "current_task",
    "next_task",
    "last_checkpoint",
    "execution_history",
    "compressed_context"
)

$missingFields = @()

foreach ($field in $requiredFields) {

    if (-not $state.PSObject.Properties[$field]) {
        $missingFields += $field
    }
}

Clear-Host

Write-Host ""
Write-Host "=================================================="
Write-Host "STATE SCHEMA VALIDATION"
Write-Host "=================================================="

Write-Host ""
Write-Host "STATE FILE"
Write-Host "--------------------------------------------------"
Write-Host "$STATE_PATH"

Write-Host ""

if ($missingFields.Count -eq 0) {

    Write-Host "STATUS"
    Write-Host "--------------------------------------------------"
    Write-Host "State schema validation successful"

    Write-Host ""
    Write-Host "Required fields verified:"
    Write-Host "$($requiredFields -join "`n")"
}
else {

    Write-Host "STATUS"
    Write-Host "--------------------------------------------------"
    Write-Host "State schema validation FAILED"

    Write-Host ""
    Write-Host "Missing fields:"
    Write-Host "$($missingFields -join "`n")"

    exit 1
}

Write-Host ""
Write-Host "=================================================="
Write-Host ""
