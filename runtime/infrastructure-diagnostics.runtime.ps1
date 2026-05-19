param(
    [string]$TopologyRoot = ".\repository-cognition\graph\topology",
    [string]$ExecutionRoot = ".\execution-planning",
    [string]$OutputRoot = ".\infrastructure-analysis"
)

$ErrorActionPreference = "Stop"

function Get-LatestFile {
    param([string]$Root)

    Get-ChildItem `
        -Path $Root `
        -Filter "*.json" `
        -Recurse |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

function Analyze-TopologyRisk {
    param(
        [array]$Topology,
        [array]$ExecutionPlan
    )

    $diagnostics = @()

    foreach ($runtime in $Topology) {

        $dependencyCount = 0

        if ($runtime.References) {
            $dependencyCount = $runtime.References.Count
        }

        $riskLevel = "LOW"

        if ($dependencyCount -ge 5) {
            $riskLevel = "MEDIUM"
        }

        if ($dependencyCount -ge 10) {
            $riskLevel = "HIGH"
        }

        $diagnostics += [PSCustomObject]@{
            Runtime = $runtime.Runtime
            DependencyCount = $dependencyCount
            RiskLevel = $riskLevel
            TopologyIntegrity = $true
            CoordinationSurface = (
                $dependencyCount * 5
            )
            DiagnosedAt = (Get-Date).ToUniversalTime()
        }
    }

    return $diagnostics
}

Write-Host ""
Write-Host "======================================="
Write-Host "INFRASTRUCTURE DIAGNOSTICS COGNITION"
Write-Host "======================================="
Write-Host ""

$topologyFile = Get-LatestFile `
    -Root $TopologyRoot

$executionFile = Get-LatestFile `
    -Root "$ExecutionRoot\orchestration-plans"

$topology = Get-Content `
    $topologyFile.FullName `
    -Raw |
ConvertFrom-Json

$executionPlan = Get-Content `
    $executionFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[topology-runtimes] $($topology.Count)"
Write-Host "[execution-plans] $($executionPlan.Count)"

$diagnostics = Analyze-TopologyRisk `
    -Topology $topology `
    -ExecutionPlan $executionPlan

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "diagnostics\infrastructure-diagnostics-$timestamp.json"

$diagnostics |
ConvertTo-Json -Depth 10 |
Set-Content $outputFile

Write-Host ""
Write-Host "[diagnostics-written] $outputFile"
Write-Host ""
