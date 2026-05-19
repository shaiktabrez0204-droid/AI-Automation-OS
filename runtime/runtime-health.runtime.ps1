param(

    [string]$HealthPath =
        ".\health\runtime-health.json",

    [string]$OrchestrationStatePath =
        ".\state\orchestration-state.json",

    [string]$EventBusPath =
        ".\events\runtime-events.json",

    [string]$StateMachinePath =
        ".\state\execution-state-machine.json",

    [string]$PropagationPath =
        ".\propagation\workflow-propagation.json",

    [string]$SupervisionPath =
        ".\supervision\orchestration-supervision.json"
)

function New-HealthState {

    return @{

        generated_at =
            (Get-Date).ToString("o")

        runtime_health = @{

            overall_health = "HEALTHY"

            orchestration_score = 100
            execution_score = 100
            propagation_score = 100
            supervision_score = 100
            event_score = 100
        }

        degradation_signals = @()

        runtime_metrics = @{

            total_events = 0
            total_transitions = 0
            invalid_transitions = 0

            total_propagations = 0
            blocked_propagations = 0

            active_executions = 0

            anomaly_count = 0
        }
    }
}

function Initialize-HealthState {

    param($Path)

    $state = New-HealthState

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

        $raw =
            Get-Content $Path -Raw

        if ([string]::IsNullOrWhiteSpace($raw)) {
            return @{}
        }

        return $raw |
            ConvertFrom-Json -AsHashtable
    }
    catch {

        return @{}
    }
}

function Register-Degradation {

    param(
        $HealthState,
        $Type,
        $Severity,
        $Impact
    )

    $signal = @{

        signal_id =
            [guid]::NewGuid().ToString()

        timestamp =
            (Get-Date).ToString("o")

        type = $Type
        severity = $Severity
        impact = $Impact
    }

    $HealthState.degradation_signals +=
        $signal

    return $HealthState
}

function Analyze-ExecutionHealth {

    param(
        $HealthState,
        $StateMachine
    )

    $invalidTransitions =
        $StateMachine.transition_metrics.invalid_transitions

    $totalTransitions =
        $StateMachine.transition_metrics.total_transitions

    $HealthState.runtime_metrics.invalid_transitions =
        $invalidTransitions

    $HealthState.runtime_metrics.total_transitions =
        $totalTransitions

    if ($invalidTransitions -gt 0) {

        $penalty =
            ($invalidTransitions * 10)

        $HealthState.runtime_health.execution_score -=
            $penalty

        $HealthState = Register-Degradation `
            -HealthState $HealthState `
            -Type "INVALID_TRANSITIONS" `
            -Severity "HIGH" `
            -Impact "-$penalty execution score"
    }

    return $HealthState
}

function Analyze-PropagationHealth {

    param(
        $HealthState,
        $PropagationState
    )

    $blocked =
        $PropagationState.propagation_metrics.blocked_propagations

    $total =
        $PropagationState.propagation_metrics.total_propagations

    $HealthState.runtime_metrics.total_propagations =
        $total

    $HealthState.runtime_metrics.blocked_propagations =
        $blocked

    if ($blocked -gt 0) {

        $penalty =
            ($blocked * 15)

        $HealthState.runtime_health.propagation_score -=
            $penalty

        $HealthState = Register-Degradation `
            -HealthState $HealthState `
            -Type "BLOCKED_PROPAGATIONS" `
            -Severity "MEDIUM" `
            -Impact "-$penalty propagation score"
    }

    return $HealthState
}

function Analyze-EventHealth {

    param(
        $HealthState,
        $EventBus
    )

    $totalEvents =
        $EventBus.event_metrics.total_events

    $HealthState.runtime_metrics.total_events =
        $totalEvents

    if ($totalEvents -gt 1000) {

        $HealthState.runtime_health.event_score -=
            20

        $HealthState = Register-Degradation `
            -HealthState $HealthState `
            -Type "HIGH_EVENT_VOLUME" `
            -Severity "MEDIUM" `
            -Impact "-20 event score"
    }

    return $HealthState
}

function Analyze-OrchestrationHealth {

    param(
        $HealthState,
        $OrchestrationState
    )

    $activeExecutions =
        $OrchestrationState.orchestration.active_executions.Count

    $HealthState.runtime_metrics.active_executions =
        $activeExecutions

    if ($activeExecutions -gt 50) {

        $HealthState.runtime_health.orchestration_score -=
            25

        $HealthState = Register-Degradation `
            -HealthState $HealthState `
            -Type "EXECUTION_PRESSURE" `
            -Severity "HIGH" `
            -Impact "-25 orchestration score"
    }

    return $HealthState
}

function Analyze-SupervisionHealth {

    param(
        $HealthState,
        $SupervisionState
    )

    $anomalies =
        $SupervisionState.supervision_summary.total_anomalies

    $HealthState.runtime_metrics.anomaly_count =
        $anomalies

    if ($anomalies -gt 0) {

        $penalty =
            ($anomalies * 10)

        $HealthState.runtime_health.supervision_score -=
            $penalty

        $HealthState = Register-Degradation `
            -HealthState $HealthState `
            -Type "RUNTIME_ANOMALIES" `
            -Severity "HIGH" `
            -Impact "-$penalty supervision score"
    }

    return $HealthState
}

function Finalize-OverallHealth {

    param(
        $HealthState
    )

    $scores = @(
        $HealthState.runtime_health.orchestration_score
        $HealthState.runtime_health.execution_score
        $HealthState.runtime_health.propagation_score
        $HealthState.runtime_health.supervision_score
        $HealthState.runtime_health.event_score
    )

    $average =
        ($scores | Measure-Object -Average).Average

    if ($average -ge 90) {

        $HealthState.runtime_health.overall_health =
            "HEALTHY"
    }
    elseif ($average -ge 70) {

        $HealthState.runtime_health.overall_health =
            "DEGRADED"
    }
    else {

        $HealthState.runtime_health.overall_health =
            "CRITICAL"
    }

    return $HealthState
}

$healthState =
    Initialize-HealthState `
        -Path $HealthPath

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

$supervisionState =
    Get-JsonState `
        -Path $SupervisionPath

$healthState = Analyze-ExecutionHealth `
    -HealthState $healthState `
    -StateMachine $stateMachineState

$healthState = Analyze-PropagationHealth `
    -HealthState $healthState `
    -PropagationState $propagationState

$healthState = Analyze-EventHealth `
    -HealthState $healthState `
    -EventBus $eventBusState

$healthState = Analyze-OrchestrationHealth `
    -HealthState $healthState `
    -OrchestrationState $orchestrationState

$healthState = Analyze-SupervisionHealth `
    -HealthState $healthState `
    -SupervisionState $supervisionState

$healthState = Finalize-OverallHealth `
    -HealthState $healthState

$healthState.generated_at =
    (Get-Date).ToString("o")

$healthState |
    ConvertTo-Json -Depth 20 |
    Set-Content $HealthPath

Write-Host ""
Write-Host "RUNTIME HEALTH ANALYSIS COMPLETE"
Write-Host ""
