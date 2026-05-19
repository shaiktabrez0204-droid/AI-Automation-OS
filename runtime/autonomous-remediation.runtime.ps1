param(
    [string]$ContinuityRoot = ".\continuity-intelligence\survivability-analysis",
    [string]$ReconciliationRoot = ".\cognition-reconciliation\distributed-consistency",
    [string]$OutputRoot = ".\autonomous-remediation"
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

function Build-RemediationPlan {
    param(
        [object]$Continuity,
        [array]$Reconciliation
    )

    $actions = @()

    $diverged = (
        $Reconciliation |
        Where-Object {
            $_.ReconciliationState -eq "DIVERGED"
        }
    )

    foreach ($runtime in $diverged) {

        $repairPlan = @()

        foreach ($action in $runtime.RepairActions) {

            switch ($action) {

                "REBUILD_SEMANTIC_INDEX" {
                    $repairPlan +=
                    "EXECUTE_SEMANTIC_REINDEX"
                }

                "REBUILD_LINEAGE" {
                    $repairPlan +=
                    "EXECUTE_LINEAGE_RECONSTRUCTION"
                }

                "REBUILD_INTENT" {
                    $repairPlan +=
                    "EXECUTE_INTENT_RECONSTRUCTION"
                }
            }
        }

        $priority = "NORMAL"

        if ($Continuity.ContinuityState -eq "FRAGILE") {
            $priority = "CRITICAL"
        }
        elseif ($Continuity.ContinuityState -eq "DEGRADED") {
            $priority = "HIGH"
        }

        $actions += [PSCustomObject]@{
            Runtime = $runtime.Runtime
            DivergenceState = $runtime.ReconciliationState
            RepairPlan = $repairPlan
            SurvivabilityPriority = $priority
            GeneratedAt = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $actions
}

Write-Host ""
Write-Host "======================================="
Write-Host "AUTONOMOUS REMEDIATION COGNITION"
Write-Host "======================================="
Write-Host ""

$continuityFile = Get-LatestFile `
    -Root $ContinuityRoot

$reconciliationFile = Get-LatestFile `
    -Root $ReconciliationRoot

$continuity = Get-Content `
    $continuityFile.FullName `
    -Raw |
ConvertFrom-Json

$reconciliation = Get-Content `
    $reconciliationFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[continuity-state] $($continuity.ContinuityState)"
Write-Host "[reconciliation-records] $($reconciliation.Count)"

$remediation = Build-RemediationPlan `
    -Continuity $continuity `
    -Reconciliation $reconciliation

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "remediation-plans\autonomous-remediation-$timestamp.json"

$remediation |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[autonomous-remediation-written] $outputFile"
Write-Host ""
