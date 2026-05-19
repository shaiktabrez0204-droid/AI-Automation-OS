param(

    [string]$PlanPath =
        ".\planning\execution-plan.json",

    [string]$OrchestrationStatePath =
        ".\state\orchestration-state.json",

    [string]$PropagationPath =
        ".\propagation\workflow-propagation.json",

    [string]$HealthPath =
        ".\health\runtime-health.json"
)

function New-ExecutionPlan {

    return @{

        generated_at =
            (Get-Date).ToString("o")

        execution_queue = @()

        planning_metrics = @{

            total_planned_executions = 0

            high_priority_executions = 0
            medium_priority_executions = 0
            low_priority_executions = 0
        }
    }
}

function Initialize-ExecutionPlan {

    param($Path)

    $state =
        New-ExecutionPlan

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

function Get-ExecutionPriority {

    param(
        $ExecutionId,
        $HealthState,
        $PropagationState
    )

    $priorityScore = 50

    $blocked =
        $PropagationState.propagation_metrics.blocked_propagations

    if ($blocked -gt 0) {
        $priorityScore += 10
    }

    $overallHealth =
        $HealthState.runtime_health.overall_health

    switch ($overallHealth) {

        "CRITICAL" {
            $priorityScore += 40
        }

        "DEGRADED" {
            $priorityScore += 20
        }

        "HEALTHY" {
            $priorityScore += 5
        }
    }

    if ($priorityScore -ge 80) {
        return "HIGH"
    }
    elseif ($priorityScore -ge 60) {
        return "MEDIUM"
    }
    else {
        return "LOW"
    }
}

function Register-ExecutionPlan {

    param(
        $PlanState,
        $ExecutionId,
        $Priority,
        $Workflow,
        $Stage
    )

    $plan = @{

        plan_id =
            [guid]::NewGuid().ToString()

        timestamp =
            (Get-Date).ToString("o")

        execution_id =
            $ExecutionId

        workflow =
            $Workflow

        stage =
            $Stage

        priority =
            $Priority
    }

    $PlanState.execution_queue +=
        $plan

    $PlanState.planning_metrics.total_planned_executions += 1

    switch ($Priority) {

        "HIGH" {
            $PlanState.planning_metrics.high_priority_executions += 1
        }

        "MEDIUM" {
            $PlanState.planning_metrics.medium_priority_executions += 1
        }

        "LOW" {
            $PlanState.planning_metrics.low_priority_executions += 1
        }
    }

    return $PlanState
}

$planState =
    Initialize-ExecutionPlan `
        -Path $PlanPath

$orchestrationState =
    Get-JsonState `
        -Path $OrchestrationStatePath

$propagationState =
    Get-JsonState `
        -Path $PropagationPath

$healthState =
    Get-JsonState `
        -Path $HealthPath

foreach (
    $executionId in
    $orchestrationState.orchestration.active_executions
) {

    $priority =
        Get-ExecutionPriority `
            -ExecutionId $executionId `
            -HealthState $healthState `
            -PropagationState $propagationState

    $workflow =
        $orchestrationState.orchestration.active_workflows[0]

    $stage =
        $orchestrationState.orchestration.runtime_stages[0]

    $planState =
        Register-ExecutionPlan `
            -PlanState $planState `
            -ExecutionId $executionId `
            -Priority $priority `
            -Workflow $workflow `
            -Stage $stage
}

$planState.generated_at =
    (Get-Date).ToString("o")

$planState |
    ConvertTo-Json -Depth 20 |
    Set-Content $PlanPath

Write-Host ""
Write-Host "EXECUTION PLANNING COMPLETE"
Write-Host ""
