param(
    [string]$RuntimeRoot = ".\runtime",
    [string]$OutputRoot = ".\repository-cognition"
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

function Extract-RuntimeReferences {
    param([string]$FilePath)

    $content = Get-Content $FilePath -Raw

    $matches = Select-String `
        -InputObject $content `
        -Pattern '\.\\runtime\\([a-zA-Z0-9\-\._]+)' `
        -AllMatches

    $refs = @()

    foreach ($match in $matches.Matches) {
        $refs += $match.Groups[1].Value
    }

    return $refs | Sort-Object -Unique
}

function Build-RuntimeTopology {
    param([array]$RuntimeFiles)

    $topology = @()

    foreach ($runtime in $RuntimeFiles) {

        $refs = Extract-RuntimeReferences `
            -FilePath $runtime.FullName

        $topology += [PSCustomObject]@{
            Runtime = $runtime.Name
            Path = $runtime.FullName
            References = $refs
            LastWriteTime = $runtime.LastWriteTimeUtc
        }
    }

    return $topology
}

Write-Host ""
Write-Host "======================================="
Write-Host "RUNTIME TOPOLOGY COGNITION"
Write-Host "======================================="
Write-Host ""

$runtimes = Get-RuntimeFiles `
    -Root $RuntimeRoot

Write-Host "[runtime-files] $($runtimes.Count)"

$topology = Build-RuntimeTopology `
    -RuntimeFiles $runtimes

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "graph\topology\runtime-topology-$timestamp.json"

$topology |
ConvertTo-Json -Depth 10 |
Set-Content $outputFile

Write-Host ""
Write-Host "[runtime-topology-written] $outputFile"
Write-Host ""
