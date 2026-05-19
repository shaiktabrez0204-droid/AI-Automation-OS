param(
    [string]$RuntimeRoot = ".\runtime",
    [string]$SemanticRoot = ".\semantic-cognition\runtime-semantics",
    [string]$ContractRoot = ".\orchestration-contracts\runtime-contracts",
    [string]$OutputRoot = ".\cognition-governance"
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

function Get-RuntimeFiles {
    param([string]$Root)

    Get-ChildItem `
        -Path $Root `
        -Recurse `
        -File `
        -Include "*.ps1","*.psm1"
}

function Analyze-CognitionConsistency {
    param(
        [array]$RuntimeFiles,
        [array]$SemanticIndex,
        [array]$Contracts
    )

    $results = @()

    foreach ($runtime in $RuntimeFiles) {

        $semantic = $SemanticIndex |
        Where-Object {
            $_.Runtime -eq $runtime.Name
        } |
        Select-Object -First 1

        $contract = $Contracts |
        Where-Object {
            $_.Runtime -eq $runtime.Name
        } |
        Select-Object -First 1

        $semanticExists = $null -ne $semantic
        $contractExists = $null -ne $contract

        $consistencyState = "CONSISTENT"

        if (-not $semanticExists) {
            $consistencyState = "SEMANTIC_MISSING"
        }

        if (-not $contractExists) {
            $consistencyState = "CONTRACT_MISSING"
        }

        if (
            (-not $semanticExists) -and
            (-not $contractExists)
        ) {
            $consistencyState = "COGNITION_ORPHAN"
        }

        $results += [PSCustomObject]@{
            Runtime = $runtime.Name
            SemanticIndexed = $semanticExists
            ContractIndexed = $contractExists
            ConsistencyState = $consistencyState
            ValidatedAt = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $results
}

Write-Host ""
Write-Host "======================================="
Write-Host "COGNITION CONSISTENCY GOVERNANCE"
Write-Host "======================================="
Write-Host ""

$semanticFile = Get-LatestFile `
    -Root $SemanticRoot

$contractFile = Get-LatestFile `
    -Root $ContractRoot

$semanticIndex = Get-Content `
    $semanticFile.FullName `
    -Raw |
ConvertFrom-Json

$contracts = Get-Content `
    $contractFile.FullName `
    -Raw |
ConvertFrom-Json

$runtimes = Get-RuntimeFiles `
    -Root $RuntimeRoot

Write-Host "[runtime-files] $($runtimes.Count)"
Write-Host "[semantic-index] $($semanticIndex.Count)"
Write-Host "[contracts] $($contracts.Count)"

$consistency = Analyze-CognitionConsistency `
    -RuntimeFiles $runtimes `
    -SemanticIndex $semanticIndex `
    -Contracts $contracts

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "consistency-checks\cognition-consistency-$timestamp.json"

$consistency |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[cognition-consistency-written] $outputFile"
Write-Host ""
