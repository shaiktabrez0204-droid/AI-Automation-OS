param(
    [string]$CurrentTask,
    [string]$NextTask
)

$ErrorActionPreference = "Stop"

Clear-Host

Write-Host ""
Write-Host "=================================================="
Write-Host "AI-Automation-OS :: WORKFLOW CONTINUITY PIPELINE"
Write-Host "=================================================="
Write-Host ""

# -----------------------------
# STATE UPDATE
# -----------------------------
Write-Host "[1/4] Updating operational state..."
.\update-state.ps1 `
-CurrentTask $CurrentTask `
-NextTask $NextTask

# -----------------------------
# CHECKPOINT
# -----------------------------
Write-Host "[2/4] Creating checkpoint..."
.\checkpoint.ps1

# -----------------------------
# CONTEXT COMPRESSION
# -----------------------------
Write-Host "[3/4] Compressing execution history..."
.\compress-history.ps1

# -----------------------------
# CONTEXT EXPORT
# -----------------------------
Write-Host "[4/4] Exporting AI operational context..."
.\export-context.ps1

Write-Host ""
Write-Host "=================================================="
Write-Host "WORKFLOW CONTINUITY CYCLE COMPLETE"
Write-Host "=================================================="
Write-Host ""
Write-Host "STATUS:"
Write-Host "- operational state updated"
Write-Host "- checkpoint created"
Write-Host "- history compressed"
Write-Host "- AI context exported"
Write-Host ""
Write-Host "SYSTEM READY FOR INTERRUPTION + RESUME"
Write-Host ""
Write-Host "=================================================="
Write-Host ""
