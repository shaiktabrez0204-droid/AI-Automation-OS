param(
    [string]$RuntimeRoot = ".\runtime",
    [string]$IntentRoot = ".\execution-intelligence\execution-intent",
    [string]$OutputRoot = ".\repository-semantic-intelligence"
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

function Infer-InfrastructureCapabilities {
    param([string]$Content)

    $capabilities = @()

    if ($Content -match "Get-ChildItem") {
        $capabilities +=
        "REPOSITORY_ENUMERATION"
    }

    if ($Content -match "ConvertTo-Json") {
        $capabilities +=
        "STATE_SERIALIZATION"
    }

    if ($Content -match "ConvertFrom-Json") {
        $capabilities +=
        "STATE_RECONSTRUCTION"
    }

    if ($Content -match "Set-Content") {
        $capabilities +=
        "PERSISTENT_STATE_WRITES"
    }

    if ($Content -match "Get-Content") {
        $capabilities +=
        "PERSISTENT_STATE_READS"
    }

    if ($Content -match "Where-Object") {
        $capabilities +=
        "TOPOLOGY_FILTERING"
    }

    if ($Content -match "Sort-Object") {
        $capabilities +=
        "ORCHESTRATION_PRIORITIZATION"
    }

    if ($Content -match "Measure-Object") {
        $capabilities +=
        "INFRASTRUCTURE_ANALYTICS"
    }

    return $capabilities |
    Sort-Object -Unique
}

function Infer-OperationalDomain {
    param([array]$Capabilities)

    $domain = "GENERAL_INFRASTRUCTURE"

    if (
        $Capabilities -contains
        "STATE_SERIALIZATION"
    ) {
        $domain = "COGNITION_PERSISTENCE"
    }

    if (
        $Capabilities -contains
        "INFRASTRUCTURE_ANALYTICS"
    ) {
        $domain = "INFRASTRUCTURE_ANALYSIS"
    }

    if (
        $Capabilities -contains
        "ORCHESTRATION_PRIORITIZATION"
    ) {
        $domain = "ORCHESTRATION_INTELLIGENCE"
    }

    return $domain
}

function Build-CapabilityIntelligence {
    param(
        [array]$RuntimeFiles,
        [array]$IntentRecords
    )

    $records = @()

    foreach ($runtime in $RuntimeFiles) {

        $content = Get-Content `
            $runtime.FullName `
            -Raw `
            -ErrorAction SilentlyContinue

        if ($null -eq $content) {
            $content = ""
        }

        $capabilities =
        Infer-InfrastructureCapabilities `
            -Content $content

        $domain =
        Infer-OperationalDomain `
            -Capabilities $capabilities

        $intent = $IntentRecords |
        Where-Object {
            $_.Runtime -eq $runtime.Name
        } |
        Select-Object -First 1

        $records += [PSCustomObject]@{
            Runtime = $runtime.Name
            OperationalDomain = $domain
            InfrastructureCapabilities = $capabilities
            CapabilityCount = (
                $capabilities.Count
            )
            IntentComplexity = (
                $intent.IntentComplexity
            )
            SemanticCapabilityScore = (
                ($capabilities.Count * 10) +
                $intent.IntentComplexity
            )
            IndexedAt = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $records
}

Write-Host ""
Write-Host "======================================="
Write-Host "REPOSITORY CAPABILITY INTELLIGENCE"
Write-Host "======================================="
Write-Host ""

$intentFile = Get-LatestFile `
    -Root $IntentRoot

$intent = Get-Content `
    $intentFile.FullName `
    -Raw |
ConvertFrom-Json

$runtimes = Get-ChildItem `
    -Path $RuntimeRoot `
    -Recurse `
    -File `
    -Include "*.ps1","*.psm1"

Write-Host "[runtime-files] $($runtimes.Count)"
Write-Host "[intent-records] $($intent.Count)"

$capabilityIntelligence =
Build-CapabilityIntelligence `
    -RuntimeFiles $runtimes `
    -IntentRecords $intent

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "capability-intelligence\repository-capabilities-$timestamp.json"

$capabilityIntelligence |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[repository-capabilities-written] $outputFile"
Write-Host ""
