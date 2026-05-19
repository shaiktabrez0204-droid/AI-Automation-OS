param(
    [string]$CognitionRoot = ".\repository-cognition"
)

$ErrorActionPreference = "Stop"

function Get-LatestManifest {
    param([string]$ManifestRoot)

    Get-ChildItem `
        -Path $ManifestRoot `
        -Filter "*.json" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

function Get-LatestTopology {
    param([string]$TopologyRoot)

    Get-ChildItem `
        -Path $TopologyRoot `
        -Filter "*.json" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

function Build-EngineeringMemory {
    param(
        [object]$Manifest,
        [object]$Topology
    )

    [PSCustomObject]@{
        MemoryId = [guid]::NewGuid().Guid
        GeneratedAt = (Get-Date).ToUniversalTime()

        RepositoryState = @{
            FileCount = $Manifest.FileCount
            TotalBytes = $Manifest.TotalBytes
            ExtensionDistribution = $Manifest.Extensions
        }

        RuntimeTopology = @{
            RuntimeCount = $Topology.Count
            Runtimes = $Topology
        }

        CognitionState = @{
            RepositoryCognition = $true
            RuntimeTopologyCognition = $true
            DependencyGraphCognition = $true
        }
    }
}

Write-Host ""
Write-Host "======================================="
Write-Host "ENGINEERING MEMORY INITIALIZATION"
Write-Host "======================================="
Write-Host ""

$manifestFile = Get-LatestManifest `
    -ManifestRoot ".\repository-cognition\manifests"

$topologyFile = Get-LatestTopology `
    -TopologyRoot ".\repository-cognition\graph\topology"

$manifest = Get-Content `
    $manifestFile.FullName `
    -Raw |
ConvertFrom-Json

$topology = Get-Content `
    $topologyFile.FullName `
    -Raw |
ConvertFrom-Json

$memory = Build-EngineeringMemory `
    -Manifest $manifest `
    -Topology $topology

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $CognitionRoot `
    "engineering-memory\cognition-history\engineering-memory-$timestamp.json"

$memory |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[engineering-memory-written] $outputFile"
Write-Host ""
