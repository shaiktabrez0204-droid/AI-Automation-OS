$ErrorActionPreference = "Stop"

# =========================================================
# AI-Automation-OS
# Deterministic State Fingerprint Engine
# =========================================================

$STATE_PATH = ".\state\project-state.json"

if (!(Test-Path $STATE_PATH)) {

    Write-Host ""
    Write-Host "[ERROR] project-state.json not found"
    Write-Host ""

    exit 1
}

try {
    $rawState = Get-Content $STATE_PATH -Raw
}
catch {

    Write-Host ""
    Write-Host "[ERROR] Failed to load state"
    Write-Host ""

    exit 1
}

# -----------------------------
# SHA256 HASH GENERATION
# -----------------------------
$sha256 = [System.Security.Cryptography.SHA256]::Create()

$bytes = [System.Text.Encoding]::UTF8.GetBytes($rawState)

$hashBytes = $sha256.ComputeHash($bytes)

$hash = [BitConverter]::ToString($hashBytes) -replace "-", ""

Clear-Host

Write-Host ""
Write-Host "=================================================="
Write-Host "DETERMINISTIC STATE FINGERPRINT"
Write-Host "=================================================="

Write-Host ""
Write-Host "STATE FILE"
Write-Host "--------------------------------------------------"
Write-Host "$STATE_PATH"

Write-Host ""
Write-Host "SHA256 FINGERPRINT"
Write-Host "--------------------------------------------------"
Write-Host "$hash"

Write-Host ""
Write-Host "STATUS"
Write-Host "--------------------------------------------------"
Write-Host "Deterministic state identity generated"

Write-Host ""
Write-Host "=================================================="
Write-Host ""
