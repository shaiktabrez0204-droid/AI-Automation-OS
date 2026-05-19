param(
    [string]$GovernanceRoot = ".\engineering-governance\policy-engine",
    [string]$SimulationRoot = ".\execution-simulation\orchestration-simulations",
    [string]$ReconciliationRoot = ".\cognition-reconciliation\distributed-consistency",
    [string]$OutputRoot = ".\continuity-intelligence"
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

function Analyze-ContinuityState {
    param(
        [array]$Governance,
        [array]$Simulation,
        [array]$Reconciliation
    )

    $highRisk = (
        $Simulation |
        Where-Object {
            $_.CascadeRisk -eq "HIGH"
        }
    ).Count

    $diverged = (
        $Reconciliation |
        Where-Object {
            $_.ReconciliationState -eq "DIVERGED"
        }
    ).Count

    $governanceCritical = (
        $Governance |
        Where-Object {
            $_.GovernanceState -eq "CRITICAL"
        }
    ).Count

    $continuityState = "STABLE"

    if (
        ($highRisk -ge 5) -or
        ($diverged -ge 5)
    ) {
        $continuityState = "DEGRADED"
    }

    if (
        ($highRisk -ge 10) -or
        ($diverged -ge 10) -or
        ($governanceCritical -ge 1)
    ) {
        $continuityState = "FRAGILE"
    }

    $resilienceScore = (
        100 -
        ($highRisk * 3) -
        ($diverged * 2)
    )

    if ($resilienceScore -lt 0) {
        $resilienceScore = 0
    }

    $forecast = "SURVIVABLE"

    if ($continuityState -eq "FRAGILE") {
        $forecast = "UNSTABLE_EVOLUTION"
    }
    elseif ($continuityState -eq "DEGRADED") {
        $forecast = "CONTROLLED_RISK"
    }

    return [PSCustomObject]@{
        HighRiskTopologyCount = $highRisk
        DivergedCognitionCount = $diverged
        GovernanceCriticalCount = $governanceCritical
        ContinuityState = $continuityState
        ResilienceScore = $resilienceScore
        SurvivabilityForecast = $forecast
        AnalyzedAt = (
            Get-Date
        ).ToUniversalTime()
    }
}

Write-Host ""
Write-Host "======================================="
Write-Host "CONTINUITY INTELLIGENCE"
Write-Host "======================================="
Write-Host ""

$governanceFile = Get-LatestFile `
    -Root $GovernanceRoot

$simulationFile = Get-LatestFile `
    -Root $SimulationRoot

$reconciliationFile = Get-LatestFile `
    -Root $ReconciliationRoot

$governance = Get-Content `
    $governanceFile.FullName `
    -Raw |
ConvertFrom-Json

$simulation = Get-Content `
    $simulationFile.FullName `
    -Raw |
ConvertFrom-Json

$reconciliation = Get-Content `
    $reconciliationFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[governance-records] $($governance.Count)"
Write-Host "[simulation-records] $($simulation.Count)"
Write-Host "[reconciliation-records] $($reconciliation.Count)"

$continuity = Analyze-ContinuityState `
    -Governance $governance `
    -Simulation $simulation `
    -Reconciliation $reconciliation

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "survivability-analysis\continuity-intelligence-$timestamp.json"

$continuity |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[continuity-intelligence-written] $outputFile"
Write-Host ""
