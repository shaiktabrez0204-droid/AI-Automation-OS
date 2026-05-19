param(
    [string]$OptimizationRoot = ".\recursive-topology-optimization\optimization-strategies",
    [string]$SimulationRoot = ".\evolutionary-simulation-intelligence\future-state-models",
    [string]$OutputRoot = ".\mutation-rollback-intelligence"
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

function Build-RollbackStrategies {
    param(
        [array]$Optimization,
        [array]$Simulation
    )

    $rollbackPlans = @()

    foreach ($runtime in $Optimization) {

        $simulation = $Simulation |
        Where-Object {
            $_.Runtime -eq $runtime.Runtime
        } |
        Select-Object -First 1

        $rollbackRequired = $false

        if (
            $runtime.OptimizationStrategy -eq
            "ROLLBACK_MUTATION"
        ) {
            $rollbackRequired = $true
        }

        if (
            $simulation.GovernanceValidation -eq
            "REJECTED"
        ) {
            $rollbackRequired = $true
        }

        $rollbackStrategy = "NO_ACTION"

        if ($rollbackRequired) {

            switch ($runtime.MutationRisk) {

                "HIGH" {
                    $rollbackStrategy =
                    "FULL_TOPOLOGY_RESTORE"
                }

                "MODERATE" {
                    $rollbackStrategy =
                    "PARTIAL_COORDINATION_RESTORE"
                }

                default {
                    $rollbackStrategy =
                    "RUNTIME_STATE_RESET"
                }
            }
        }

        $recoveryPriority = "NORMAL"

        if (
            $runtime.EvolutionScore -lt 40
        ) {
            $recoveryPriority = "HIGH"
        }

        if (
            $runtime.EvolutionScore -lt 20
        ) {
            $recoveryPriority = "CRITICAL"
        }

        $rollbackPlans += [PSCustomObject]@{
            Runtime = $runtime.Runtime
            RollbackRequired = $rollbackRequired
            RollbackStrategy = $rollbackStrategy
            RecoveryPriority = $recoveryPriority
            MutationRisk = $runtime.MutationRisk
            EvolutionScore = $runtime.EvolutionScore
            RecoveryGeneratedAt = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $rollbackPlans
}

Write-Host ""
Write-Host "======================================="
Write-Host "MUTATION ROLLBACK INTELLIGENCE"
Write-Host "======================================="
Write-Host ""

$optimizationFile = Get-LatestFile `
    -Root $OptimizationRoot

$simulationFile = Get-LatestFile `
    -Root $SimulationRoot

$optimization = Get-Content `
    $optimizationFile.FullName `
    -Raw |
ConvertFrom-Json

$simulation = Get-Content `
    $simulationFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[optimization-records] $($optimization.Count)"
Write-Host "[simulation-records] $($simulation.Count)"

$rollback =
Build-RollbackStrategies `
    -Optimization $optimization `
    -Simulation $simulation

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "rollback-strategies\mutation-rollback-$timestamp.json"

$rollback |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[mutation-rollback-written] $outputFile"
Write-Host ""
