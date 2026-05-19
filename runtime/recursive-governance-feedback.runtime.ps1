param(
    [string]$RollbackRoot = ".\mutation-rollback-intelligence\rollback-strategies",
    [string]$GovernanceRoot = ".\engineering-governance\policy-engine",
    [string]$OutputRoot = ".\recursive-governance-feedback"
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

function Build-GovernanceFeedback {
    param(
        [array]$Rollback,
        [array]$Governance
    )

    $feedback = @()

    foreach ($runtime in $Rollback) {

        $governanceState =
        $Governance |
        Select-Object -First 1

        $feedbackStrength = "STABLE"

        if (
            $runtime.RollbackRequired
        ) {
            $feedbackStrength = "REINFORCED"
        }

        if (
            $runtime.RecoveryPriority -eq
            "CRITICAL"
        ) {
            $feedbackStrength = "ESCALATED"
        }

        $policyAdaptation = "NONE"

        switch ($feedbackStrength) {

            "REINFORCED" {
                $policyAdaptation =
                "INCREASE_MUTATION_CONSTRAINTS"
            }

            "ESCALATED" {
                $policyAdaptation =
                "ENABLE_STRICT_SURVIVABILITY_MODE"
            }
        }

        $governanceScore = 100

        if (
            $runtime.RollbackRequired
        ) {
            $governanceScore -= 30
        }

        if (
            $runtime.RecoveryPriority -eq
            "CRITICAL"
        ) {
            $governanceScore -= 50
        }

        if ($governanceScore -lt 0) {
            $governanceScore = 0
        }

        $feedback += [PSCustomObject]@{
            Runtime = $runtime.Runtime
            FeedbackStrength = $feedbackStrength
            PolicyAdaptation = $policyAdaptation
            GovernanceScore = $governanceScore
            RollbackRequired = $runtime.RollbackRequired
            RecoveryPriority = $runtime.RecoveryPriority
            GovernanceState = $governanceState.GovernanceState
            FeedbackGeneratedAt = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $feedback
}

Write-Host ""
Write-Host "======================================="
Write-Host "RECURSIVE GOVERNANCE FEEDBACK"
Write-Host "======================================="
Write-Host ""

$rollbackFile = Get-LatestFile `
    -Root $RollbackRoot

$governanceFile = Get-LatestFile `
    -Root $GovernanceRoot

$rollback = Get-Content `
    $rollbackFile.FullName `
    -Raw |
ConvertFrom-Json

$governance = Get-Content `
    $governanceFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[rollback-records] $($rollback.Count)"
Write-Host "[governance-records] $($governance.Count)"

$feedback =
Build-GovernanceFeedback `
    -Rollback $rollback `
    -Governance $governance

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "feedback-loops\recursive-governance-feedback-$timestamp.json"

$feedback |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[recursive-governance-feedback-written] $outputFile"
Write-Host ""
