$ErrorActionPreference = "Stop"

# =========================================================
# AI-Automation-OS
# Checkpoint Integrity Validation Engine
# =========================================================

$CHECKPOINT_DIR = ".\checkpoints"

if (!(Test-Path $CHECKPOINT_DIR)) {
    Write-Host ""
    Write-Host "[ERROR] Checkpoints directory not found"
    Write-Host ""
    exit 1
}

$checkpointFiles = Get-ChildItem $CHECKPOINT_DIR -Filter "*.json"

if ($checkpointFiles.Count -eq 0) {
    Write-Host ""
    Write-Host "[ERROR] No checkpoint files found"
    Write-Host ""
    exit 1
}

Clear-Host

Write-Host ""
Write-Host "=================================================="
Write-Host "CHECKPOINT INTEGRITY VALIDATION"
Write-Host "=================================================="
Write-Host ""

$validCount = 0
$invalidCount = 0

foreach ($file in $checkpointFiles) {

    try {
        $content = Get-Content $file.FullName -Raw | ConvertFrom-Json

        $requiredFields = @(
            "project",
            "phase",
            "current_task",
            "next_task",
            "last_checkpoint"
        )

        $missingFields = @()

        foreach ($field in $requiredFields) {
            if (-not $content.$field) {
                $missingFields += $field
            }
        }

        if ($missingFields.Count -eq 0) {
            Write-Host "[VALID]   $($file.Name)"
            $validCount++
        }
        else {
            Write-Host "[INVALID] $($file.Name)"
            Write-Host "Missing Fields: $($missingFields -join ', ')"
            $invalidCount++
        }
    }
    catch {
        Write-Host "[CORRUPTED] $($file.Name)"
        $invalidCount++
    }
}

Write-Host ""
Write-Host "=================================================="
Write-Host "VALIDATION SUMMARY"
Write-Host "=================================================="
Write-Host ""
Write-Host "Valid Checkpoints   : $validCount"
Write-Host "Invalid Checkpoints : $invalidCount"
Write-Host ""
Write-Host "=================================================="
Write-Host ""
