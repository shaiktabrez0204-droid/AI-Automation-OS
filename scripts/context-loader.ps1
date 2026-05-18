param(
    [string[]]$Modes = @("architecture")
)

$ExportFile = "exports/combined-context.txt"

Clear-Content $ExportFile -ErrorAction SilentlyContinue

$LoadedFiles = @{}

function Add-ToExport($Path, $Mode, $Priority) {

    if ($LoadedFiles.ContainsKey($Path)) {

        Write-Host "Skipping Duplicate: $Path"
        return
    }

    $LoadedFiles[$Path] = $true

    Add-Content $ExportFile "`n=================================================="
    Add-Content $ExportFile "FILE: $Path"
    Add-Content $ExportFile "PROFILE: $Mode"
    Add-Content $ExportFile "PRIORITY: $Priority"
    Add-Content $ExportFile "ROLE: Operational Context"
    Add-Content $ExportFile "==================================================`n"

    Get-Content $Path | Add-Content $ExportFile
}

Write-Host ""
Write-Host "=================================================="
Write-Host " AI-Automation-OS Priority Context Loader"
Write-Host "=================================================="
Write-Host ""

foreach ($Mode in $Modes) {

    $ProfilePath = "context/profiles/$Mode.json"

    if (!(Test-Path $ProfilePath)) {

        Write-Host "Profile not found: $Mode"
        continue
    }

    Write-Host "Loading Profile: $Mode"

    $Profile = Get-Content $ProfilePath | ConvertFrom-Json

    foreach ($File in $Profile.files) {

        Add-ToExport $File.path $Mode $File.priority
    }
}

Write-Host ""
Write-Host "Context export completed."
Write-Host "Export File: $ExportFile"
Write-Host ""
