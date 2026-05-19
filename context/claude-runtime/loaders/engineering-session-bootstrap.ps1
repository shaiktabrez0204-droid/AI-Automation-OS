Write-Host ""
Write-Host "AI-Automation-OS :: Engineering Session Bootstrap"
Write-Host ""

$activeContextPath = "context\active-runtime-context.json"

$outputPath = "context\session-context.md"

if (!(Test-Path $activeContextPath)) {

    Write-Host "Missing active runtime context."
    exit
}

$activeContext = Get-Content $activeContextPath -Raw | ConvertFrom-Json

$highestPriorityModule = $activeContext.activeOperationalState.highestPriorityModule

$primaryRuntime = $activeContext.activeOperationalState.primaryRuntime

$orchestrationScripts = $activeContext.activeOperationalState.orchestrationScripts

$topologyZones = $activeContext.activeOperationalState.topologyZones

$focusAreas = (
    $activeContext.activeEngineeringFocus.operationalFocus
) -join ", "

$directives = (
    $activeContext.activeEngineeringFocus.engineeringDirectives
) -join "`n- "

$criticalSystems = (
    $activeContext.criticalRuntimeSystems |
    ForEach-Object {
        "- $($_.module) [$($_.classification)] Score=$($_.importanceScore)"
    }
) -join "`n"

$bootstrap = @"
# AI-Automation-OS :: Engineering Session Context

## Operational State

- Primary Runtime: $primaryRuntime
- Highest Priority Module: $highestPriorityModule
- Orchestration Scripts: $orchestrationScripts
- Topology Zones: $topologyZones

## Operational Focus

$focusAreas

## Engineering Directives

- $directives

## Critical Runtime Systems

$criticalSystems

## Cognition Capabilities

- Retrieval-Aware Cognition Enabled
- Runtime Ranking Enabled
- Dynamic Context Assembly Enabled
- Orchestration Intelligence Enabled

## Session Objective

Maintain operational continuity.
Prioritize orchestration-critical systems.
Preserve retrieval-aware cognition integrity.
Prevent architecture drift.
"@

$bootstrap |
    Set-Content $outputPath

Write-Host ""
Write-Host "Engineering session bootstrap generated:"
Write-Host $outputPath
Write-Host ""
