param(
    [string]$MutationRoot = ".\adaptive-infrastructure-evolution\topology-mutations",
    [string]$GovernedConsensusRoot = ".\execution-governed-consensus\quorum-enforcement",
    [string]$OutputRoot = ".\mutation-admission-control"
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

function Build-AdmissionControl {
    param(
        [array]$Mutations,
        [array]$GovernedConsensus
    )

    $admissions = @()

    foreach ($mutation in $Mutations) {

        $consensusRecord = $GovernedConsensus |
        Where-Object {
            $_.Runtime -eq $mutation.Runtime
        } |
        Select-Object -First 1

        $admissionState = "ADMITTED"

        if (
            $mutation.MutationRisk -eq "HIGH"
        ) {
            $admissionState = "REVIEW_REQUIRED"
        }

        if (
            $consensusRecord.ExecutionState -eq "BLOCKED"
        ) {
            $admissionState = "REJECTED"
        }

        $governanceGate = "OPEN"

        switch ($admissionState) {

            "REVIEW_REQUIRED" {
                $governanceGate = "RESTRICTED"
            }

            "REJECTED" {
                $governanceGate = "CLOSED"
            }
        }

        $constraintSeverity = "LOW"

        switch ($mutation.MutationRisk) {

            "MODERATE" {
                $constraintSeverity = "MEDIUM"
            }

            "HIGH" {
                $constraintSeverity = "HIGH"
            }
        }

        $admissions += [PSCustomObject]@{
            Runtime = $mutation.Runtime
            MutationStrategy = $mutation.MutationStrategy
            MutationRisk = $mutation.MutationRisk
            AdmissionState = $admissionState
            GovernanceGate = $governanceGate
            ConstraintSeverity = $constraintSeverity
            ConsensusExecutionState = $consensusRecord.ExecutionState
            AdmissionTimestamp = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $admissions
}

Write-Host ""
Write-Host "======================================="
Write-Host "MUTATION ADMISSION CONTROL"
Write-Host "======================================="
Write-Host ""

$mutationFile = Get-LatestFile `
    -Root $MutationRoot

$consensusFile = Get-LatestFile `
    -Root $GovernedConsensusRoot

$mutations = Get-Content `
    $mutationFile.FullName `
    -Raw |
ConvertFrom-Json

$consensus = Get-Content `
    $consensusFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[mutation-records] $($mutations.Count)"
Write-Host "[governed-consensus-records] $($consensus.Count)"

$admission =
Build-AdmissionControl `
    -Mutations $mutations `
    -GovernedConsensus $consensus

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "execution-admission\mutation-admission-$timestamp.json"

$admission |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[mutation-admission-written] $outputFile"
Write-Host ""
