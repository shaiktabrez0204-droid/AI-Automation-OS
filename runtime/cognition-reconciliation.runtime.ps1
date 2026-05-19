param(
    [string]$RuntimeRoot = ".\runtime",
    [string]$SemanticRoot = ".\semantic-cognition\runtime-semantics",
    [string]$LineageRoot = ".\engineering-lineage\runtime-lineage",
    [string]$IntentRoot = ".\execution-intelligence\execution-intent",
    [string]$OutputRoot = ".\cognition-reconciliation"
)

$ErrorActionPreference = "Stop"

function Get-LatestFile {
    param([string]$Root)

    Get-ChildItem `
        -Path $Root `
        -Filter "*.json" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

function Get-RuntimeInventory {
    param([string]$Root)

    Get-ChildItem `
        -Path $Root `
        -Recurse `
        -File `
        -Include "*.ps1","*.psm1" |
    Select-Object -ExpandProperty Name
}

function Build-ReconciliationState {
    param(
        [array]$RuntimeInventory,
        [array]$SemanticIndex,
        [array]$Lineage,
        [array]$Intent
    )

    $records = @()

    foreach ($runtime in $RuntimeInventory) {

        $semanticExists = (
            $SemanticIndex |
            Where-Object {
                $_.Runtime -eq $runtime
            }
        ).Count -gt 0

        $lineageExists = (
            $Lineage |
            Where-Object {
                $_.Runtime -eq $runtime
            }
        ).Count -gt 0

        $intentExists = (
            $Intent |
            Where-Object {
                $_.Runtime -eq $runtime
            }
        ).Count -gt 0

        $reconciliationState = "SYNCHRONIZED"

        if (
            (-not $semanticExists) -or
            (-not $lineageExists) -or
            (-not $intentExists)
        ) {
            $reconciliationState = "DIVERGED"
        }

        $repairActions = @()

        if (-not $semanticExists) {
            $repairActions += "REBUILD_SEMANTIC_INDEX"
        }

        if (-not $lineageExists) {
            $repairActions += "REBUILD_LINEAGE"
        }

        if (-not $intentExists) {
            $repairActions += "REBUILD_INTENT"
        }

        $records += [PSCustomObject]@{
            Runtime = $runtime
            SemanticIndexed = $semanticExists
            LineageIndexed = $lineageExists
            IntentIndexed = $intentExists
            ReconciliationState = $reconciliationState
            RepairActions = $repairActions
            ReconciledAt = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $records
}

Write-Host ""
Write-Host "======================================="
Write-Host "DISTRIBUTED COGNITION RECONCILIATION"
Write-Host "======================================="
Write-Host ""

$semanticFile = Get-LatestFile `
    -Root $SemanticRoot

$lineageFile = Get-LatestFile `
    -Root $LineageRoot

$intentFile = Get-LatestFile `
    -Root $IntentRoot

$semantic = Get-Content `
    $semanticFile.FullName `
    -Raw |
ConvertFrom-Json

$lineage = Get-Content `
    $lineageFile.FullName `
    -Raw |
ConvertFrom-Json

$intent = Get-Content `
    $intentFile.FullName `
    -Raw |
ConvertFrom-Json

$runtimes = Get-RuntimeInventory `
    -Root $RuntimeRoot

Write-Host "[runtime-inventory] $($runtimes.Count)"
Write-Host "[semantic-records] $($semantic.Count)"
Write-Host "[lineage-records] $($lineage.Count)"
Write-Host "[intent-records] $($intent.Count)"

$reconciliation = Build-ReconciliationState `
    -RuntimeInventory $runtimes `
    -SemanticIndex $semantic `
    -Lineage $lineage `
    -Intent $intent

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "distributed-consistency\cognition-reconciliation-$timestamp.json"

$reconciliation |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[cognition-reconciliation-written] $outputFile"
Write-Host ""
