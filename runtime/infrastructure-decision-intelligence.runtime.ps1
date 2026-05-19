param(
    [string]$ConsequenceRoot = ".\execution-consequence-intelligence\consequence-analysis",
    [string]$ContinuityRoot = ".\continuity-intelligence\survivability-analysis",
    [string]$RemediationRoot = ".\autonomous-remediation\remediation-plans",
    [string]$OutputRoot = ".\infrastructure-decision-intelligence"
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

function Build-DecisionIntelligence {
    param(
        [array]$Consequences,
        [object]$Continuity,
        [array]$Remediation
    )

    $decisions = @()

    foreach ($runtime in $Consequences) {

        $priority = "NORMAL"

        if ($runtime.OperationalRisk -eq "ELEVATED") {
            $priority = "HIGH"
        }

        if ($runtime.OperationalRisk -eq "CRITICAL") {
            $priority = "URGENT"
        }

        $strategy = "MAINTAIN"

        if ($runtime.BlastRadius -eq "HIGH") {
            $strategy = "CONSTRAIN_EXECUTION"
        }

        if (
            $Continuity.ContinuityState -eq "FRAGILE"
        ) {
            $strategy = "PRIORITIZE_STABILIZATION"
        }

        $tradeoffScore = (
            $runtime.ConsequenceScore +
            $runtime.CapabilitySurface
        )

        $decisions += [PSCustomObject]@{
            Runtime = $runtime.Runtime
            OperationalRisk = $runtime.OperationalRisk
            BlastRadius = $runtime.BlastRadius
            DecisionPriority = $priority
            CoordinationStrategy = $strategy
            TradeoffScore = $tradeoffScore
            DecisionIndexedAt = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $decisions
}

Write-Host ""
Write-Host "======================================="
Write-Host "INFRASTRUCTURE DECISION INTELLIGENCE"
Write-Host "======================================="
Write-Host ""

$consequenceFile = Get-LatestFile `
    -Root $ConsequenceRoot

$continuityFile = Get-LatestFile `
    -Root $ContinuityRoot

$remediationFile = Get-LatestFile `
    -Root $RemediationRoot

$consequences = Get-Content `
    $consequenceFile.FullName `
    -Raw |
ConvertFrom-Json

$continuity = Get-Content `
    $continuityFile.FullName `
    -Raw |
ConvertFrom-Json

$remediation = Get-Content `
    $remediationFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[consequence-records] $($consequences.Count)"
Write-Host "[remediation-records] $($remediation.Count)"
Write-Host "[continuity-state] $($continuity.ContinuityState)"

$decisionIntelligence =
Build-DecisionIntelligence `
    -Consequences $consequences `
    -Continuity $continuity `
    -Remediation $remediation

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "decision-analysis\decision-intelligence-$timestamp.json"

$decisionIntelligence |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[decision-intelligence-written] $outputFile"
Write-Host ""
