param(
    [string]$ExpansionRoot = ".\adaptive-execution-expansion\execution-scaling",
    [string]$RollbackRoot = ".\mutation-rollback-intelligence\rollback-strategies",
    [string]$OutputRoot = ".\topology-self-healing"
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

function Build-SelfHealingTopology {
    param(
        [array]$Expansion,
        [array]$Rollback
    )

    $healing = @()

    foreach ($runtime in $Expansion) {

        $rollbackRecord = $Rollback |
        Where-Object {
            $_.Runtime -eq $runtime.Runtime
        } |
        Select-Object -First 1

        $healingStrategy = "STABLE"

        if (
            $runtime.ExpansionStrategy -eq
            "LIMIT_EXECUTION_EXPANSION"
        ) {
            $healingStrategy =
            "COORDINATION_CONSTRAINT"
        }

        if (
            $rollbackRecord.RollbackRequired
        ) {
            $healingStrategy =
            "RUNTIME_RECOVERY"
        }

        $stabilityScore = 100

        $stabilityScore -= (
            [math]::Max(
                0,
                (100 - $runtime.GovernanceScore)
            )
        )

        if (
            $rollbackRecord.RecoveryPriority -eq
            "HIGH"
        ) {
            $stabilityScore -= 20
        }

        if (
            $rollbackRecord.RecoveryPriority -eq
            "CRITICAL"
        ) {
            $stabilityScore -= 40
        }

        if ($stabilityScore -lt 0) {
            $stabilityScore = 0
        }

        $healing += [PSCustomObject]@{
            Runtime = $runtime.Runtime
            HealingStrategy = $healingStrategy
            StabilityScore = $stabilityScore
            GovernanceScore = $runtime.GovernanceScore
            RollbackRequired = $rollbackRecord.RollbackRequired
            HealingGeneratedAt = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $healing
}

Write-Host ""
Write-Host "======================================="
Write-Host "TOPOLOGY SELF-HEALING"
Write-Host "======================================="
Write-Host ""

$expansionFile = Get-LatestFile `
    -Root $ExpansionRoot

$rollbackFile = Get-LatestFile `
    -Root $RollbackRoot

$expansion = Get-Content `
    $expansionFile.FullName `
    -Raw |
ConvertFrom-Json

$rollback = Get-Content `
    $rollbackFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[expansion-records] $($expansion.Count)"
Write-Host "[rollback-records] $($rollback.Count)"

$selfHealing =
Build-SelfHealingTopology `
    -Expansion $expansion `
    -Rollback $rollback

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "runtime-healing\topology-self-healing-$timestamp.json"

$selfHealing |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[topology-self-healing-written] $outputFile"
Write-Host ""
