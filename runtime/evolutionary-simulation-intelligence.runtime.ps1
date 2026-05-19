param(
    [string]$MutationRoot = ".\adaptive-infrastructure-evolution\topology-mutations",
    [string]$ContinuityRoot = ".\continuity-intelligence\survivability-analysis",
    [string]$OutputRoot = ".\evolutionary-simulation-intelligence"
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

function Simulate-EvolutionaryFuture {
    param(
        [array]$Mutations,
        [object]$Continuity
    )

    $results = @()

    foreach ($mutation in $Mutations) {

        $futureState = "STABLE"

        if (
            $mutation.MutationRisk -eq "MODERATE"
        ) {
            $futureState = "ELEVATED_RISK"
        }

        if (
            $mutation.MutationRisk -eq "HIGH"
        ) {
            $futureState = "UNSTABLE"
        }

        $governanceValidation = "APPROVED"

        if (
            ($mutation.MutationRisk -eq "HIGH") -and
            ($Continuity.ContinuityState -eq "FRAGILE")
        ) {
            $governanceValidation = "REJECTED"
        }

        $survivabilityScore = 100

        switch ($mutation.MutationRisk) {

            "LOW" {
                $survivabilityScore -= 10
            }

            "MODERATE" {
                $survivabilityScore -= 30
            }

            "HIGH" {
                $survivabilityScore -= 60
            }
        }

        if (
            $Continuity.ContinuityState -eq "FRAGILE"
        ) {
            $survivabilityScore -= 20
        }

        if ($survivabilityScore -lt 0) {
            $survivabilityScore = 0
        }

        $results += [PSCustomObject]@{
            Runtime = $mutation.Runtime
            MutationStrategy = $mutation.MutationStrategy
            MutationRisk = $mutation.MutationRisk
            SimulatedFutureState = $futureState
            GovernanceValidation = $governanceValidation
            SurvivabilityScore = $survivabilityScore
            SimulationTimestamp = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $results
}

Write-Host ""
Write-Host "======================================="
Write-Host "EVOLUTIONARY SIMULATION INTELLIGENCE"
Write-Host "======================================="
Write-Host ""

$mutationFile = Get-LatestFile `
    -Root $MutationRoot

$continuityFile = Get-LatestFile `
    -Root $ContinuityRoot

$mutations = Get-Content `
    $mutationFile.FullName `
    -Raw |
ConvertFrom-Json

$continuity = Get-Content `
    $continuityFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[mutation-records] $($mutations.Count)"
Write-Host "[continuity-state] $($continuity.ContinuityState)"

$simulation =
Simulate-EvolutionaryFuture `
    -Mutations $mutations `
    -Continuity $continuity

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "future-state-models\evolutionary-simulation-$timestamp.json"

$simulation |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[evolutionary-simulation-written] $outputFile"
Write-Host ""
