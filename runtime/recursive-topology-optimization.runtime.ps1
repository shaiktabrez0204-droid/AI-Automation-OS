param(
    [string]$SimulationRoot = ".\evolutionary-simulation-intelligence\future-state-models",
    [string]$DecisionRoot = ".\infrastructure-decision-intelligence\decision-analysis",
    [string]$OutputRoot = ".\recursive-topology-optimization"
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

function Optimize-TopologyEvolution {
    param(
        [array]$Simulation,
        [array]$DecisionIntelligence
    )

    $results = @()

    foreach ($future in $Simulation) {

        $decision = $DecisionIntelligence |
        Where-Object {
            $_.Runtime -eq $future.Runtime
        } |
        Select-Object -First 1

        $optimizationStrategy = "MAINTAIN"

        if (
            $future.GovernanceValidation -eq "REJECTED"
        ) {
            $optimizationStrategy =
            "ROLLBACK_MUTATION"
        }

        elseif (
            $future.SurvivabilityScore -lt 50
        ) {
            $optimizationStrategy =
            "REDUCE_COORDINATION_SURFACE"
        }

        elseif (
            $future.SurvivabilityScore -ge 80
        ) {
            $optimizationStrategy =
            "EXPAND_ADAPTIVE_EXECUTION"
        }

        $governanceWeight = 1

        switch ($future.MutationRisk) {

            "LOW" {
                $governanceWeight = 1
            }

            "MODERATE" {
                $governanceWeight = 2
            }

            "HIGH" {
                $governanceWeight = 5
            }
        }

        $evolutionScore = (
            $future.SurvivabilityScore -
            ($governanceWeight * 10)
        )

        if ($evolutionScore -lt 0) {
            $evolutionScore = 0
        }

        $results += [PSCustomObject]@{
            Runtime = $future.Runtime
            OptimizationStrategy = $optimizationStrategy
            GovernanceWeight = $governanceWeight
            EvolutionScore = $evolutionScore
            MutationRisk = $future.MutationRisk
            SurvivabilityScore = $future.SurvivabilityScore
            CoordinationStrategy = $decision.CoordinationStrategy
            OptimizationTimestamp = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $results
}

Write-Host ""
Write-Host "======================================="
Write-Host "RECURSIVE TOPOLOGY OPTIMIZATION"
Write-Host "======================================="
Write-Host ""

$simulationFile = Get-LatestFile `
    -Root $SimulationRoot

$decisionFile = Get-LatestFile `
    -Root $DecisionRoot

$simulation = Get-Content `
    $simulationFile.FullName `
    -Raw |
ConvertFrom-Json

$decision = Get-Content `
    $decisionFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[simulation-records] $($simulation.Count)"
Write-Host "[decision-records] $($decision.Count)"

$optimization =
Optimize-TopologyEvolution `
    -Simulation $simulation `
    -DecisionIntelligence $decision

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "optimization-strategies\recursive-optimization-$timestamp.json"

$optimization |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[recursive-optimization-written] $outputFile"
Write-Host ""
