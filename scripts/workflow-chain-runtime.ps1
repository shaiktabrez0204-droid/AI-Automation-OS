param(
    [string]$ChainFile
)

Write-Host ""
Write-Host "====================================="
Write-Host " Workflow Chain Runtime"
Write-Host "====================================="
Write-Host ""

if (-not (Test-Path $ChainFile)) {

    Write-Host "[ERROR] Chain file missing."
    exit 1
}

$Content = Get-Content $ChainFile

$ChainEntries = @()

foreach ($Line in $Content) {

    if ($Line.Trim().StartsWith("- workflow:")) {

        $Workflow = $Line.Trim().Replace("- workflow: ", "")

        $ChainEntries += [PSCustomObject]@{
            workflow = $Workflow
        }
    }
}

for ($i = 0; $i -lt $ChainEntries.Count; $i++) {

    $CurrentWorkflow = $ChainEntries[$i].workflow

    Write-Host "[EXECUTING]"
    Write-Host $CurrentWorkflow

    Start-Sleep -Seconds 2

    $RandomNumber = Get-Random -Minimum 1 -Maximum 10

    if ($RandomNumber -le 2) {

        Write-Host "[FAILED]"
        Write-Host $CurrentWorkflow

        Write-Host ""
        Write-Host "[CHAIN STOPPED]"
        exit 1
    }

    Write-Host "[COMPLETED]"
    Write-Host $CurrentWorkflow
    Write-Host ""

    if ($i -lt ($ChainEntries.Count - 1)) {

        $NextWorkflow = $ChainEntries[$i + 1].workflow

        Write-Host "[CHAINING TO]"
        Write-Host $NextWorkflow
        Write-Host ""
    }
}

Write-Host "[SUCCESS] Workflow chain completed."
