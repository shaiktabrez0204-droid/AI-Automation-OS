param(
    [string]$CapabilityRoot = ".\repository-semantic-intelligence\capability-intelligence",
    [string]$SimulationRoot = ".\execution-simulation\orchestration-simulations",
    [string]$OutputRoot = ".\execution-consequence-intelligence"
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

function Analyze-ExecutionConsequences {
    param(
        [array]$Capabilities,
        [array]$Simulation
    )

    $results = @()

    foreach ($runtime in $Capabilities) {

        $simulationRecord = $Simulation |
        Where-Object {
            $_.Runtime -eq $runtime.Runtime
        } |
        Select-Object -First 1

        $blastRadius = "LOW"

        if ($runtime.CapabilityCount -ge 5) {
            $blastRadius = "MEDIUM"
        }

        if ($runtime.CapabilityCount -ge 8) {
            $blastRadius = "HIGH"
        }

        $operationalRisk = "STABLE"

        if (
            $simulationRecord.CascadeRisk -eq "MEDIUM"
        ) {
            $operationalRisk = "ELEVATED"
        }

        if (
            $simulationRecord.CascadeRisk -eq "HIGH"
        ) {
            $operationalRisk = "CRITICAL"
        }

        $consequenceScore = (
            ($runtime.CapabilityCount * 10) +
            ($runtime.SemanticCapabilityScore)
        )

        $results += [PSCustomObject]@{
            Runtime = $runtime.Runtime
            OperationalDomain = $runtime.OperationalDomain
            BlastRadius = $blastRadius
            OperationalRisk = $operationalRisk
            ConsequenceScore = $consequenceScore
            CapabilitySurface = (
                $runtime.CapabilityCount
            )
            ConsequenceIndexedAt = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $results
}

Write-Host ""
Write-Host "======================================="
Write-Host "EXECUTION CONSEQUENCE INTELLIGENCE"
Write-Host "======================================="
Write-Host ""

$capabilityFile = Get-LatestFile `
    -Root $CapabilityRoot

$simulationFile = Get-LatestFile `
    -Root $SimulationRoot

$capabilities = Get-Content `
    $capabilityFile.FullName `
    -Raw |
ConvertFrom-Json

$simulation = Get-Content `
    $simulationFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[capability-records] $($capabilities.Count)"
Write-Host "[simulation-records] $($simulation.Count)"

$consequences =
Analyze-ExecutionConsequences `
    -Capabilities $capabilities `
    -Simulation $simulation

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "consequence-analysis\execution-consequences-$timestamp.json"

$consequences |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[execution-consequences-written] $outputFile"
Write-Host ""
