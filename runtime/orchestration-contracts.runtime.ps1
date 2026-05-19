param(
    [string]$RuntimeRoot = ".\runtime",
    [string]$SemanticRoot = ".\semantic-cognition\runtime-semantics",
    [string]$OutputRoot = ".\orchestration-contracts"
)

$ErrorActionPreference = "Stop"

function Get-LatestSemanticIndex {
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

function Extract-ExecutionContracts {
    param([string]$Content)

    $contracts = @()

    if ($Content -match "param\(") {
        $contracts += "PARAMETERIZED_EXECUTION"
    }

    if ($Content -match "ConvertTo-Json") {
        $contracts += "STATE_SERIALIZATION"
    }

    if ($Content -match "ConvertFrom-Json") {
        $contracts += "STATE_RECONSTRUCTION"
    }

    if ($Content -match "Set-Content") {
        $contracts += "PERSISTENT_STATE_MUTATION"
    }

    if ($Content -match "Get-Content") {
        $contracts += "STATE_DEPENDENCY"
    }

    return $contracts | Sort-Object -Unique
}

function Build-OrchestrationContracts {
    param(
        [array]$RuntimeFiles,
        [array]$SemanticIndex
    )

    $contracts = @()

    foreach ($runtime in $RuntimeFiles) {

        $content = Get-Content `
            $runtime.FullName `
            -Raw `
            -ErrorAction SilentlyContinue

        if ($null -eq $content) {
            $content = ""
        }

        $semantic = $SemanticIndex |
        Where-Object {
            $_.Runtime -eq $runtime.Name
        } |
        Select-Object -First 1

        $executionContracts = Extract-ExecutionContracts `
            -Content $content

        $contracts += [PSCustomObject]@{
            Runtime = $runtime.Name
            Role = $semantic.Role
            OperationalIntent = $semantic.OperationalIntent
            ExecutionContracts = $executionContracts
            CoordinationSurface = (
                $executionContracts.Count
            )
            ContractIndexedAt = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $contracts
}

Write-Host ""
Write-Host "======================================="
Write-Host "ORCHESTRATION CONTRACT COGNITION"
Write-Host "======================================="
Write-Host ""

$semanticFile = Get-LatestSemanticIndex `
    -Root $SemanticRoot

$semanticIndex = Get-Content `
    $semanticFile.FullName `
    -Raw |
ConvertFrom-Json

$runtimes = Get-RuntimeFiles `
    -Root $RuntimeRoot

Write-Host "[runtime-files] $($runtimes.Count)"
Write-Host "[semantic-index] $($semanticIndex.Count)"

$contracts = Build-OrchestrationContracts `
    -RuntimeFiles $runtimes `
    -SemanticIndex $semanticIndex

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "runtime-contracts\orchestration-contracts-$timestamp.json"

$contracts |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[orchestration-contracts-written] $outputFile"
Write-Host ""
