Write-Host ""
Write-Host "AI-Automation-OS :: Claude Context Runtime"
Write-Host ""

$cognitionPath = "infrastructure\repo-intelligence\exports\repo-cognition-export.json"

$outputPath = "context\claude-runtime\exports\engineering-context.json"

if (!(Test-Path $cognitionPath)) {

    Write-Host "Missing repo cognition export."
    exit
}

$cognition = Get-Content $cognitionPath -Raw | ConvertFrom-Json

$topology = $cognition.topology
$relationships = $cognition.relationships
$summary = $cognition.runtimeSummary

$activeZones = $topology.zones |
    Where-Object {
        $_.totalFiles -gt 0
    } |
    Select-Object zone, classification, totalFiles

$highDependencyModules = $relationships |
    Where-Object {
        $_.dependencyCount -gt 0
    } |
    Sort-Object dependencyCount -Descending |
    Select-Object -First 10

$contextPacket = @{
    generatedAt = (Get-Date).ToString("s")

    operationalState = @{
        topologyZones = $summary.topologyZones
        orchestrationScripts = $summary.orchestrationScripts
        runtimeModules = $summary.runtimeModules
    }

    activeInfrastructureZones = $activeZones

    highDependencyModules = $highDependencyModules

    architectureSummary = @{
        primaryRuntime = "orchestration-runtime"
        retrievalSystem = "repo-aware retrieval"
        memorySystem = "operational-memory"
        cognitionLayer = "claude-runtime"
        infrastructureType = "AI-native operational infrastructure"
    }
}

$contextPacket |
    ConvertTo-Json -Depth 20 |
    Set-Content $outputPath

Write-Host ""
Write-Host "Engineering context generated:"
Write-Host $outputPath
Write-Host ""
