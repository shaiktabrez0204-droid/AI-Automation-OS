param(
    [string]$SemanticRoot = ".\semantic-cognition\runtime-semantics",
    [string]$GovernanceRoot = ".\cognition-governance\consistency-checks",
    [string]$OutputRoot = ".\engineering-lineage"
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

function Build-LineageRecords {
    param(
        [array]$SemanticIndex,
        [array]$Governance
    )

    $records = @()

    foreach ($semantic in $SemanticIndex) {

        $governanceRecord = $Governance |
        Where-Object {
            $_.Runtime -eq $semantic.Runtime
        } |
        Select-Object -First 1

        $consistencyState = "UNKNOWN"

        if ($null -ne $governanceRecord) {
            $consistencyState = $governanceRecord.ConsistencyState
        }

        $records += [PSCustomObject]@{
            Runtime = $semantic.Runtime
            Role = $semantic.Role
            SemanticHash = $semantic.SemanticHash
            OperationalIntent = $semantic.OperationalIntent
            ConsistencyState = $consistencyState
            LineageId = (
                [guid]::NewGuid().Guid
            )
            LineageRecordedAt = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $records
}

Write-Host ""
Write-Host "======================================="
Write-Host "ENGINEERING LINEAGE COGNITION"
Write-Host "======================================="
Write-Host ""

$semanticFile = Get-LatestFile `
    -Root $SemanticRoot

$governanceFile = Get-LatestFile `
    -Root $GovernanceRoot

$semanticIndex = Get-Content `
    $semanticFile.FullName `
    -Raw |
ConvertFrom-Json

$governance = Get-Content `
    $governanceFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[semantic-index] $($semanticIndex.Count)"
Write-Host "[governance-records] $($governance.Count)"

$lineage = Build-LineageRecords `
    -SemanticIndex $semanticIndex `
    -Governance $governance

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "runtime-lineage\engineering-lineage-$timestamp.json"

$lineage |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[engineering-lineage-written] $outputFile"
Write-Host ""
