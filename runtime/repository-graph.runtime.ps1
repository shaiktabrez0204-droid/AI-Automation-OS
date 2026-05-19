param(
    [string]$RepositoryRoot = ".",
    [string]$OutputRoot = ".\repository-cognition"
)

$ErrorActionPreference = "Stop"

function Get-PackageFiles {
    param([string]$Root)

    Get-ChildItem -Path $Root -Recurse -File |
    Where-Object {
        $_.Name -in @(
            "package.json",
            "requirements.txt",
            "Cargo.toml",
            "go.mod",
            "pom.xml"
        )
    }
}

function Parse-PackageJson {
    param([string]$Path)

    try {
        $content = Get-Content $Path -Raw | ConvertFrom-Json

        return [PSCustomObject]@{
            File = $Path
            Type = "node"
            Dependencies = @(
                $content.dependencies.PSObject.Properties.Name +
                $content.devDependencies.PSObject.Properties.Name
            ) | Sort-Object -Unique
        }
    }
    catch {
        Write-Warning "Failed parsing package.json: $Path"
    }
}

function Parse-Requirements {
    param([string]$Path)

    try {
        $deps = Get-Content $Path |
        Where-Object {
            $_ -and $_ -notmatch "^#"
        } |
        ForEach-Object {
            ($_ -split "==")[0]
        }

        return [PSCustomObject]@{
            File = $Path
            Type = "python"
            Dependencies = $deps
        }
    }
    catch {
        Write-Warning "Failed parsing requirements.txt: $Path"
    }
}

function Build-DependencyGraph {
    param([array]$PackageFiles)

    $graph = @()

    foreach ($file in $PackageFiles) {

        switch ($file.Name) {

            "package.json" {
                $parsed = Parse-PackageJson -Path $file.FullName
                if ($parsed) { $graph += $parsed }
            }

            "requirements.txt" {
                $parsed = Parse-Requirements -Path $file.FullName
                if ($parsed) { $graph += $parsed }
            }
        }
    }

    return $graph
}

Write-Host ""
Write-Host "======================================="
Write-Host "DEPENDENCY GRAPH COGNITION"
Write-Host "======================================="
Write-Host ""

$packageFiles = Get-PackageFiles `
    -Root $RepositoryRoot

Write-Host "[package-files] $($packageFiles.Count)"

$graph = Build-DependencyGraph `
    -PackageFiles $packageFiles

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "graph\dependency-graph\dependency-graph-$timestamp.json"

$graph |
ConvertTo-Json -Depth 10 |
Set-Content $outputFile

Write-Host ""
Write-Host "[dependency-graph-written] $outputFile"
Write-Host ""
