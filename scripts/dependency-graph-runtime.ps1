param(
    [string]$GraphFile
)

Write-Host ""
Write-Host "====================================="
Write-Host " Dependency Graph Runtime"
Write-Host "====================================="
Write-Host ""

if (-not (Test-Path $GraphFile)) {

    Write-Host "[ERROR] Graph file missing."
    exit 1
}

$Content = Get-Content $GraphFile

$WorkflowGraph = @()

$currentWorkflow = $null

foreach ($Line in $Content) {

    $Trimmed = $Line.Trim()

    if ($Trimmed.StartsWith("- id:")) {

        if ($currentWorkflow -ne $null) {
            $WorkflowGraph += $currentWorkflow
        }

        $WorkflowId = $Trimmed.Replace("- id: ", "")

        $currentWorkflow = @{
            id = $WorkflowId
            depends_on = @()
            completed = $false
        }
    }

    elseif ($Trimmed.StartsWith("- ") -and `
        -not $Trimmed.StartsWith("- id:")) {

        $Dependency = $Trimmed.Replace("- ", "")

        if ($currentWorkflow -ne $null) {
            $currentWorkflow.depends_on += $Dependency
        }
    }
}

if ($currentWorkflow -ne $null) {
    $WorkflowGraph += $currentWorkflow
}

$ExecutionProgress = $true

while ($ExecutionProgress) {

    $ExecutionProgress = $false

    foreach ($Workflow in $WorkflowGraph) {

        if ($Workflow.completed -eq $true) {
            continue
        }

        $DependenciesSatisfied = $true

        foreach ($Dependency in $Workflow.depends_on) {

            $DependencyWorkflow = $WorkflowGraph | Where-Object {
                $_.id -eq $Dependency
            }

            if ($DependencyWorkflow.completed -ne $true) {

                $DependenciesSatisfied = $false
            }
        }

        if ($DependenciesSatisfied) {

            Write-Host "[EXECUTING]"
            Write-Host $Workflow.id
            Write-Host ""

            Start-Sleep -Seconds 2

            $RandomNumber = Get-Random -Minimum 1 -Maximum 10

            if ($RandomNumber -le 2) {

                Write-Host "[FAILED]"
                Write-Host $Workflow.id

                Write-Host ""
                Write-Host "[GRAPH EXECUTION STOPPED]"
                exit 1
            }

            Write-Host "[COMPLETED]"
            Write-Host $Workflow.id
            Write-Host ""

            $Workflow.completed = $true

            $ExecutionProgress = $true
        }
    }
}

$Incomplete = $WorkflowGraph | Where-Object {
    $_.completed -ne $true
}

if ($Incomplete.Count -gt 0) {

    Write-Host "[WARNING] Unresolved dependency graph detected."

    $Incomplete | Format-Table
}
else {

    Write-Host "[SUCCESS] Dependency graph execution completed."
}
