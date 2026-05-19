param(

    [string]$SupervisionPath =
        ".\supervision\orchestration-supervision.json",

    [string]$OrchestrationStatePath =
        ".\state\orchestration-state.json",

    [string]$EventBusPath =
        ".\events\runtime-events.json",

    [string]$StateMachinePath =
        ".\state\execution-state-machine.json",

    [string]$PropagationPath =
        ".\propagation\workflow-propagation.json"
)

function New-SupervisionState {

    return @{

        generated_at = (Get-Date).ToString("o")

        supervision_summary = @{

            total_anomalies = 0
            invalid_transitions = 0
            blocked_propagations = 0
            failed_executions = 0
        }

        detected_anomalies = @()

        runtime_health = @{

            orchestration_health = "HEALTHY"
            propagation_health = "HEALTHY"
            execution_health = "HEALTHY"
        }
    }
}

function Initialize-SupervisionState {

    param($Path)

    $state = New-SupervisionState

    $state |
        ConvertTo-Json -Depth 20 |
        Set-Content $Path

    return $state
}

function Get-JsonState {

    param($Path)

    if (!(Test-Path $Path)) {
        return @{}
    }

    try {

        $raw = Get-Content $Path -Raw

        if ([string]::IsNullOrWhiteSpace($raw)) {
            return @{}
        }

        return $raw | ConvertFrom-Json -AsHashtable
    }
    catch {

        return @{}
    }
}

function Register-Anomaly {

    param(
        $StateObject,
        $Type,
        $Severity,
        $Details
    )

    $anomaly = @{

        anomaly_id =
            [guid]::NewGuid().ToString()

        timestamp =
            (Get-Date).ToString("o")

        type = $Type
        severity = $Severity
        details = $Details
    }

    $StateObject.detected_anomalies += $anomaly

    $StateObject.supervision_summary.total_anomalies += 1

    return $StateObject
}

function Analyze-StateMachine {

    param(
        $SupervisorState,
        $StateMachine
    )

    $invalidCount =
        $StateMachine.transition_metrics.invalid_transitions

    if ($invalidCount -gt 0) {

        $SupervisorState.supervision_summary.invalid_transitions =
            $invalidCount

        $SupervisorState.runtime_health.execution_health =
            "DEGRADED"

        $SupervisorState = Register-Anomaly `
            -StateObject $SupervisorState `
            -Type "INVALID_STATE_TRANSITIONS" `
            -Severity "HIGH" `
            -Details "$invalidCount invalid transitions detected"
    }

    return $SupervisorState
}

function Analyze-Propagation {

    param(
        $SupervisorState,
        $PropagationState
    )

    $blockedCount =
        $PropagationState.propagation_metrics.blocked_propagations

    if ($blockedCount -gt 0) {

        $SupervisorState.supervision_summary.blocked_propagations =
            $blockedCount

        $SupervisorState.runtime_health.propagation_health =
            "DEGRADED"

        $SupervisorState = Register-Anomaly `
            -StateObject $SupervisorState `
            -Type "BLOCKED_PROPAGATIONS" `
            -Severity "MEDIUM" `
            -Details "$blockedCount blocked propagations detected"
    }

    return $SupervisorState
}

function Analyze-Orchestration {

    param(
        $SupervisorState,
        $OrchestrationState
    )

    $failedExecutions =
        $OrchestrationState.execution_state.failed.Count

    if ($failedExecutions -gt 0) {

        $SupervisorState.supervision_summary.failed_executions =
            $failedExecutions

        $SupervisorState.runtime_health.orchestration_health =
            "DEGRADED"

        $SupervisorState = Register-Anomaly `
            -StateObject $SupervisorState `
            -Type "FAILED_EXECUTIONS" `
            -Severity "HIGH" `
            -Details "$failedExecutions failed executions detected"
    }

    return $SupervisorState
}

$supervisorState =
    Initialize-SupervisionState `
        -Path $SupervisionPath

$orchestrationState =
    Get-JsonState `
        -Path $OrchestrationStatePath

$eventBusState =
    Get-JsonState `
        -Path $EventBusPath

$stateMachineState =
    Get-JsonState `
        -Path $StateMachinePath

$propagationState =
    Get-JsonState `
        -Path $PropagationPath

$supervisorState = Analyze-StateMachine `
    -SupervisorState $supervisorState `
    -StateMachine $stateMachineState

$supervisorState = Analyze-Propagation `
    -SupervisorState $supervisorState `
    -PropagationState $propagationState

$supervisorState = Analyze-Orchestration `
    -SupervisorState $supervisorState `
    -OrchestrationState $orchestrationState

$supervisorState.generated_at =
    (Get-Date).ToString("o")

$supervisorState |
    ConvertTo-Json -Depth 20 |
    Set-Content $SupervisionPath

Write-Host ""
Write-Host "ORCHESTRATION SUPERVISION COMPLETE"
Write-Host ""
