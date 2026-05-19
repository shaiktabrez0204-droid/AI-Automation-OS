param(
    [string]$CheckpointFile
)

$ErrorActionPreference = "Stop"

# =========================================================
# AI-Automation-OS
# Deterministic Replay Restore Engine
# =========================================================

$CHECKPOINT_DIR = ".\checkpoints"
$STATE_PATH = ".\state\project-state.json"

if (-not $CheckpointFile) {

    Write-Host ""
    Write-Host "[ERROR] Missing checkpoint filename"
    Write-Host ""
    Write-Host "Example:"
    Write-Host '.\restore-checkpoint.ps1 -CheckpointFile "checkpoint-2026-05-19_22-11-00.json"'
    Write-Host ""

    exit 1
}

$checkpointPath = "$CHECKPOINT_DIR\$CheckpointFile"

if (!(Test-Path $checkpointPath)) {

    Write-Host ""
    Write-Host "[ERROR] Checkpoint file not found"
    Write-Host "$checkpointPath"
    Write-Host ""

    exit 1
}

try {
    $checkpointState = Get-Content $checkpointPath -Raw | ConvertFrom-Json
}
catch {

    Write-Host ""
    Write-Host "[ERROR] Failed to parse checkpoint"
    Write-Host ""

    exit 1
}

# -----------------------------
# RESTORE STATE
# -----------------------------
$checkpointState | ConvertTo-Json -Depth 20 | Set-Content $STATE_PATH

Clear-Host

Write-Host ""
Write-Host "=================================================="
Write-Host "DETERMINISTIC CHECKPOINT RESTORE"
Write-Host "=================================================="
Write-Host ""

Write-Host "Restored Checkpoint:"
Write-Host "$CheckpointFile"

Write-Host ""
Write-Host "RESTORED EXECUTION STATE"
Write-Host "--------------------------------------------------"
Write-Host "Phase        : $($checkpointState.phase)"
Write-Host "Current Task : $($checkpointState.current_task)"
Write-Host "Next Task    : $($checkpointState.next_task)"
Write-Host "Checkpoint   : $($checkpointState.last_checkpoint)"

Write-Host ""
Write-Host "STATUS:"
Write-Host "Operational continuity restored successfully"

Write-Host ""
Write-Host "=================================================="
Write-Host ""
