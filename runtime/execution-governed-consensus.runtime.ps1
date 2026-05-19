param(
    [string]$ConsensusRoot = ".\distributed-cognition-consensus\quorum-state",
    [string]$OutputRoot = ".\execution-governed-consensus"
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

function Build-GovernedConsensus {
    param([array]$Consensus)

    $governed = @()

    foreach ($record in $Consensus) {

        $executionState = "ALLOWED"

        if (
            $record.QuorumState -eq
            "REVIEW_REQUIRED"
        ) {
            $executionState = "RESTRICTED"
        }

        if (
            $record.ConflictState -eq
            "SEQUENCE_CONFLICT"
        ) {
            $executionState = "BLOCKED"
        }

        $propagationValidation = "VALID"

        if (
            $record.OrderingState -eq
            "RESEQUENCING_REQUIRED"
        ) {
            $propagationValidation = "REVALIDATE"
        }

        $constraintLevel = "NORMAL"

        switch ($executionState) {

            "RESTRICTED" {
                $constraintLevel = "HIGH"
            }

            "BLOCKED" {
                $constraintLevel = "CRITICAL"
            }
        }

        $governed += [PSCustomObject]@{
            Runtime = $record.Runtime
            EventSequence = $record.EventSequence
            ExecutionState = $executionState
            ConstraintLevel = $constraintLevel
            PropagationValidation = $propagationValidation
            QuorumState = $record.QuorumState
            ConflictState = $record.ConflictState
            GovernanceTimestamp = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $governed
}

Write-Host ""
Write-Host "======================================="
Write-Host "EXECUTION-GOVERNED CONSENSUS"
Write-Host "======================================="
Write-Host ""

$consensusFile = Get-LatestFile `
    -Root $ConsensusRoot

$consensus = Get-Content `
    $consensusFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[consensus-records] $($consensus.Count)"

$governed =
Build-GovernedConsensus `
    -Consensus $consensus

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "quorum-enforcement\execution-governed-consensus-$timestamp.json"

$governed |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[execution-governed-consensus-written] $outputFile"
Write-Host ""
