Write-Host ""
Write-Host "AI-Automation-OS :: Execution Graph Runtime"
Write-Host ""

$registryPath = "infrastructure\repo-intelligence\topology\runtime-registry.json"

$outputPath = "runtime\state\execution-graph.json"

if (!(Test-Path $registryPath)) {

    Write-Host "Missing runtime registry."
    exit
}

$registry = Get-Content $registryPath -Raw | ConvertFrom-Json

$executionNodes = @()

$executionEdges = @()

foreach ($module in $registry.runtimeModules) {

    $node = [PSCustomObject]@{

        module = $module.module

        classification = $module.classification

        role = $module.role

        dependencyCount = $module.dependencies.Count
    }

    $executionNodes += $node

    foreach ($dependency in $module.dependencies) {

        $edge = [PSCustomObject]@{

            source = $module.module

            target = $dependency

            relationship = "runtime-dependency"
        }

        $executionEdges += $edge
    }
}

$coreExecutionFlow = @(
    "execution-dispatcher.ps1",
    "execution-runtime.ps1",
    "queue-runtime.ps1",
    "pipeline-runtime.ps1",
    "runtime-supervisor.ps1",
    "telemetry-runtime.ps1"
)

$executionGraph = [PSCustomObject]@{

    generatedAt = (Get-Date).ToString("s")

    executionGraph = [PSCustomObject]@{

        nodes = $executionNodes

        edges = $executionEdges
    }

    orchestrationFlow = [PSCustomObject]@{

        primaryExecutionPath = $coreExecutionFlow

        orchestrationType = "AI-native orchestration runtime"

        executionPriority = "orchestration-critical"
    }

    runtimeTopology = [PSCustomObject]@{

        totalNodes = $executionNodes.Count

        totalEdges = $executionEdges.Count

        orchestrationModules = (
            $executionNodes |
            Where-Object {
                $_.classification -match "runtime|orchestration|dispatch"
            }
        ).Count
    }
}

$executionGraph |
    ConvertTo-Json -Depth 30 |
    Set-Content $outputPath

Write-Host ""
Write-Host "Execution graph generated:"
Write-Host $outputPath
Write-Host ""
