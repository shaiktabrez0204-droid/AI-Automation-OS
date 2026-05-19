param(
    [string]$PropagationPath = ".\propagation\workflow-propagation.json",

    [string]$SourceWorkflow = "",
    [string]$TargetWorkflow = "",

    [string]$ExecutionId = "",

    [string]$PropagationType = "",
    [string]$TriggerEvent = "",

    [string]$Runtime = "",
    [string]$Stage = "",

    [int]$PropagationDepth = 0
)

function New-PropagationState {

    return @{

        generated_at = (Get-Date).ToString("o")

        propagation_rules = @()

        propagation_history = @()

        active_propagations = @()

        propagation_metrics = @{

            total_propagations = 0
            successful_propagations = 0
            blocked_propagations = 0

            max_depth_observed = 0

            unique_workflows = @()
            unique_runtimes = @()
        }
    }
}

function Initialize-PropagationState {

    param($Path)

    $state = New-PropagationState

    $state |
        ConvertTo-Json -Depth 20 |
        Set-Content $Path

    return $state
}

function Get-PropagationState {

    param($Path)

    if (!(Test-Path $Path)) {
        return Initialize-PropagationState -Path $Path
    }

    try {

        $raw = Get-Content $Path -Raw

        if ([string]::IsNullOrWhiteSpace($raw)) {
            return Initialize-PropagationState -Path $Path
        }

        $parsed = $raw | ConvertFrom-Json -AsHashtable

        if ($null -eq $parsed) {
            return Initialize-PropagationState -Path $Path
        }

        return $parsed
    }
    catch {

        Write-Host ""
        Write-Host "PROPAGATION STATE CORRUPTED — REBUILDING"
        Write-Host ""

        return Initialize-PropagationState -Path $Path
    }
}

function Save-PropagationState {

    param(
        $StateObject,
        $Path
    )

    $StateObject.generated_at = (Get-Date).ToString("o")

    $StateObject |
        ConvertTo-Json -Depth 20 |
        Set-Content $Path
}

function Test-PropagationAllowed {

    param(
        $PropagationDepth
    )

    $MAX_DEPTH = 5

    if ($PropagationDepth -ge $MAX_DEPTH) {
        return $false
    }

    return $true
}

function Register-Propagation {

    param(
        $StateObject,

        $SourceWorkflow,
        $TargetWorkflow,

        $ExecutionId,

        $PropagationType,
        $TriggerEvent,

        $Runtime,
        $Stage,

        $PropagationDepth
    )

    $allowed = Test-PropagationAllowed `
        -PropagationDepth $PropagationDepth

    $propagationRecord = @{

        propagation_id = [guid]::NewGuid().ToString()

        timestamp = (Get-Date).ToString("o")

        source_workflow = $SourceWorkflow
        target_workflow = $TargetWorkflow

        execution_id = $ExecutionId

        propagation_type = $PropagationType
        trigger_event = $TriggerEvent

        runtime = $Runtime
        stage = $Stage

        propagation_depth = $PropagationDepth

        allowed = $allowed
    }

    $StateObject.propagation_history += $propagationRecord

    $StateObject.propagation_metrics.total_propagations += 1

    if ($allowed) {

        $StateObject.active_propagations += $propagationRecord

        $StateObject.propagation_metrics.successful_propagations += 1

        Write-Host ""
        Write-Host "PROPAGATION ACCEPTED"
        Write-Host ""
    }
    else {

        $StateObject.propagation_metrics.blocked_propagations += 1

        Write-Host ""
        Write-Host "PROPAGATION BLOCKED — DEPTH LIMIT"
        Write-Host ""
    }

    if (
        $PropagationDepth -gt
        $StateObject.propagation_metrics.max_depth_observed
    ) {

        $StateObject.propagation_metrics.max_depth_observed =
            $PropagationDepth
    }

    if (
        $SourceWorkflow -ne "" -and
        $SourceWorkflow -notin
        $StateObject.propagation_metrics.unique_workflows
    ) {

        $StateObject.propagation_metrics.unique_workflows +=
            $SourceWorkflow
    }

    if (
        $TargetWorkflow -ne "" -and
        $TargetWorkflow -notin
        $StateObject.propagation_metrics.unique_workflows
    ) {

        $StateObject.propagation_metrics.unique_workflows +=
            $TargetWorkflow
    }

    if (
        $Runtime -ne "" -and
        $Runtime -notin
        $StateObject.propagation_metrics.unique_runtimes
    ) {

        $StateObject.propagation_metrics.unique_runtimes +=
            $Runtime
    }

    return $StateObject
}

$stateObject = Get-PropagationState `
    -Path $PropagationPath

$stateObject = Register-Propagation `
    -StateObject $stateObject `
    -SourceWorkflow $SourceWorkflow `
    -TargetWorkflow $TargetWorkflow `
    -ExecutionId $ExecutionId `
    -PropagationType $PropagationType `
    -TriggerEvent $TriggerEvent `
    -Runtime $Runtime `
    -Stage $Stage `
    -PropagationDepth $PropagationDepth

Save-PropagationState `
    -StateObject $stateObject `
    -Path $PropagationPath
