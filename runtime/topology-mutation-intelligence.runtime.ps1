param(
    [string]$DecisionRoot = ".\infrastructure-decision-intelligence\decision-analysis",
    [string]$ContinuityRoot = ".\continuity-intelligence\survivability-analysis",
    [string]$OutputRoot = ".\adaptive-infrastructure-evolution"
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

function Build-TopologyMutations {
    param(
        [array]$DecisionIntelligence,
        [object]$Continuity
    )

    $mutations = @()

    foreach ($runtime in $DecisionIntelligence) {

        $mutationStrategy = "NO_CHANGE"

        if (
            $runtime.DecisionPriority -eq "HIGH"
        ) {
            $mutationStrategy =
            "LIMIT_COORDINATION_SURFACE"
        }

        if (
            $runtime.DecisionPriority -eq "URGENT"
        ) {
            $mutationStrategy =
            "ISOLATE_RUNTIME_EXECUTION"
        }

        $survivabilityConstraint = "NORMAL"

        if (
            $Continuity.ContinuityState -eq "FRAGILE"
        ) {
            $survivabilityConstraint =
            "STRICT_GOVERNANCE"
        }

        $mutationRisk = "LOW"

        if (
            $runtime.BlastRadius -eq "MEDIUM"
        ) {
            $mutationRisk = "MODERATE"
        }

        if (
            $runtime.BlastRadius -eq "HIGH"
        ) {
            $mutationRisk = "HIGH"
        }

        $mutations += [PSCustomObject]@{
            Runtime = $runtime.Runtime
            MutationStrategy = $mutationStrategy
            SurvivabilityConstraint = $survivabilityConstraint
            MutationRisk = $mutationRisk
            CoordinationStrategy = $runtime.CoordinationStrategy
            EvolutionPriority = $runtime.DecisionPriority
            MutationGeneratedAt = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $mutations
}

Write-Host ""
Write-Host "======================================="
Write-Host "TOPOLOGY MUTATION INTELLIGENCE"
Write-Host "======================================="
Write-Host ""

$decisionFile = Get-LatestFile `
    -Root $DecisionRoot

$continuityFile = Get-LatestFile `
    -Root $ContinuityRoot

$decision = Get-Content `
    $decisionFile.FullName `
    -Raw |
ConvertFrom-Json

$continuity = Get-Content `
    $continuityFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[decision-records] $($decision.Count)"
Write-Host "[continuity-state] $($continuity.ContinuityState)"

$mutations =
Build-TopologyMutations `
    -DecisionIntelligence $decision `
    -Continuity $continuity

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "topology-mutations\topology-mutations-$timestamp.json"

$mutations |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[topology-mutations-written] $outputFile"
Write-Host ""
