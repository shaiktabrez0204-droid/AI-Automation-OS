param(
    [string]$RepositoryRoot = ".",
    [string]$OutputRoot = ".\repository-cognition"
)

$ErrorActionPreference = "Stop"

function Get-RepositoryFiles {
    param([string]$Root)

    Get-ChildItem -Path $Root -Recurse -File |
    Where-Object {
        $_.FullName -notmatch "\\node_modules\\" -and
        $_.FullName -notmatch "\\.git\\" -and
        $_.FullName -notmatch "\\bin\\" -and
        $_.FullName -notmatch "\\obj\\"
    }
}

function Get-FileHashMap {
    param([array]$Files)

    $hashes = @()

    foreach ($file in $Files) {
        try {
            $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256

            $hashes += [PSCustomObject]@{
                Path = $file.FullName
                Hash = $hash.Hash
                Size = $file.Length
                Extension = $file.Extension
                LastWriteTime = $file.LastWriteTimeUtc
            }
        }
        catch {
            Write-Warning "Failed hashing: $($file.FullName)"
        }
    }

    return $hashes
}

function Build-RepositoryManifest {
    param(
        [array]$Files,
        [array]$Hashes
    )

    [PSCustomObject]@{
        RepositoryId = [guid]::NewGuid().Guid
        GeneratedAt = (Get-Date).ToUniversalTime()
        FileCount = $Files.Count
        TotalBytes = ($Files | Measure-Object Length -Sum).Sum
        Extensions = (
            $Files |
            Group-Object Extension |
            Sort-Object Count -Descending |
            Select-Object Name, Count
        )
        Hashes = $Hashes
    }
}

Write-Host ""
Write-Host "======================================="
Write-Host "REPOSITORY COGNITION INITIALIZATION"
Write-Host "======================================="
Write-Host ""

$files = Get-RepositoryFiles -Root $RepositoryRoot

Write-Host "[repository-files] $($files.Count)"

$hashes = Get-FileHashMap -Files $files

$manifest = Build-RepositoryManifest `
    -Files $files `
    -Hashes $hashes

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "manifests\repository-manifest-$timestamp.json"

$manifest |
ConvertTo-Json -Depth 10 |
Set-Content $outputFile

Write-Host ""
Write-Host "[manifest-written] $outputFile"
Write-Host ""
