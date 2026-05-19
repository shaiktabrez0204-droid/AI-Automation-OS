$script:DistributedStateFile = ".\distributed-runtime-state\distributed-runtime-state.json"

function Get-ConsensusState {

    if (-not (Test-Path $script:DistributedStateFile)) {
        throw "Distributed state file missing."
    }

    return Get-Content $script:DistributedStateFile -Raw | ConvertFrom-Json
}

function Save-ConsensusState {
    param(
        [Parameter(Mandatory=$true)]
        $State
    )

    $State.lastUpdatedUtc = (Get-Date).ToUniversalTime().ToString("o")

    $State |
        ConvertTo-Json -Depth 100 |
        Set-Content $script:DistributedStateFile
}

function Start-OrchestrationConsensus {
    param(
        [string]$ConsensusId,
        [string[]]$Participants,
        [string]$ExecutionType
    )

    $state = Get-ConsensusState

    $consensus = @{
        consensusId = $ConsensusId
        executionType = $ExecutionType
        participants = $Participants
        approvals = @()
        status = "pending"
        createdUtc = (Get-Date).ToUniversalTime().ToString("o")
    }

    $state.runtimeConsensus = $consensus

    Save-ConsensusState -State $state

    Write-Host "[orchestration-consensus] consensus started: $ConsensusId"
}

function Approve-ConsensusVote {
    param(
        [string]$ConsensusId,
        [string]$AgentId
    )

    $state = Get-ConsensusState

    if ($state.runtimeConsensus.consensusId -ne $ConsensusId) {
        throw "Consensus not found."
    }

    $state.runtimeConsensus.approvals += $AgentId

    $approvalCount = $state.runtimeConsensus.approvals.Count
    $participantCount = $state.runtimeConsensus.participants.Count

    if ($approvalCount -ge $participantCount) {

        $state.runtimeConsensus.status = "approved"
    }

    Save-ConsensusState -State $state

    Write-Host "[orchestration-consensus] vote approved: $AgentId"
}

function Get-OrchestrationConsensus {

    $state = Get-ConsensusState

    return $state.runtimeConsensus
}

Export-ModuleMember -Function `
    Get-ConsensusState,
    Save-ConsensusState,
    Start-OrchestrationConsensus,
    Approve-ConsensusVote,
    Get-OrchestrationConsensus
