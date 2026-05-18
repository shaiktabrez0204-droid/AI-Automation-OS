param(
    [string]$ChainFile
)

$ArtifactFile = "runtime\artifacts\workflow-output.json"

Write-Host ""
Write-Host "====================================="
Write-Host " Workflow Output Runtime"
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

        $ChainEntries += $Workflow
    }
}

$PreviousOutput = $null

foreach ($Workflow in $ChainEntries) {

    Write-Host "[EXECUTING]"
    Write-Host $Workflow
    Write-Host ""

    if ($PreviousOutput -ne $null) {

        Write-Host "[INPUT RECEIVED]"
        Write-Host $PreviousOutput
        Write-Host ""
    }

    Start-Sleep -Seconds 2

    $RandomNumber = Get-Random -Minimum 1 -Maximum 10

    if ($RandomNumber -le 2) {

        Write-Host "[FAILED]"
        Write-Host $Workflow

        Write-Host ""
        Write-Host "[CHAIN STOPPED]"
        exit 1
    }

    $WorkflowOutput = @{
        workflow = $Workflow
        output = "generated-output-from-$Workflow"
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }

    $WorkflowOutput | ConvertTo-Json -Depth 10 | `
        Set-Content $ArtifactFile

    $PreviousOutput = Get-Content $ArtifactFile -Raw

    Write-Host "[OUTPUT GENERATED]"
    Write-Host $PreviousOutput
    Write-Host ""

    Write-Host "[COMPLETED]"
    Write-Host $Workflow
    Write-Host ""
}

Write-Host "[SUCCESS] Workflow chain completed."
