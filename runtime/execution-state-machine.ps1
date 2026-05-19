param(
    [string]$StateMachinePath = ".\state\execution-state-machine.json",
    [string]$ExecutionId = "",
    [string]$CurrentState = "",
    [string]$NextState = "",
    [string]$Workflow = "",
    [string]$Runtime = ""
)

function New-StateMachine {

    return @{
        generated_at = (Get-Date).ToString("o")

        valid_transitions = @{
            PENDING = @(
                "RUNNING"
            )

            RUNNING = @(
                "COMPLETED",
                "FAILED",
                "RETRYING"
            )

            FAILED = @(
                "RETRYING"
            )

            RETRYING = @(
                "RUNNING",
                "FAILED"
            )

            COMPLETED = @()
        }

        execution_transitions = @()

        transition_metrics = @{
            total_transitions = 0
            invalid_transitions = 0
            successful_transitions = 0
        }
    }
}

function Initialize-StateMachine {

    param($Path)

    $state = New-StateMachine

    $state |
        ConvertTo-Json -Depth 20 |
        Set-Content $Path

    return $state
}

function Get-StateMachine {

    param($Path)

    if (!(Test-Path $Path)) {
        return Initialize-StateMachine -Path $Path
    }

    try {

        $raw = Get-Content $Path -Raw

        if ([string]::IsNullOrWhiteSpace($raw)) {
            return Initialize-StateMachine -Path $Path
        }

        $parsed = $raw | ConvertFrom-Json -AsHashtable

        if ($null -eq $parsed) {
            return Initialize-StateMachine -Path $Path
        }

        return $parsed
    }
    catch {

        Write-Host ""
        Write-Host "STATE MACHINE CORRUPTED — REBUILDING"
        Write-Host ""

        return Initialize-StateMachine -Path $Path
    }
}

function Save-StateMachine {

    param(
        $StateObject,
        $Path
    )

    $StateObject.generated_at = (Get-Date).ToString("o")

    $StateObject |
        ConvertTo-Json -Depth 20 |
        Set-Content $Path
}

function Test-StateTransition {

    param(
        $StateObject,
        $CurrentState,
        $NextState
    )

    $validTransitions =
        $StateObject.valid_transitions[$CurrentState]

    if ($null -eq $validTransitions) {
        return $false
    }

    return $NextState -in $validTransitions
}

function Register-Transition {

    param(
        $StateObject,
        $ExecutionId,
        $CurrentState,
        $NextState,
        $Workflow,
        $Runtime
    )

    $isValid = Test-StateTransition `
        -StateObject $StateObject `
        -CurrentState $CurrentState `
        -NextState $NextState

    $transition = @{
        timestamp = (Get-Date).ToString("o")

        execution_id = $ExecutionId

        current_state = $CurrentState
        next_state = $NextState

        workflow = $Workflow
        runtime = $Runtime

        valid = $isValid
    }

    $StateObject.execution_transitions += $transition

    $StateObject.transition_metrics.total_transitions += 1

    if ($isValid) {

        $StateObject.transition_metrics.successful_transitions += 1

        Write-Host ""
        Write-Host "VALID STATE TRANSITION"
        Write-Host ""
    }
    else {

        $StateObject.transition_metrics.invalid_transitions += 1

        Write-Host ""
        Write-Host "INVALID STATE TRANSITION"
        Write-Host ""
    }

    return $StateObject
}

$stateObject = Get-StateMachine `
    -Path $StateMachinePath

$stateObject = Register-Transition `
    -StateObject $stateObject `
    -ExecutionId $ExecutionId `
    -CurrentState $CurrentState `
    -NextState $NextState `
    -Workflow $Workflow `
    -Runtime $Runtime

Save-StateMachine `
    -StateObject $stateObject `
    -Path $StateMachinePath
