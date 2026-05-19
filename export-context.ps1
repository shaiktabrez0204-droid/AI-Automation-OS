$ErrorActionPreference = "Stop"

# =========================================================
# AI-Automation-OS
# AI Context Export Engine
# =========================================================

$STATE_PATH = ".\state\project-state.json"
$EXPORT_DIR = ".\state"

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

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$context = @"
AI-Automation-OS :: OPERATIONAL CONTEXT EXPORT
==============================================

PROJECT
-------
Name        : $($state.project)
Phase       : $($state.phase)
Phase Name  : $($state.phase_name)

CURRENT STATE
-------------
Current Task : $($state.current_task)
Next Task    : $($state.next_task)

WORKFLOW SUMMARY
----------------
$($state.workflow_summary)

ARCHITECTURE FOCUS
------------------
$($state.architecture_focus -join "`n")

IMPORTANT FILES
---------------
$($state.important_files -join "`n")

KNOWN ISSUES
------------
$($state.known_issues -join "`n")

CONSTRAINTS
-----------
$($state.constraints -join "`n")

LAST CHECKPOINT
---------------
$($state.last_checkpoint)

SYSTEM IDENTITY
---------------
Persistent execution continuity infrastructure
for AI-native engineering workflows.

PRIMARY GOAL
-------------
Restore workflow continuity instantly with
minimal context rebuilding and token usage.
"@

$exportFile = "$EXPORT_DIR\ai-context-export.txt"

$context | Set-Content $exportFile

Clear-Host

Write-Host ""
Write-Host "=================================================="
Write-Host "AI CONTEXT EXPORT GENERATED"
Write-Host "=================================================="
Write-Host ""
Write-Host "Export File:"
Write-Host "$exportFile"
Write-Host ""
Write-Host "STATUS: READY FOR AI INGESTION"
Write-Host ""
Write-Host "=================================================="
Write-Host ""
