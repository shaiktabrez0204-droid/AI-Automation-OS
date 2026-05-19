param(
    [string]$RootPath = "."
)

Write-Host ""
Write-Host "AI-Automation-OS :: Repository Topology Scanner"
Write-Host ""

$topology = @{
    generatedAt = (Get-Date).ToString("s")
    root = (Resolve-Path $RootPath).Path
    zones = @()
}

$zoneMappings = @{
    "runtime"        = "execution-runtime"
    "scripts"        = "orchestration-runtime"
    "memory"         = "operational-memory"
    "retrieval"      = "retrieval-infrastructure"
    "context"        = "ai-context-runtime"
    "workflows"      = "workflow-infrastructure"
    "infrastructure" = "meta-runtime-infrastructure"
    "telemetry"      = "observability"
    "executions"     = "execution-artifacts"
}

$directories = Get-ChildItem -Path $RootPath -Directory

foreach ($directory in $directories) {

    $zoneName = $directory.Name

    $classification = if ($zoneMappings.ContainsKey($zoneName)) {
        $zoneMappings[$zoneName]
    }
    else {
        "unclassified"
    }

    $files = Get-ChildItem $directory.FullName -Recurse -File -ErrorAction SilentlyContinue

    $zone = @{
        zone = $zoneName
        classification = $classification
        path = $directory.FullName
        totalFiles = $files.Count
        fileTypes = @()
        sampleFiles = @()
    }

    $extensions = $files |
        Group-Object Extension |
        Sort-Object Count -Descending

    foreach ($ext in $extensions) {

        $zone.fileTypes += @{
            extension = if ($ext.Name) { $ext.Name } else { "[none]" }
            count = $ext.Count
        }
    }

    $zone.sampleFiles = $files |
        Select-Object -First 10 |
        ForEach-Object {
            $_.FullName.Replace((Resolve-Path $RootPath).Path, "").TrimStart("\")
        }

    $topology.zones += $zone
}

$outputPath = "infrastructure\repo-intelligence\topology\topology-map.json"

$topology | ConvertTo-Json -Depth 10 |
    Set-Content $outputPath

Write-Host ""
Write-Host "Topology map generated:"
Write-Host $outputPath
Write-Host ""
