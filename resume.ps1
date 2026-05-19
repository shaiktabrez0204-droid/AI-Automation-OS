$ErrorActionPreference = "Stop"

# =========================================================
# AI-Automation-OS
# Universal Persistent Execution State Layer
# Resume Engine
# =========================================================

# -----------------------------
# PATH CONFIGURATION
# -----------------------------
$STATE_PATH = ".\state\project-state.json"

# -----------------------------
# STATE VALIDATION
# -----------------------------
if (!(Test-Path $STATE_PATH)) {
    Write-Host ""
    Write-Host "[ERROR] project-state.json not found"
    Write-Host "Expected Path: $STATE_PATH"
    Write-Host ""
    exit 1
}

# -----------------------------
# LOAD STATE
# -----------------------------
try {
    $state = Get-Content $STATE_PATH -Raw | ConvertFrom-Json
}
catch {
    Write-Host ""
    Write-Host "[ERROR] Failed to parse project-state.json"
    Write-Host $_
    Write-Host ""
    exit 1
}

# -----------------------------
# OPERATIONAL OUTPUT
# -----------------------------
Clear-Host

Write-Host ""
Write-Host "=================================================="
Write-Host "AI-Automation-OS :: RESUME ENGINE"
Write-Host "=================================================="

Write-Host ""
Write-Host "PROJECT"
Write-Host "--------------------------------------------------"
Write-Host "Name            : $($state.project)"
Write-Host "Phase           : $($state.phase)"
Write-Host "Phase Name      : $($state.phase_name)"

Write-Host ""
Write-Host "CURRENT EXECUTION STATE"
Write-Host "--------------------------------------------------"
Write-Host "Current Task    : $($state.current_task)"
Write-Host "Next Task       : $($state.next_task)"
Write-Host "Last Checkpoint : $($state.last_checkpoint)"

Write-Host ""
Write-Host "WORKFLOW SUMMARY"
Write-Host "--------------------------------------------------"
Write-Host "$($state.workflow_summary)"

Write-Host ""
Write-Host "ARCHITECTURE FOCUS"
Write-Host "--------------------------------------------------"

foreach ($item in $state.architecture_focus) {
    Write-Host "- $item"
}

Write-Host ""
Write-Host "IMPORTANT FILES"
Write-Host "--------------------------------------------------"

foreach ($file in $state.important_files) {
    Write-Host "- $file"
}

Write-Host ""
Write-Host "KNOWN ISSUES"
Write-Host "--------------------------------------------------"

if ($state.known_issues.Count -eq 0) {
    Write-Host "No known issues"
}
else {
    foreach ($issue in $state.known_issues) {
        Write-Host "- $issue"
    }
}

Write-Host ""
Write-Host "AI-READY COMPRESSED CONTEXT"
Write-Host "--------------------------------------------------"
Write-Host "$($state.compressed_context)"

Write-Host ""
Write-Host "STATUS"
Write-Host "--------------------------------------------------"
Write-Host "Workflow continuity restored successfully"

Write-Host ""
Write-Host "=================================================="
Write-Host ""
