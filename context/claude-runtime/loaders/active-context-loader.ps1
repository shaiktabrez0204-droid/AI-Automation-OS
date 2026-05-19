Write-Host ""
Write-Host "AI-Automation-OS :: Active Context Loader"
Write-Host ""

$evolutionPath = "memory\implementation-history\architecture-evolution.json"

$retrievalPath = "retrieval\repo-aware\indexing\retrieval-context.json"

$dynamicContextPath = "context\claude-runtime\exports\dynamic-engineering-context.json"

$outputPath = "context\active-runtime-context.json"

if (!(Test-Path $evolutionPath)) {

    Write-Host "Missing architecture evolution history."
    exit
}

$evolution = Get-Content $evolutionPath -Raw | ConvertFrom-Json

$retrieval = Get-Content $retrievalPath -Raw | ConvertFrom-Json

$dynamicContext = Get-Content $dynamicContextPath -Raw | ConvertFrom-Json

$latestEvolution = $evolution |
    Select-Object -Last 1

$activeContext = [PSCustomObject]@{

    generatedAt = (Get-Date).ToString("s")

    activeOperationalState = [PSCustomObject]@{

        highestPriorityModule = (
            $retrieval.engineeringFocus.highestPriorityModule
        )

        primaryRuntime = (
            $dynamicContext.operationalState.primaryRuntime
        )

        orchestrationScripts = (
            $latestEvolution.architectureState.orchestrationScripts
        )

        topologyZones = (
            $latestEvolution.architectureState.topologyZones
        )
    }

    activeEngineeringFocus = [PSCustomObject]@{

        operationalFocus = (
            $retrieval.engineeringFocus.operationalFocus
        )

        engineeringDirectives = (
            $dynamicContext.engineeringDirectives
        )
    }

    criticalRuntimeSystems = (
        $dynamicContext.criticalInfrastructure.modules |
        Select-Object module, importanceScore, classification
    )

    cognitionCapabilities = [PSCustomObject]@{

        retrievalAware = (
            $latestEvolution.cognitionState.retrievalAware
        )

        runtimeRankingEnabled = (
            $latestEvolution.cognitionState.runtimeRankingEnabled
        )

        dynamicContextAssembly = (
            $latestEvolution.cognitionState.dynamicContextAssembly
        )

        orchestrationIntelligence = (
            $latestEvolution.cognitionState.orchestrationIntelligence
        )
    }
}

$activeContext |
    ConvertTo-Json -Depth 30 |
    Set-Content $outputPath

Write-Host ""
Write-Host "Active runtime context generated:"
Write-Host $outputPath
Write-Host ""
