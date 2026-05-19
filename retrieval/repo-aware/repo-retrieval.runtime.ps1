Write-Host ""
Write-Host "AI-Automation-OS :: Repo Retrieval Runtime"
Write-Host ""

$cognitionPath = "infrastructure\repo-intelligence\exports\repo-cognition-export.json"

$outputPath = "retrieval\repo-aware\indexing\retrieval-context.json"

if (!(Test-Path $cognitionPath)) {

    Write-Host "Missing repo cognition export."
    exit
}

$cognition = Get-Content $cognitionPath -Raw | ConvertFrom-Json

$importanceRanking = $cognition.runtimeImportanceRanking

$topology = $cognition.topology

$criticalModules = $importanceRanking |
    Sort-Object importanceScore -Descending |
    Select-Object -First 10

$criticalZones = $topology.zones |
    Where-Object {
        $_.classification -match "runtime|retrieval|memory|workflow"
    } |
    Sort-Object totalFiles -Descending

$retrievalPacket = [PSCustomObject]@{

    generatedAt = (Get-Date).ToString("s")

    retrievalPriority = [PSCustomObject]@{

        criticalModules = $criticalModules

        criticalZones = $criticalZones
    }

    engineeringFocus = [PSCustomObject]@{

        primaryRuntime = "orchestration-runtime"

        highestPriorityModule = (
            $criticalModules |
            Select-Object -First 1
        ).module

        operationalFocus = @(
            "execution orchestration",
            "runtime supervision",
            "pipeline coordination",
            "repo cognition",
            "retrieval-aware infrastructure"
        )
    }
}

$retrievalPacket |
    ConvertTo-Json -Depth 25 |
    Set-Content $outputPath

Write-Host ""
Write-Host "Retrieval context generated:"
Write-Host $outputPath
Write-Host ""
