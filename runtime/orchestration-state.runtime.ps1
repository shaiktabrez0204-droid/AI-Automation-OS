param(
    [string]$StatePath = ".\state\orchestration-state.json",
    [string]$ExecutionId = "",
    [string]$Workflow = "",
    [string]$State = "",
    [string]$Stage = "",
    [string]$Runtime = "",
    [string]$Event = ""
)

function New-OrchestrationState {

    return @{
        generated_at = (Get-Date).ToString("o")

        orchestration = @{
            active_executions = @()
            active_workflows  = @()
            runtime_stages    = @()
            active_events     = @()
        }

        execution_state = @{
            pending   = @()
            running   = @()
            completed = @()
            failed    = @()
        }

        runtime_coordination = @{
            supervisors = @()
            propagations = @()
            dependencies = @()
        }

        telemetry = @{
            transitions = @()
            state_events = @()
        }
    }
}

function Initialize-OrchestrationState {

    param($Path)

    $state = New-OrchestrationState

    $state |
        ConvertTo-Json -Depth 20 |
        Set-Content $Path

    return $state
}

function Get-OrchestrationState {

    param($Path)

    if (!(Test-Path $Path)) {
        return Initialize-OrchestrationState -Path $Path
    }

    try {

        $raw = Get-Content $Path -Raw

        if ([string]::IsNullOrWhiteSpace($raw)) {
            return Initialize-OrchestrationState -Path $Path
        }

        $parsed = $raw | ConvertFrom-Json -AsHashtable

        if ($null -eq $parsed) {
            return Initialize-OrchestrationState -Path $Path
        }

        return $parsed
    }
    catch {

        Write-Host ""
        Write-Host "STATE FILE CORRUPTED — REBUILDING"
        Write-Host ""

        return Initialize-OrchestrationState -Path $Path
    }
}

function Save-OrchestrationState {

    param(
        $StateObject,
        $Path
    )

    $StateObject.generated_at = (Get-Date).ToString("o")

    $StateObject |
        ConvertTo-Json -Depth 20 |
        Set-Content $Path
}

function Register-StateTransition {

    param(
        $StateObject,
        $ExecutionId,
        $Workflow,
        $State,
        $Stage,
        $Runtime,
        $Event
    )

    $transition = @{
        timestamp = (Get-Date).ToString("o")
        execution_id = $ExecutionId
        workflow = $Workflow
        state = $State
        stage = $Stage
        runtime = $Runtime
        event = $Event
    }

    $StateObject.telemetry.transitions += $transition

    switch ($State) {

        "PENDING" {
            $StateObject.execution_state.pending += $ExecutionId
        }

        "RUNNING" {
            $StateObject.execution_state.running += $ExecutionId
        }

        "COMPLETED" {
            $StateObject.execution_state.completed += $ExecutionId
        }

        "FAILED" {
            $StateObject.execution_state.failed += $ExecutionId
        }
    }

    if ($ExecutionId -ne "") {
        $StateObject.orchestration.active_executions += $ExecutionId
    }

    if ($Workflow -ne "") {
        $StateObject.orchestration.active_workflows += $Workflow
    }

    if ($Event -ne "") {
        $StateObject.orchestration.active_events += $Event
    }

    if ($Stage -ne "") {
        $StateObject.orchestration.runtime_stages += $Stage
    }

    return $StateObject
}

$stateObject = Get-OrchestrationState `
    -Path $StatePath

$stateObject = Register-StateTransition `
    -StateObject $stateObject `
    -ExecutionId $ExecutionId `
    -Workflow $Workflow `
    -State $State `
    -Stage $Stage `
    -Runtime $Runtime `
    -Event $Event

Save-OrchestrationState `
    -StateObject $stateObject `
    -Path $StatePath

Write-Host ""
Write-Host "ORCHESTRATION STATE UPDATED"
Write-Host ""
