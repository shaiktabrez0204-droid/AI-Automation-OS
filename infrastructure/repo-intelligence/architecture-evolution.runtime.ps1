Write-Host ""
Write-Host "AI-Automation-OS :: Architecture Evolution Runtime"
Write-Host ""

$cognitionPath = "infrastructure\repo-intelligence\exports\repo-cognition-export.json"

$retrievalPath = "retrieval\repo-aware\indexing\retrieval-context.json"

$dynamicContextPath = "context\claude-runtime\exports\dynamic-engineering-context.json"

$historyPath = "memory\implementation-history\architecture-evolution.json"

if (!(Test-Path $cognitionPath)) {

    Write-Host "Missing cognition export."
    exit
}

$cognition = Get-Content $cognitionPath -Raw | ConvertFrom-Json

$retrieval = Get-Content $retrievalPath -Raw | ConvertFrom-Json

$dynamicContext = Get-Content $dynamicContextPath -Raw | ConvertFrom-Json

$evolutionSnapshot = [PSCustomObject]@{

    timestamp = (Get-Date).ToString("s")

    architectureState = [PSCustomObject]@{

        topologyZones = $cognition.runtimeSummary.topologyZones

        runtimeModules = $cognition.runtimeSummary.runtimeModules

        orchestrationScripts = $cognition.runtimeSummary.orchestrationScripts

        highestPriorityModule = $retrieval.engineeringFocus.highestPriorityModule
    }

    cognitionState = [PSCustomObject]@{

        cognitionEnabled = $true

        retrievalAware = $true

        runtimeRankingEnabled = $true

        dynamicContextAssembly = $true

        orchestrationIntelligence = $true
    }

    infrastructureFocus = $dynamicContext.engineeringDirectives

    criticalSystems = (
        $retrieval.retrievalPriority.criticalModules |
        Select-Object module, importanceScore
    )
}

$history = @()

if (Test-Path $historyPath) {

    $existing = Get-Content $historyPath -Raw

    if (![string]::IsNullOrWhiteSpace($existing)) {

        $parsed = $existing | ConvertFrom-Json

        if ($parsed -is [System.Array]) {

            $history = $parsed
        }
        else {

            $history = @($parsed)
        }
    }
}

$history += $evolutionSnapshot

$history |
    ConvertTo-Json -Depth 30 |
    Set-Content $historyPath

Write-Host ""
Write-Host "Architecture evolution snapshot recorded:"
Write-Host $historyPath
Write-Host ""

