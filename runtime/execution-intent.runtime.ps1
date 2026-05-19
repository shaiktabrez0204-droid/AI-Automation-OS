param(
    [string]$RuntimeRoot = ".\runtime",
    [string]$LineageRoot = ".\engineering-lineage\runtime-lineage",
    [string]$OutputRoot = ".\execution-intelligence"
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

function Infer-ExecutionObjective {
    param([string]$Content)

    $objectives = @()

    if ($Content -match "Get-ChildItem") {
        $objectives += "INFRASTRUCTURE_DISCOVERY"
    }

    if ($Content -match "ConvertTo-Json") {
        $objectives += "COGNITION_PERSISTENCE"
    }

    if ($Content -match "ConvertFrom-Json") {
        $objectives += "STATE_RECONSTRUCTION"
    }

    if ($Content -match "Set-Content") {
        $objectives += "INFRASTRUCTURE_MUTATION"
    }

    if ($Content -match "Write-Host") {
        $objectives += "EXECUTION_VISIBILITY"
    }

    return $objectives | Sort-Object -Unique
}

function Build-ExecutionIntent {
    param(
        [array]$Lineage,
        [array]$RuntimeFiles
    )

    $intentRecords = @()

    foreach ($runtime in $RuntimeFiles) {

        $content = Get-Content `
            $runtime.FullName `
            -Raw `
            -ErrorAction SilentlyContinue

        if ($null -eq $content) {
            $content = ""
        }

        $lineage = $Lineage |
        Where-Object {
            $_.Runtime -eq $runtime.Name
        } |
        Select-Object -First 1

        $objectives = Infer-ExecutionObjective `
            -Content $content

        $intentRecords += [PSCustomObject]@{
            Runtime = $runtime.Name
            Role = $lineage.Role
            ExecutionObjectives = $objectives
            IntentComplexity = (
                $objectives.Count
            )
            OperationalLineage = $lineage.LineageId
            IntentIndexedAt = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $intentRecords
}

Write-Host ""
Write-Host "======================================="
Write-Host "EXECUTION INTENT COGNITION"
Write-Host "======================================="
Write-Host ""

$lineageFile = Get-LatestFile `
    -Root $LineageRoot

$lineage = Get-Content `
    $lineageFile.FullName `
    -Raw |
ConvertFrom-Json

$runtimes = Get-ChildItem `
    -Path $RuntimeRoot `
    -Recurse `
    -File `
    -Include "*.ps1","*.psm1"

Write-Host "[lineage-records] $($lineage.Count)"
Write-Host "[runtime-files] $($runtimes.Count)"

$intent = Build-ExecutionIntent `
    -Lineage $lineage `
    -RuntimeFiles $runtimes

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "execution-intent\execution-intent-$timestamp.json"

$intent |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[execution-intent-written] $outputFile"
Write-Host ""
