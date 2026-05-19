param(
    [string]$CheckpointA,
    [string]$CheckpointB
)

$ErrorActionPreference = "Stop"

# =========================================================
# AI-Automation-OS
# Checkpoint Diff Engine
# =========================================================

$CHECKPOINT_DIR = ".\checkpoints"

if (-not $CheckpointA -or -not $CheckpointB) {

    Write-Host ""
    Write-Host "[ERROR] Two checkpoint files required"
    Write-Host ""

    exit 1
}

$pathA = "$CHECKPOINT_DIR\$CheckpointA"
$pathB = "$CHECKPOINT_DIR\$CheckpointB"

if (!(Test-Path $pathA)) {

    Write-Host ""
    Write-Host "[ERROR] Checkpoint A not found"
    Write-Host ""

    exit 1
}

if (!(Test-Path $pathB)) {

    Write-Host ""
    Write-Host "[ERROR] Checkpoint B not found"
    Write-Host ""

    exit 1
}

try {
    $stateA = Get-Content $pathA -Raw | ConvertFrom-Json
    $stateB = Get-Content $pathB -Raw | ConvertFrom-Json
}
catch {

    Write-Host ""
    Write-Host "[ERROR] Failed to parse checkpoints"
    Write-Host ""

    exit 1
}

Clear-Host

Write-Host ""
Write-Host "=================================================="
Write-Host "CHECKPOINT DIFFERENCE ANALYSIS"
Write-Host "=================================================="

Write-Host ""
Write-Host "CHECKPOINT A"
Write-Host "--------------------------------------------------"
Write-Host "$CheckpointA"

Write-Host ""
Write-Host "CHECKPOINT B"
Write-Host "--------------------------------------------------"
Write-Host "$CheckpointB"

Write-Host ""
Write-Host "OPERATIONAL DIFFERENCES"
Write-Host "--------------------------------------------------"

$changesDetected = $false

if ($stateA.current_task -ne $stateB.current_task) {

    Write-Host ""
    Write-Host "[CURRENT TASK]"
    Write-Host "A: $($stateA.current_task)"
    Write-Host "B: $($stateB.current_task)"

    $changesDetected = $true
}

if ($stateA.next_task -ne $stateB.next_task) {

    Write-Host ""
    Write-Host "[NEXT TASK]"
    Write-Host "A: $($stateA.next_task)"
    Write-Host "B: $($stateB.next_task)"

    $changesDetected = $true
}

if ($stateA.last_checkpoint -ne $stateB.last_checkpoint) {

    Write-Host ""
    Write-Host "[CHECKPOINT]"
    Write-Host "A: $($stateA.last_checkpoint)"
    Write-Host "B: $($stateB.last_checkpoint)"

    $changesDetected = $true
}

if (-not $changesDetected) {

    Write-Host ""
    Write-Host "No operational differences detected"
}

Write-Host ""
Write-Host "STATUS"
Write-Host "--------------------------------------------------"
Write-Host "Checkpoint diff analysis completed"

Write-Host ""
Write-Host "=================================================="
Write-Host ""
