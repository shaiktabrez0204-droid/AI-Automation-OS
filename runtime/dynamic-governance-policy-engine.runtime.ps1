param(
    [string]$AdmissionRoot = ".\mutation-admission-control\execution-admission",
    [string]$FeedbackRoot = ".\recursive-governance-feedback\feedback-loops",
    [string]$OutputRoot = ".\dynamic-governance-policy-engine"
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

function Build-DynamicPolicies {
    param(
        [array]$Admissions,
        [array]$Feedback
    )

    $policies = @()

    foreach ($admission in $Admissions) {

        $feedbackRecord = $Feedback |
        Where-Object {
            $_.Runtime -eq $admission.Runtime
        } |
        Select-Object -First 1

        $policyMode = "NORMAL"

        if (
            $admission.ConstraintSeverity -eq
            "MEDIUM"
        ) {
            $policyMode = "RESTRICTED"
        }

        if (
            $admission.ConstraintSeverity -eq
            "HIGH"
        ) {
            $policyMode = "STRICT"
        }

        if (
            $feedbackRecord.PolicyAdaptation -eq
            "ENABLE_STRICT_SURVIVABILITY_MODE"
        ) {
            $policyMode = "LOCKDOWN"
        }

        $policyAction = "ALLOW_EXECUTION"

        switch ($policyMode) {

            "RESTRICTED" {
                $policyAction =
                "LIMIT_MUTATION_SCOPE"
            }

            "STRICT" {
                $policyAction =
                "REQUIRE_MULTI_STAGE_VALIDATION"
            }

            "LOCKDOWN" {
                $policyAction =
                "BLOCK_NON_CRITICAL_MUTATIONS"
            }
        }

        $policyScore = 100

        switch ($policyMode) {

            "RESTRICTED" {
                $policyScore -= 20
            }

            "STRICT" {
                $policyScore -= 40
            }

            "LOCKDOWN" {
                $policyScore -= 70
            }
        }

        $policies += [PSCustomObject]@{
            Runtime = $admission.Runtime
            PolicyMode = $policyMode
            PolicyAction = $policyAction
            PolicyScore = $policyScore
            AdmissionState = $admission.AdmissionState
            GovernanceGate = $admission.GovernanceGate
            PolicyGeneratedAt = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $policies
}

Write-Host ""
Write-Host "======================================="
Write-Host "DYNAMIC GOVERNANCE POLICY ENGINE"
Write-Host "======================================="
Write-Host ""

$admissionFile = Get-LatestFile `
    -Root $AdmissionRoot

$feedbackFile = Get-LatestFile `
    -Root $FeedbackRoot

$admission = Get-Content `
    $admissionFile.FullName `
    -Raw |
ConvertFrom-Json

$feedback = Get-Content `
    $feedbackFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[admission-records] $($admission.Count)"
Write-Host "[feedback-records] $($feedback.Count)"

$policies =
Build-DynamicPolicies `
    -Admissions $admission `
    -Feedback $feedback

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "policy-registry\dynamic-governance-policies-$timestamp.json"

$policies |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[dynamic-governance-policies-written] $outputFile"
Write-Host ""
