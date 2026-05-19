param(
    [string]$ScriptsPath = "scripts"
)

Write-Host ""
Write-Host "AI-Automation-OS :: Stable Module Relationship Analyzer"
Write-Host ""

$relationshipList = New-Object System.Collections.Generic.List[Object]

$scripts = Get-ChildItem -Path $ScriptsPath -Filter *.ps1 -File

foreach ($script in $scripts) {

    Write-Host "Analyzing $($script.Name)"

    $content = Get-Content $script.FullName -Raw

    $dependencySet = New-Object System.Collections.Generic.HashSet[string]

    $patterns = @(
        '\b[\w\-]+\.ps1\b',
        'powershell\s+.*?\.ps1',
        '\.\\.*?\.ps1'
    )

    foreach ($pattern in $patterns) {

        $matches = [regex]::Matches($content, $pattern)

        foreach ($match in $matches) {

            $dependency = $match.Value.Trim()

            $dependency = $dependency.Replace('"', '')
            $dependency = $dependency.Replace("'", '')

            if (![string]::IsNullOrWhiteSpace($dependency)) {

                $null = $dependencySet.Add($dependency)
            }
        }
    }

    $dependencyArray = @()

foreach ($item in $dependencySet) {
    $dependencyArray += $item
}

    $dependencyFrequency = @()

    foreach ($dep in $dependencyArray) {

        $matchCount = ([regex]::Matches(
            $content,
            [regex]::Escape($dep)
        )).Count

        $dependencyFrequency += [PSCustomObject]@{
            dependency = $dep
            frequency = $matchCount
        }
    }

    $relationshipObject = [PSCustomObject]@{
        module = $script.Name

        path = $script.FullName

        dependencyCount = $dependencyArray.Count

        dependencies = $dependencyArray

        dependencyFrequency = $dependencyFrequency

        orchestrationRole = if ($script.Name -match "runtime|dispatcher|queue|pipeline") {
            "core-orchestration"
        }
        elseif ($script.Name -match "telemetry|registry") {
            "observability"
        }
        else {
            "standard-runtime"
        }
    }

    $relationshipList.Add($relationshipObject)
}

$outputPath = "infrastructure\repo-intelligence\topology\module-relationships.json"

$relationshipList |
    ConvertTo-Json -Depth 25 |
    Set-Content $outputPath

Write-Host ""
Write-Host "Stable module relationships generated:"
Write-Host $outputPath
Write-Host ""
