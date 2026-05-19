$ErrorActionPreference = "Stop"

# =========================================================
# AI-Automation-OS
# Universal Persistent Execution State Layer
# Checkpoint Engine
# =========================================================

# -----------------------------
# PATH CONFIGURATION
# -----------------------------
$STATE_PATH = ".\state\project-state.json"
$CHECKPOINT_DIR = ".\checkpoints"
$LOGS_DIR = ".\logs"
$SNAPSHOT_DIR = ".\snapshots"
$WORKFLOW_LOG = "$LOGS_DIR\workflow-history.log"

# -----------------------------
# DIRECTORY VALIDATION
# -----------------------------
$requiredDirectories = @(
    $CHECKPOINT_DIR,
    $LOGS_DIR,
    $SNAPSHOT_DIR
)

foreach ($directory in $requiredDirectories) {
    if (!(Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory | Out-Null
    }
}

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
# TIMESTAMP GENERATION
# -----------------------------
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# -----------------------------
# CHECKPOINT METADATA
# -----------------------------
$checkpointId = "checkpoint-$timestamp"

$checkpointMetadata = @{
    checkpoint_id = $checkpointId
    timestamp = $timestamp
    phase = $state.phase
    current_task = $state.current_task
    next_task = $state.next_task
    architecture_focus = $state.architecture_focus
}

# -----------------------------
# UPDATE STATE
# -----------------------------
$state.last_checkpoint = $timestamp

if (-not $state.execution_history) {
    $state | Add-Member -MemberType NoteProperty -Name execution_history -Value @()
}

$state.execution_history += $checkpointMetadata

# -----------------------------
# CONTEXT COMPRESSION
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
$timestamp
"@

$state | Add-Member -Force -MemberType NoteProperty -Name compressed_context -Value $compressedSummary

# -----------------------------
# CHECKPOINT FILES
# -----------------------------
$checkpointFile = "$CHECKPOINT_DIR\$checkpointId.json"
$snapshotFile = "$SNAPSHOT_DIR\snapshot-$timestamp.json"

$state | ConvertTo-Json -Depth 20 | Set-Content $STATE_PATH
$state | ConvertTo-Json -Depth 20 | Set-Content $checkpointFile
$state | ConvertTo-Json -Depth 20 | Set-Content $snapshotFile

# -----------------------------
# WORKFLOW LOGGING
# -----------------------------
$logEntry = "[${timestamp}] CHECKPOINT_CREATED | Phase=$($state.phase) | Task=$($state.current_task)"

Add-Content $WORKFLOW_LOG $logEntry

# -----------------------------
# OPERATIONAL OUTPUT
# -----------------------------
Clear-Host

Write-Host ""
Write-Host "=================================================="
Write-Host "AI-Automation-OS :: CHECKPOINT ENGINE"
Write-Host "=================================================="
Write-Host ""
Write-Host "Checkpoint ID  : $checkpointId"
Write-Host "Timestamp      : $timestamp"
Write-Host "Phase          : $($state.phase)"
Write-Host "Current Task   : $($state.current_task)"
Write-Host "Next Task      : $($state.next_task)"
Write-Host ""
Write-Host "Checkpoint File:"
Write-Host "$checkpointFile"
Write-Host ""
Write-Host "Snapshot File:"
Write-Host "$snapshotFile"
Write-Host ""
Write-Host "Workflow Log:"
Write-Host "$WORKFLOW_LOG"
Write-Host ""
Write-Host "STATUS: CHECKPOINT SUCCESSFUL"
Write-Host ""
Write-Host "=================================================="
Write-Host ""
