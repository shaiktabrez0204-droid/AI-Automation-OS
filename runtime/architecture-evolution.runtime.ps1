param(
    [string]$MemoryRoot = ".\repository-cognition\engineering-memory\cognition-history",
    [string]$SimulationRoot = ".\execution-simulation\orchestration-simulations",
    [string]$OutputRoot = ".\architecture-evolution"
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

function Analyze-ArchitectureEvolution {
    param(
        [object]$Memory,
        [array]$Simulation
    )

    $runtimeCount = 0

    if ($Memory.RuntimeTopology.Runtimes) {
        $runtimeCount = $Memory.RuntimeTopology.Runtimes.Count
    }

    $highRiskCount = (
        $Simulation |
        Where-Object {
            $_.CascadeRisk -eq "HIGH"
        }
    ).Count

    $mutationPressure = "LOW"

    if ($runtimeCount -ge 25) {
        $mutationPressure = "MEDIUM"
    }

    if ($runtimeCount -ge 50) {
        $mutationPressure = "HIGH"
    }

    $continuityRisk = "STABLE"

    if ($highRiskCount -ge 5) {
        $continuityRisk = "ELEVATED"
    }

    if ($highRiskCount -ge 10) {
        $continuityRisk = "CRITICAL"
    }

    return [PSCustomObject]@{
        RuntimeCount = $runtimeCount
        HighRiskRuntimeCount = $highRiskCount
        MutationPressure = $mutationPressure
        ContinuityRisk = $continuityRisk
        ArchitectureDriftDetected = (
            $runtimeCount -gt 20
        )
        EvolutionAnalyzedAt = (
            Get-Date
        ).ToUniversalTime()
    }
}

Write-Host ""
Write-Host "======================================="
Write-Host "ARCHITECTURE EVOLUTION COGNITION"
Write-Host "======================================="
Write-Host ""

$memoryFile = Get-LatestFile `
    -Root $MemoryRoot

$simulationFile = Get-LatestFile `
    -Root $SimulationRoot

$memory = Get-Content `
    $memoryFile.FullName `
    -Raw |
ConvertFrom-Json

$simulation = Get-Content `
    $simulationFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[memory-loaded]"
Write-Host "[simulation-runtimes] $($simulation.Count)"

$evolution = Analyze-ArchitectureEvolution `
    -Memory $memory `
    -Simulation $simulation

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "infrastructure-evolution\architecture-evolution-$timestamp.json"

$evolution |
ConvertTo-Json -Depth 10 |
Set-Content $outputFile

Write-Host ""
Write-Host "[architecture-evolution-written] $outputFile"
Write-Host ""
