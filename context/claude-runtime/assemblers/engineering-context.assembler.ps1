Write-Host ""
Write-Host "AI-Automation-OS :: Engineering Context Assembler"
Write-Host ""

$retrievalPath = "retrieval\repo-aware\indexing\retrieval-context.json"

$cognitionPath = "infrastructure\repo-intelligence\exports\repo-cognition-export.json"

$architectureStatePath = "memory\architecture-state\current-runtime-state.md"

$outputPath = "context\claude-runtime\exports\dynamic-engineering-context.json"

if (!(Test-Path $retrievalPath)) {

    Write-Host "Missing retrieval context."
    exit
}

if (!(Test-Path $cognitionPath)) {

    Write-Host "Missing cognition export."
    exit
}

$retrieval = Get-Content $retrievalPath -Raw | ConvertFrom-Json

$cognition = Get-Content $cognitionPath -Raw | ConvertFrom-Json

$criticalModules = $retrieval.retrievalPriority.criticalModules |
    Select-Object -First 5

$criticalZones = $retrieval.retrievalPriority.criticalZones |
    Select-Object -First 5

$runtimeRanking = $cognition.runtimeImportanceRanking |
    Select-Object -First 5

$engineeringPacket = [PSCustomObject]@{

    generatedAt = (Get-Date).ToString("s")

    operationalState = [PSCustomObject]@{

        primaryRuntime = $retrieval.engineeringFocus.primaryRuntime

        highestPriorityModule = $retrieval.engineeringFocus.highestPriorityModule

        runtimeModules = $cognition.runtimeSummary.runtimeModules

        topologyZones = $cognition.runtimeSummary.topologyZones
    }

    criticalInfrastructure = [PSCustomObject]@{

        modules = $criticalModules

        zones = $criticalZones
    }

    orchestrationIntelligence = [PSCustomObject]@{

        runtimeRanking = $runtimeRanking

        orchestrationFocus = @(
            "execution orchestration",
            "pipeline coordination",
            "runtime supervision",
            "retrieval-aware engineering",
            "repo cognition"
        )
    }

    engineeringDirectives = @(
        "prioritize orchestration-critical systems",
        "maintain modular runtime boundaries",
        "preserve retrieval-aware cognition",
        "optimize operational continuity",
        "prevent architecture drift"
    )
}

$engineeringPacket |
    ConvertTo-Json -Depth 30 |
    Set-Content $outputPath

Write-Host ""
Write-Host "Dynamic engineering context generated:"
Write-Host $outputPath
Write-Host ""
