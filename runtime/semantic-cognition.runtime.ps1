param(
    [string]$RuntimeRoot = ".\runtime",
    [string]$OutputRoot = ".\semantic-cognition"
)

$ErrorActionPreference = "Stop"

function Get-RuntimeFiles {
    param([string]$Root)

    Get-ChildItem `
        -Path $Root `
        -Recurse `
        -File `
        -Include "*.ps1","*.psm1"
}

function Infer-RuntimeRole {
    param(
        [string]$RuntimeName,
        [string]$Content
    )

    $role = "UNKNOWN"

    if ($RuntimeName -match "orchestration") {
        $role = "ORCHESTRATION"
    }
    elseif ($RuntimeName -match "memory") {
        $role = "ENGINEERING_MEMORY"
    }
    elseif ($RuntimeName -match "topology") {
        $role = "TOPOLOGY_ANALYSIS"
    }
    elseif ($RuntimeName -match "simulation") {
        $role = "EXECUTION_SIMULATION"
    }
    elseif ($RuntimeName -match "diagnostics") {
        $role = "INFRASTRUCTURE_DIAGNOSTICS"
    }
    elseif ($RuntimeName -match "cognition") {
        $role = "ENGINEERING_COGNITION"
    }
    elseif ($RuntimeName -match "execution") {
        $role = "EXECUTION_PLANNING"
    }

    return $role
}

function Infer-OperationalIntent {
    param([string]$Content)

    $intent = @()

    if ([string]::IsNullOrWhiteSpace($Content)) {
        return @("EMPTY_RUNTIME")
    }

    if ($Content -match "Get-ChildItem") {
        $intent += "REPOSITORY_DISCOVERY"
    }

    if ($Content -match "ConvertTo-Json") {
        $intent += "STATE_SERIALIZATION"
    }

    if ($Content -match "Get-Content") {
        $intent += "STATE_INSPECTION"
    }

    if ($Content -match "Set-Content") {
        $intent += "STATE_PERSISTENCE"
    }

    if ($Content -match "ConvertFrom-Json") {
        $intent += "COGNITION_RECONSTRUCTION"
    }

    return $intent | Sort-Object -Unique
}

function Get-SemanticHash {
    param([string]$Content)

    if ([string]::IsNullOrWhiteSpace($Content)) {
        return "EMPTY_RUNTIME"
    }

    return (
        [System.BitConverter]::ToString(
            [System.Security.Cryptography.SHA256]::Create().ComputeHash(
                [System.Text.Encoding]::UTF8.GetBytes($Content)
            )
        ).Replace("-", "")
    )
}

function Build-SemanticIndex {
    param([array]$RuntimeFiles)

    $index = @()

    foreach ($runtime in $RuntimeFiles) {

        $content = Get-Content `
            $runtime.FullName `
            -Raw `
            -ErrorAction SilentlyContinue

        if ($null -eq $content) {
            $content = ""
        }

        $role = Infer-RuntimeRole `
            -RuntimeName $runtime.Name `
            -Content $content

        $intent = Infer-OperationalIntent `
            -Content $content

        $semanticHash = Get-SemanticHash `
            -Content $content

        $index += [PSCustomObject]@{
            Runtime = $runtime.Name
            Role = $role
            OperationalIntent = $intent
            SemanticHash = $semanticHash
            IndexedAt = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $index
}

Write-Host ""
Write-Host "======================================="
Write-Host "SEMANTIC ENGINEERING COGNITION"
Write-Host "======================================="
Write-Host ""

$runtimes = Get-RuntimeFiles `
    -Root $RuntimeRoot

Write-Host "[runtime-files] $($runtimes.Count)"

$semanticIndex = Build-SemanticIndex `
    -RuntimeFiles $runtimes

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "runtime-semantics\semantic-index-$timestamp.json"

$semanticIndex |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[semantic-index-written] $outputFile"
Write-Host ""
