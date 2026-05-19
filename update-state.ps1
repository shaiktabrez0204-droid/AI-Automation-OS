param(
    [string]$CurrentTask,
    [string]$NextTask
)

$ErrorActionPreference = "Stop"

# =========================================================
# AI-Automation-OS
# Operational State Update Engine
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
# UPDATE STATE
# -----------------------------
if ($CurrentTask) {
    $state.current_task = $CurrentTask
}

if ($NextTask) {
    $state.next_task = $NextTask
}

# -----------------------------
# REGENERATE COMPRESSED CONTEXT
# -----------------------------
$compressedSummary = @"
CURRENT PROJECT STATE
---------------------
Project      : $($state.project)
Phase        : $($state.phase)
Current Task : $($state.current_task)
Next Task    : $($state.next_task)

ARCHITECTURE FOCUS
---------------------
$($state.architecture_focus -join "`n")

KNOWN ISSUES
---------------------
$($state.known_issues -join "`n")

LAST CHECKPOINT
---------------------
$($state.last_checkpoint)
"@

$state.compressed_context = $compressedSummary

# -----------------------------
# SAVE STATE
# -----------------------------
$state | ConvertTo-Json -Depth 20 | Set-Content $STATE_PATH

Clear-Host

Write-Host ""
Write-Host "=================================================="
Write-Host "STATE UPDATE SUCCESSFUL"
Write-Host "=================================================="
Write-Host ""
Write-Host "Current Task : $($state.current_task)"
Write-Host "Next Task    : $($state.next_task)"
Write-Host ""
Write-Host "Compressed operational context regenerated"
Write-Host ""
Write-Host "=================================================="
Write-Host ""
