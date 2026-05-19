param(
    [string]$OptimizationRoot = ".\recursive-topology-optimization\optimization-strategies",
    [string]$FeedbackRoot = ".\recursive-governance-feedback\feedback-loops",
    [string]$OutputRoot = ".\adaptive-execution-expansion"
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

function Build-AdaptiveExpansion {
    param(
        [array]$Optimization,
        [array]$Feedback
    )

    $results = @()

    foreach ($runtime in $Optimization) {

        $feedbackRecord = $Feedback |
        Where-Object {
            $_.Runtime -eq $runtime.Runtime
        } |
        Select-Object -First 1

        $expansionStrategy = "MAINTAIN"

        if (
            $runtime.OptimizationStrategy -eq
            "EXPAND_ADAPTIVE_EXECUTION"
        ) {
            $expansionStrategy =
            "EXPAND_RUNTIME_COORDINATION"
        }

        if (
            $feedbackRecord.PolicyAdaptation -eq
            "ENABLE_STRICT_SURVIVABILITY_MODE"
        ) {
            $expansionStrategy =
            "LIMIT_EXECUTION_EXPANSION"
        }

        $scalingFactor = 1

        if (
            $runtime.EvolutionScore -ge 80
        ) {
            $scalingFactor = 3
        }
        elseif (
            $runtime.EvolutionScore -ge 50
        ) {
            $scalingFactor = 2
        }

        $results += [PSCustomObject]@{
            Runtime = $runtime.Runtime
            ExpansionStrategy = $expansionStrategy
            ScalingFactor = $scalingFactor
            GovernanceScore = $feedbackRecord.GovernanceScore
            EvolutionScore = $runtime.EvolutionScore
            ExpansionGeneratedAt = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $results
}

Write-Host ""
Write-Host "======================================="
Write-Host "ADAPTIVE EXECUTION EXPANSION"
Write-Host "======================================="
Write-Host ""

$optimizationFile = Get-LatestFile `
    -Root $OptimizationRoot

$feedbackFile = Get-LatestFile `
    -Root $FeedbackRoot

$optimization = Get-Content `
    $optimizationFile.FullName `
    -Raw |
ConvertFrom-Json

$feedback = Get-Content `
    $feedbackFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[optimization-records] $($optimization.Count)"
Write-Host "[feedback-records] $($feedback.Count)"

$expansion =
Build-AdaptiveExpansion `
    -Optimization $optimization `
    -Feedback $feedback

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "execution-scaling\adaptive-expansion-$timestamp.json"

$expansion |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[adaptive-expansion-written] $outputFile"
Write-Host ""
