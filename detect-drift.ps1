$ErrorActionPreference = "Stop"

# =========================================================
# AI-Automation-OS
# Operational Drift Detection Engine
# =========================================================

$STATE_PATH = ".\state\project-state.json"
$CHECKPOINT_DIR = ".\checkpoints"

if (!(Test-Path $STATE_PATH)) {

    Write-Host ""
    Write-Host "[ERROR] project-state.json not found"
    Write-Host ""

    exit 1
}

$latestCheckpoint = Get-ChildItem $CHECKPOINT_DIR `
| Sort-Object LastWriteTime -Descending `
| Select-Object -First 1

if (-not $latestCheckpoint) {

    Write-Host ""
    Write-Host "[ERROR] No checkpoints found"
    Write-Host ""

    exit 1
}

try {
    $liveState = Get-Content $STATE_PATH -Raw | ConvertFrom-Json
    $checkpointState = Get-Content $latestCheckpoint.FullName -Raw | ConvertFrom-Json
}
catch {

    Write-Host ""
    Write-Host "[ERROR] Failed to parse state"
    Write-Host ""

    exit 1
}

Clear-Host

Write-Host ""
Write-Host "=================================================="
Write-Host "OPERATIONAL DRIFT DETECTION"
Write-Host "=================================================="

Write-Host ""
Write-Host "LATEST CHECKPOINT"
Write-Host "--------------------------------------------------"
Write-Host "$($latestCheckpoint.Name)"

Write-Host ""
Write-Host "DRIFT ANALYSIS"
Write-Host "--------------------------------------------------"

$driftDetected = $false

if ($liveState.current_task -ne $checkpointState.current_task) {

    Write-Host "[DRIFT] Current Task mismatch"

    $driftDetected = $true
}

if ($liveState.next_task -ne $checkpointState.next_task) {

    Write-Host "[DRIFT] Next Task mismatch"

    $driftDetected = $true
}

if (
    ($liveState.architecture_focus -join ",") -ne
    ($checkpointState.architecture_focus -join ",")
) {

    Write-Host "[DRIFT] Architecture focus mismatch"

    $driftDetected = $true
}

if (-not $driftDetected) {

    Write-Host "No operational drift detected"
}

Write-Host ""
Write-Host "STATUS"
Write-Host "--------------------------------------------------"

if ($driftDetected) {
    Write-Host "Operational drift detected"
}
else {
    Write-Host "Operational continuity aligned"
}

Write-Host ""
Write-Host "=================================================="
Write-Host ""
