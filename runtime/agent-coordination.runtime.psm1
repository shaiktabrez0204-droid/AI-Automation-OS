$script:DistributedStateFile = ".\distributed-runtime-state\distributed-runtime-state.json"

function Get-CoordinationState {

    if (-not (Test-Path $script:DistributedStateFile)) {
        throw "Distributed state file missing."
    }

    return Get-Content $script:DistributedStateFile -Raw | ConvertFrom-Json
}

function Save-CoordinationState {
    param(
        [Parameter(Mandatory=$true)]
        $State
    )

    $State.lastUpdatedUtc = (Get-Date).ToUniversalTime().ToString("o")

    $State |
        ConvertTo-Json -Depth 100 |
        Set-Content $script:DistributedStateFile
}

function Update-AgentHeartbeat {
    param(
        [string]$AgentId
    )

    $state = Get-CoordinationState

    $agent = $state.activeAgents |
        Where-Object { $_.agentId -eq $AgentId }

    if (-not $agent) {
        throw "Agent not registered: $AgentId"
    }

    $agent.lastHeartbeatUtc = (Get-Date).ToUniversalTime().ToString("o")
    $agent.state = "active"

    $state.distributedTelemetry.runtimeSynchronizations += 1

    Save-CoordinationState -State $state

    Write-Host "[agent-coordination] heartbeat updated: $AgentId"
}

function Get-StaleAgents {
    param(
        [int]$TimeoutSeconds = 60
    )

    $state = Get-CoordinationState

    $threshold = (Get-Date).ToUniversalTime().AddSeconds(-$TimeoutSeconds)

    return $state.activeAgents | Where-Object {

        ([datetime]$_.lastHeartbeatUtc) -lt $threshold
    }
}

function Sync-DistributedRuntime {

    $state = Get-CoordinationState

    $state.distributedTelemetry.coordinationCycles += 1

    Save-CoordinationState -State $state

    Write-Host "[agent-coordination] distributed runtime synchronized"
}

function Invoke-AgentStateArbitration {
    param(
        [int]$TimeoutSeconds = 60
    )

    $state = Get-CoordinationState

    $threshold = (Get-Date).ToUniversalTime().AddSeconds(-$TimeoutSeconds)

    foreach ($agent in $state.activeAgents) {

        $heartbeat = [datetime]$agent.lastHeartbeatUtc

        if ($heartbeat -lt $threshold) {

            $agent.state = "stale"
        }
        else {

            $agent.state = "active"
        }
    }

    Save-CoordinationState -State $state

    Write-Host "[agent-coordination] arbitration completed"
}

Export-ModuleMember -Function `
    Get-CoordinationState,
    Save-CoordinationState,
    Update-AgentHeartbeat,
    Get-StaleAgents,
    Sync-DistributedRuntime,
    Invoke-AgentStateArbitration
