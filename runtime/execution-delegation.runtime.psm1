$script:DistributedStateFile = ".\distributed-runtime-state\distributed-runtime-state.json"

function Get-DelegationState {

    if (-not (Test-Path $script:DistributedStateFile)) {
        throw "Distributed state file missing."
    }

    return Get-Content $script:DistributedStateFile -Raw | ConvertFrom-Json
}

function Save-DelegationState {
    param(
        [Parameter(Mandatory=$true)]
        $State
    )

    $State.lastUpdatedUtc = (Get-Date).ToUniversalTime().ToString("o")

    $State |
        ConvertTo-Json -Depth 100 |
        Set-Content $script:DistributedStateFile
}

function New-ExecutionDelegation {
    param(
        [string]$DelegationId,
        [string]$ExecutionType,
        [string]$SourceRuntime,
        [string]$TargetRuntime
    )

    $state = Get-DelegationState

    $delegation = @{
        delegationId = $DelegationId
        executionType = $ExecutionType
        sourceRuntime = $SourceRuntime
        targetRuntime = $TargetRuntime
        status = "pending"
        createdUtc = (Get-Date).ToUniversalTime().ToString("o")
    }

    $state.executionDelegations += $delegation

    Save-DelegationState -State $state

    Write-Host "[execution-delegation] delegation created: $DelegationId"
}

function Approve-ExecutionDelegation {
    param(
        [string]$DelegationId
    )

    $state = Get-DelegationState

    $delegation = $state.executionDelegations |
        Where-Object { $_.delegationId -eq $DelegationId }

    if (-not $delegation) {
        throw "Delegation not found: $DelegationId"
    }

    $delegation.status = "approved"

    Save-DelegationState -State $state

    Write-Host "[execution-delegation] delegation approved: $DelegationId"
}

function Get-ExecutionDelegations {

    $state = Get-DelegationState

    return $state.executionDelegations
}

Export-ModuleMember -Function `
    Get-DelegationState,
    Save-DelegationState,
    New-ExecutionDelegation,
    Approve-ExecutionDelegation,
    Get-ExecutionDelegations
