$ErrorActionPreference = "Stop"

# =========================================================
# AI-Automation-OS
# Context Compression Engine
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
# HISTORY COMPRESSION
# -----------------------------
$recentHistory = @()

if ($state.execution_history.Count -gt 5) {
    $recentHistory = $state.execution_history[-5..-1]
}
else {
    $recentHistory = $state.execution_history
}

# -----------------------------
# COMPRESSED EXECUTION SUMMARY
# -----------------------------
$historySummary = ""

foreach ($entry in $recentHistory) {

    $historySummary += @"

[$($entry.timestamp)]
Task      : $($entry.current_task)
Next Task : $($entry.next_task)

"@
}

# -----------------------------
# GENERATE NEW CONTEXT
# -----------------------------
$compressedContext = @"
CURRENT PROJECT STATE
---------------------
Project      : $($state.project)
Phase        : $($state.phase)

ACTIVE EXECUTION
---------------------
Current Task : $($state.current_task)
Next Task    : $($state.next_task)

RECENT EXECUTION HISTORY
---------------------
$historySummary

ARCHITECTURE FOCUS
---------------------
$($state.architecture_focus -join "`n")

LAST CHECKPOINT
---------------------
$($state.last_checkpoint)
"@

$state.compressed_context = $compressedContext

# -----------------------------
# SAVE UPDATED STATE
# -----------------------------
$state | ConvertTo-Json -Depth 20 | Set-Content $STATE_PATH

Clear-Host

Write-Host ""
Write-Host "=================================================="
Write-Host "CONTEXT COMPRESSION COMPLETE"
Write-Host "=================================================="
Write-Host ""
Write-Host "Execution history compressed successfully"
Write-Host ""
Write-Host "Recent history window : 5 entries"
Write-Host ""
Write-Host "STATUS: OPERATIONAL CONTEXT OPTIMIZED"
Write-Host ""
Write-Host "=================================================="
Write-Host ""
