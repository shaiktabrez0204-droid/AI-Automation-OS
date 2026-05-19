Write-Host ""
Write-Host "AI-Automation-OS :: Repo Intelligence Runtime"
Write-Host ""

$topologyPath = "infrastructure\repo-intelligence\topology\topology-map.json"

$relationshipPath = "infrastructure\repo-intelligence\topology\module-relationships.json"

$registryPath = "infrastructure\repo-intelligence\topology\runtime-registry.json"

$exportPath = "infrastructure\repo-intelligence\exports\repo-cognition-export.json"

$topology = Get-Content $topologyPath -Raw | ConvertFrom-Json

$relationshipsRaw = Get-Content $relationshipPath -Raw | ConvertFrom-Json

$registry = Get-Content $registryPath -Raw | ConvertFrom-Json

if ($relationshipsRaw.value) {
    $relationships = $relationshipsRaw.value
}
else {
    $relationships = $relationshipsRaw
}

$runtimeImportance = @()

foreach ($module in $registry.runtimeModules) {

    $importanceScore = 0

    $importanceScore += ($module.dependencies.Count * 10)

    switch ($module.classification) {

        "core-execution-runtime" {
            $importanceScore += 100
        }

        "runtime-dispatch" {
            $importanceScore += 80
        }

        "pipeline-orchestration" {
            $importanceScore += 70
        }

        "runtime-supervision" {
            $importanceScore += 60
        }

        "async-orchestration" {
            $importanceScore += 50
        }

        "observability" {
            $importanceScore += 30
        }
    }

    $runtimeImportance += @{
        module = $module.module
        classification = $module.classification
        importanceScore = $importanceScore
        role = $module.role
    }
}

$runtimeImportance = $runtimeImportance |
    Sort-Object importanceScore -Descending

$runtimeSummary = @{
    generatedAt = (Get-Date).ToString("s")

    topologyZones = $topology.zones.Count

    orchestrationScripts = (
        $topology.zones |
        Where-Object {
            $_.classification -eq "orchestration-runtime"
        }
    ).totalFiles

    runtimeModules = (
        $registry.runtimeModules |
        Measure-Object
    ).Count
}

$export = @{
    runtimeSummary = $runtimeSummary

    topology = $topology

    relationships = $relationships

    runtimeRegistry = $registry

    runtimeImportanceRanking = $runtimeImportance
}

$export |
    ConvertTo-Json -Depth 25 |
    Set-Content $exportPath

Write-Host ""
Write-Host "Repo cognition export generated:"
Write-Host $exportPath
Write-Host ""
