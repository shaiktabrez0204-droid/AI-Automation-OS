param(
    [string]$TopologyRoot = ".\adaptive-infrastructure-evolution\topology-mutations",
    [string]$HealingRoot = ".\topology-self-healing\runtime-healing",
    [string]$OutputRoot = ".\incremental-cognition-propagation"
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

function Build-CognitionDeltas {
    param(
        [array]$Topology,
        [array]$Healing
    )

    $deltas = @()

    foreach ($runtime in $Topology) {

        $healingRecord = $Healing |
        Where-Object {
            $_.Runtime -eq $runtime.Runtime
        } |
        Select-Object -First 1

        $deltaType = "NO_CHANGE"

        if (
            $runtime.MutationStrategy -ne
            "NO_CHANGE"
        ) {
            $deltaType = "TOPOLOGY_MUTATION"
        }

        if (
            $healingRecord.HealingStrategy -eq
            "RUNTIME_RECOVERY"
        ) {
            $deltaType = "RECOVERY_PROPAGATION"
        }

        $propagationPriority = "NORMAL"

        if (
            $runtime.MutationRisk -eq "MODERATE"
        ) {
            $propagationPriority = "HIGH"
        }

        if (
            $runtime.MutationRisk -eq "HIGH"
        ) {
            $propagationPriority = "CRITICAL"
        }

        $deltaHash = (
            [System.Guid]::NewGuid().Guid
        )

        $deltas += [PSCustomObject]@{
            Runtime = $runtime.Runtime
            DeltaType = $deltaType
            MutationRisk = $runtime.MutationRisk
            PropagationPriority = $propagationPriority
            HealingStrategy = $healingRecord.HealingStrategy
            DeltaHash = $deltaHash
            PropagationTimestamp = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $deltas
}

Write-Host ""
Write-Host "======================================="
Write-Host "INCREMENTAL COGNITION PROPAGATION"
Write-Host "======================================="
Write-Host ""

$topologyFile = Get-LatestFile `
    -Root $TopologyRoot

$healingFile = Get-LatestFile `
    -Root $HealingRoot

$topology = Get-Content `
    $topologyFile.FullName `
    -Raw |
ConvertFrom-Json

$healing = Get-Content `
    $healingFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[topology-records] $($topology.Count)"
Write-Host "[healing-records] $($healing.Count)"

$propagation =
Build-CognitionDeltas `
    -Topology $topology `
    -Healing $healing

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "delta-streams\incremental-propagation-$timestamp.json"

$propagation |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[incremental-propagation-written] $outputFile"
Write-Host ""
