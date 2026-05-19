param(
    [string]$TopologyRoot = ".\repository-cognition\graph\topology",
    [string]$OutputRoot = ".\execution-planning"
)

$ErrorActionPreference = "Stop"

function Get-LatestTopology {
    param([string]$Root)

    Get-ChildItem `
        -Path $Root `
        -Filter "*.json" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

function Build-ExecutionPlan {
    param([array]$Topology)

    $plans = @()

    foreach ($runtime in $Topology) {

        $dependencyCount = 0

        if ($runtime.References) {
            $dependencyCount = $runtime.References.Count
        }

        $plans += [PSCustomObject]@{
            Runtime = $runtime.Runtime
            ExecutionPriority = $dependencyCount
            Dependencies = $runtime.References
            CoordinationWeight = (
                $dependencyCount * 10
            )
            PlannedAt = (Get-Date).ToUniversalTime()
        }
    }

    return $plans |
        Sort-Object ExecutionPriority -Descending
}

Write-Host ""
Write-Host "======================================="
Write-Host "EXECUTION PLANNING COGNITION"
Write-Host "======================================="
Write-Host ""

$topologyFile = Get-LatestTopology `
    -Root $TopologyRoot

$topology = Get-Content `
    $topologyFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[topology-runtimes] $($topology.Count)"

$executionPlan = Build-ExecutionPlan `
    -Topology $topology

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "orchestration-plans\execution-plan-$timestamp.json"

$executionPlan |
ConvertTo-Json -Depth 10 |
Set-Content $outputFile

Write-Host ""
Write-Host "[execution-plan-written] $outputFile"
Write-Host ""
