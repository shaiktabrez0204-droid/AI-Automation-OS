$script:DistributedStateFile = ".\distributed-runtime-state\distributed-runtime-state.json"

function Get-CapabilityState {

    if (-not (Test-Path $script:DistributedStateFile)) {
        throw "Distributed state file missing."
    }

    return Get-Content $script:DistributedStateFile -Raw | ConvertFrom-Json
}

function Save-CapabilityState {
    param(
        [Parameter(Mandatory=$true)]
        $State
    )

    $State.lastUpdatedUtc = (Get-Date).ToUniversalTime().ToString("o")

    $State |
        ConvertTo-Json -Depth 100 |
        Set-Content $script:DistributedStateFile
}

function Register-RuntimeCapability {
    param(
        [string]$AgentId,
        [string[]]$Capabilities
    )

    $state = Get-CapabilityState

    $agent = $state.activeAgents |
        Where-Object { $_.agentId -eq $AgentId }

    if (-not $agent) {
        throw "Agent not found: $AgentId"
    }

    $agent | Add-Member `
        -MemberType NoteProperty `
        -Name capabilities `
        -Value $Capabilities `
        -Force

    Save-CapabilityState -State $state

    Write-Host "[runtime-capability] capabilities registered: $AgentId"
}

function Get-RuntimeCapabilities {

    $state = Get-CapabilityState

    return $state.activeAgents |
        Select-Object `
            agentId,
            agentType,
            runtimeRole,
            state,
            capabilities
}

function Test-DelegationEligibility {
    param(
        [string]$AgentId,
        [string]$RequiredCapability
    )

    $state = Get-CapabilityState

    $agent = $state.activeAgents |
        Where-Object { $_.agentId -eq $AgentId }

    if (-not $agent) {
        return $false
    }

    if ($agent.state -ne "active") {
        return $false
    }

    return $agent.capabilities -contains $RequiredCapability
}

Export-ModuleMember -Function `
    Get-CapabilityState,
    Save-CapabilityState,
    Register-RuntimeCapability,
    Get-RuntimeCapabilities,
    Test-DelegationEligibility
