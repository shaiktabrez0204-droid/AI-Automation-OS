<#
AI-Automation-OS runtime stage: runtime-local governance.

This stage resolves global policy and consensus records into local runtime
execution constraints. The output is consumed by local event journaling so
events carry the governance context active when they were journaled.
#>

param(
    [string]$PolicyRoot = ".\dynamic-governance-policy-engine\policy-registry",
    [string]$ConsensusRoot = ".\execution-governed-consensus\quorum-enforcement",
    [string]$OutputRoot = ".\runtime-local-governance"
)

$ErrorActionPreference = "Stop"

<#
============================================================
   ARTIFACT DISCOVERY
============================================================
#>

function Get-LatestFile {
    param([string]$Root)

    # Local governance combines independently produced policy and consensus
    # artifacts. Timestamp skew between those inputs is currently an operator
    # concern, not something this script resolves.
    Get-ChildItem `
        -Path $Root `
        -Filter "*.json" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

<#
============================================================
   LOCAL GOVERNANCE PROJECTION
============================================================
#>

function Build-LocalGovernance {
    param(
        [array]$Policies,
        [array]$Consensus
    )

    $localGovernance = @()

    foreach ($policy in $Policies) {

        $consensusRecord = $Consensus |
        Where-Object {
            $_.Runtime -eq $policy.Runtime
        } |
        Select-Object -First 1

        $localExecution = "ENABLED"

        # PolicyMode is intentionally translated into a smaller execution-state
        # vocabulary so event journaling can reason about local constraints
        # without reinterpreting global policy rules.
        if (
            $policy.PolicyMode -eq "STRICT"
        ) {
            $localExecution = "CONSTRAINED"
        }

        if (
            $policy.PolicyMode -eq "LOCKDOWN"
        ) {
            $localExecution = "ISOLATED"
        }

        $syncState = "SYNCHRONIZED"

        if (
            $consensusRecord.PropagationValidation -eq
            "REVALIDATE"
        ) {
            $syncState = "PENDING_RECONCILIATION"
        }

        $constraintScope = "LOCAL"

        # Lockdown crosses the local boundary because replay and audit need to
        # know that a federated constraint was active for this runtime.
        if (
            $policy.PolicyMode -eq "LOCKDOWN"
        ) {
            $constraintScope = "FEDERATED"
        }

        $localGovernance += [PSCustomObject]@{
            Runtime = $policy.Runtime
            PolicyMode = $policy.PolicyMode
            LocalExecutionState = $localExecution
            SynchronizationState = $syncState
            ConstraintScope = $constraintScope
            PolicyAction = $policy.PolicyAction
            ConsensusExecutionState = $consensusRecord.ExecutionState
            GovernanceTimestamp = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $localGovernance
}

<#
============================================================
   RUNTIME ENTRYPOINT
============================================================
#>

Write-Host ""
Write-Host "======================================="
Write-Host "RUNTIME-LOCAL GOVERNANCE"
Write-Host "======================================="
Write-Host ""

$policyFile = Get-LatestFile `
    -Root $PolicyRoot

$consensusFile = Get-LatestFile `
    -Root $ConsensusRoot

$policies = Get-Content `
    $policyFile.FullName `
    -Raw |
ConvertFrom-Json

$consensus = Get-Content `
    $consensusFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[policy-records] $($policies.Count)"
Write-Host "[consensus-records] $($consensus.Count)"

$localGovernance =
Build-LocalGovernance `
    -Policies $policies `
    -Consensus $consensus

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "local-policy-state\runtime-local-governance-$timestamp.json"

$localGovernance |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[runtime-local-governance-written] $outputFile"
Write-Host ""
