param(
    [string]$EventPath = ".\events\runtime-events.json",
    [string]$EventType = "",
    [string]$ExecutionId = "",
    [string]$Workflow = "",
    [string]$Runtime = "",
    [string]$Stage = "",
    [string]$Source = "",
    [string]$Payload = ""
)

function New-EventBusState {

    return @{
        generated_at = (Get-Date).ToString("o")

        runtime_events = @()

        event_metrics = @{
            total_events = 0
            unique_workflows = @()
            unique_runtimes = @()
            unique_event_types = @()
        }
    }
}

function Initialize-EventBus {

    param($Path)

    $state = New-EventBusState

    $state |
        ConvertTo-Json -Depth 20 |
        Set-Content $Path

    return $state
}

function Get-EventBusState {

    param($Path)

    if (!(Test-Path $Path)) {
        return Initialize-EventBus -Path $Path
    }

    try {

        $raw = Get-Content $Path -Raw

        if ([string]::IsNullOrWhiteSpace($raw)) {
            return Initialize-EventBus -Path $Path
        }

        $parsed = $raw | ConvertFrom-Json -AsHashtable

        if ($null -eq $parsed) {
            return Initialize-EventBus -Path $Path
        }

        return $parsed
    }
    catch {

        Write-Host ""
        Write-Host "EVENT BUS CORRUPTED — REBUILDING"
        Write-Host ""

        return Initialize-EventBus -Path $Path
    }
}

function Save-EventBusState {

    param(
        $StateObject,
        $Path
    )

    $StateObject.generated_at = (Get-Date).ToString("o")

    $StateObject |
        ConvertTo-Json -Depth 20 |
        Set-Content $Path
}

function Publish-RuntimeEvent {

    param(
        $StateObject,
        $EventType,
        $ExecutionId,
        $Workflow,
        $Runtime,
        $Stage,
        $Source,
        $Payload
    )

    $event = @{
        event_id = [guid]::NewGuid().ToString()

        timestamp = (Get-Date).ToString("o")

        event_type = $EventType
        execution_id = $ExecutionId
        workflow = $Workflow
        runtime = $Runtime
        stage = $Stage
        source = $Source
        payload = $Payload
    }

    $StateObject.runtime_events += $event

    $StateObject.event_metrics.total_events += 1

    if (
        $Workflow -ne "" -and
        $Workflow -notin $StateObject.event_metrics.unique_workflows
    ) {
        $StateObject.event_metrics.unique_workflows += $Workflow
    }

    if (
        $Runtime -ne "" -and
        $Runtime -notin $StateObject.event_metrics.unique_runtimes
    ) {
        $StateObject.event_metrics.unique_runtimes += $Runtime
    }

    if (
        $EventType -ne "" -and
        $EventType -notin $StateObject.event_metrics.unique_event_types
    ) {
        $StateObject.event_metrics.unique_event_types += $EventType
    }

    return $StateObject
}

$stateObject = Get-EventBusState `
    -Path $EventPath

$stateObject = Publish-RuntimeEvent `
    -StateObject $stateObject `
    -EventType $EventType `
    -ExecutionId $ExecutionId `
    -Workflow $Workflow `
    -Runtime $Runtime `
    -Stage $Stage `
    -Source $Source `
    -Payload $Payload

Save-EventBusState `
    -StateObject $stateObject `
    -Path $EventPath

Write-Host ""
Write-Host "RUNTIME EVENT PUBLISHED"
Write-Host ""
