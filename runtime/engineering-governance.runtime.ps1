param(
    [string]$SimulationRoot = ".\execution-simulation\orchestration-simulations",
    [string]$EvolutionRoot = ".\architecture-evolution\infrastructure-evolution",
    [string]$ReconciliationRoot = ".\cognition-reconciliation\distributed-consistency",
    [string]$OutputRoot = ".\engineering-governance"
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

function Build-GovernancePolicies {
    param(
        [array]$Simulation,
        [object]$Evolution,
        [array]$Reconciliation
    )

    $policies = @()

    $highRiskRuntimes = (
        $Simulation |
        Where-Object {
            $_.CascadeRisk -eq "HIGH"
        }
    ).Count

    $divergedRuntimes = (
        $Reconciliation |
        Where-Object {
            $_.ReconciliationState -eq "DIVERGED"
        }
    ).Count

    $globalRisk = "STABLE"

    if ($highRiskRuntimes -ge 5) {
        $globalRisk = "ELEVATED"
    }

    if ($divergedRuntimes -ge 5) {
        $globalRisk = "CRITICAL"
    }

    $enforcement = "NORMAL"

if ($globalRisk -eq "CRITICAL") {
    $enforcement = "STRICT"
}
elseif ($globalRisk -eq "ELEVATED") {
    $enforcement = "MODERATE"
}

$policies += [PSCustomObject]@{
        Policy = "TOPOLOGY_STABILITY"
        Enforcement = $enforcement
        HighRiskRuntimes = $highRiskRuntimes
        DivergedRuntimes = $divergedRuntimes
        ArchitectureDrift = $Evolution.ArchitectureDriftDetected
        GovernanceState = $globalRisk
        GovernedAt = (
            Get-Date
        ).ToUniversalTime()
    }

    return $policies
}

Write-Host ""
Write-Host "======================================="
Write-Host "ADAPTIVE ENGINEERING GOVERNANCE"
Write-Host "======================================="
Write-Host ""

$simulationFile = Get-LatestFile `
    -Root $SimulationRoot

$evolutionFile = Get-LatestFile `
    -Root $EvolutionRoot

$reconciliationFile = Get-LatestFile `
    -Root $ReconciliationRoot

$simulation = Get-Content `
    $simulationFile.FullName `
    -Raw |
ConvertFrom-Json

$evolution = Get-Content `
    $evolutionFile.FullName `
    -Raw |
ConvertFrom-Json

$reconciliation = Get-Content `
    $reconciliationFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[simulation-records] $($simulation.Count)"
Write-Host "[reconciliation-records] $($reconciliation.Count)"

$governance = Build-GovernancePolicies `
    -Simulation $simulation `
    -Evolution $evolution `
    -Reconciliation $reconciliation

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "policy-engine\engineering-governance-$timestamp.json"

$governance |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[engineering-governance-written] $outputFile"
Write-Host ""

