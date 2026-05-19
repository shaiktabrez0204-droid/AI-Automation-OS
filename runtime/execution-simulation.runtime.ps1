param(
    [string]$TopologyRoot = ".\repository-cognition\graph\topology",
    [string]$DiagnosticsRoot = ".\infrastructure-analysis\diagnostics",
    [string]$OutputRoot = ".\execution-simulation"
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

function Simulate-ExecutionTopology {
    param(
        [array]$Topology,
        [array]$Diagnostics
    )

    $simulations = @()

    foreach ($runtime in $Topology) {

        $dependencyCount = 0

        if ($runtime.References) {
            $dependencyCount = $runtime.References.Count
        }

        $cascadeRisk = "LOW"

        if ($dependencyCount -ge 3) {
            $cascadeRisk = "MEDIUM"
        }

        if ($dependencyCount -ge 7) {
            $cascadeRisk = "HIGH"
        }

        $executionSurvivability = "STABLE"

        if ($cascadeRisk -eq "HIGH") {
            $executionSurvivability = "FRAGILE"
        }
        elseif ($cascadeRisk -eq "MEDIUM") {
            $executionSurvivability = "MODERATE"
        }

        $projectedCoordinationCost = (
            ($dependencyCount + 1) * 12
        )

        $simulations += [PSCustomObject]@{
            Runtime = $runtime.Runtime
            DependencyCount = $dependencyCount
            CascadeRisk = $cascadeRisk
            ProjectedCoordinationCost = $projectedCoordinationCost
            ExecutionSurvivability = $executionSurvivability
            SimulatedAt = (Get-Date).ToUniversalTime()
        }
    }

    return $simulations
}

Write-Host ""
Write-Host "======================================="
Write-Host "EXECUTION SIMULATION COGNITION"
Write-Host "======================================="
Write-Host ""

$topologyFile = Get-LatestFile `
    -Root $TopologyRoot

$diagnosticsFile = Get-LatestFile `
    -Root $DiagnosticsRoot

$topology = Get-Content `
    $topologyFile.FullName `
    -Raw |
ConvertFrom-Json

$diagnostics = Get-Content `
    $diagnosticsFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[topology-runtimes] $($topology.Count)"
Write-Host "[diagnostics-loaded] $($diagnostics.Count)"

$simulation = Simulate-ExecutionTopology `
    -Topology $topology `
    -Diagnostics $diagnostics

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "orchestration-simulations\execution-simulation-$timestamp.json"

$simulation |
ConvertTo-Json -Depth 10 |
Set-Content $outputFile

Write-Host ""
Write-Host "[execution-simulation-written] $outputFile"
Write-Host ""
