param(
    [string]$CheckpointFile
)

$ErrorActionPreference = "Stop"

# =========================================================
# AI-Automation-OS
# Safe Replay Preview Engine
# =========================================================

$CHECKPOINT_DIR = ".\checkpoints"
$STATE_PATH = ".\state\project-state.json"

if (-not $CheckpointFile) {

    Write-Host ""
    Write-Host "[ERROR] Missing checkpoint filename"
    Write-Host ""

    exit 1
}

$checkpointPath = "$CHECKPOINT_DIR\$CheckpointFile"

if (!(Test-Path $checkpointPath)) {

    Write-Host ""
    Write-Host "[ERROR] Checkpoint not found"
    Write-Host "$checkpointPath"
    Write-Host ""

    exit 1
}

try {
    $liveState = Get-Content $STATE_PATH -Raw | ConvertFrom-Json
    $checkpointState = Get-Content $checkpointPath -Raw | ConvertFrom-Json
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
Write-Host "SAFE CHECKPOINT PREVIEW"
Write-Host "=================================================="

Write-Host ""
Write-Host "CHECKPOINT FILE"
Write-Host "--------------------------------------------------"
Write-Host "$CheckpointFile"

Write-Host ""
Write-Host "LIVE STATE"
Write-Host "--------------------------------------------------"
Write-Host "Current Task : $($liveState.current_task)"
Write-Host "Next Task    : $($liveState.next_task)"
Write-Host "Checkpoint   : $($liveState.last_checkpoint)"

Write-Host ""
Write-Host "CHECKPOINT STATE"
Write-Host "--------------------------------------------------"
Write-Host "Current Task : $($checkpointState.current_task)"
Write-Host "Next Task    : $($checkpointState.next_task)"
Write-Host "Checkpoint   : $($checkpointState.last_checkpoint)"

Write-Host ""
Write-Host "STATE DIFFERENCES"
Write-Host "--------------------------------------------------"

if ($liveState.current_task -ne $checkpointState.current_task) {
    Write-Host "[CHANGED] Current Task"
}

if ($liveState.next_task -ne $checkpointState.next_task) {
    Write-Host "[CHANGED] Next Task"
}

if ($liveState.last_checkpoint -ne $checkpointState.last_checkpoint) {
    Write-Host "[CHANGED] Last Checkpoint"
}

Write-Host ""
Write-Host "STATUS"
Write-Host "--------------------------------------------------"
Write-Host "Checkpoint preview completed safely"

Write-Host ""
Write-Host "=================================================="
Write-Host ""
