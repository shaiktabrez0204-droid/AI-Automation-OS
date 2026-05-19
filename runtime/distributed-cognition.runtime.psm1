$script:StateFile = ".\distributed-runtime-state\distributed-runtime-state.json"

function Get-DistributedRuntimeState {

    if (-not (Test-Path $script:StateFile)) {
        throw "Distributed runtime state file missing."
    }

    return Get-Content $script:StateFile -Raw | ConvertFrom-Json
}

function Save-DistributedRuntimeState {
    param(
        [Parameter(Mandatory=$true)]
        $State
    )

    $State.lastUpdatedUtc = (Get-Date).ToUniversalTime().ToString("o")

    $State |
        ConvertTo-Json -Depth 100 |
        Set-Content $script:StateFile
}

function Register-AgentRuntime {
    param(
        [string]$AgentId,
        [string]$AgentType,
        [string]$RuntimeRole
    )

    $state = Get-DistributedRuntimeState

    $agent = @{
        agentId = $AgentId
        agentType = $AgentType
        runtimeRole = $RuntimeRole
        state = "idle"
        lastHeartbeatUtc = (Get-Date).ToUniversalTime().ToString("o")
    }

    $state.activeAgents += $agent

    Save-DistributedRuntimeState -State $state

    Write-Host "[distributed-cognition] registered agent: $AgentId"
}

function Get-ActiveAgents {

    $state = Get-DistributedRuntimeState

    return $state.activeAgents
}

Export-ModuleMember -Function `
    Get-DistributedRuntimeState,
    Save-DistributedRuntimeState,
    Register-AgentRuntime,
    Get-ActiveAgents
