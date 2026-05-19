$script:DistributedStateFile = ".\distributed-runtime-state\distributed-runtime-state.json"

function Get-FederationState {

    if (-not (Test-Path $script:DistributedStateFile)) {
        throw "Distributed state file missing."
    }

    return Get-Content $script:DistributedStateFile -Raw | ConvertFrom-Json
}

function Save-FederationState {
    param(
        [Parameter(Mandatory=$true)]
        $State
    )

    $State.lastUpdatedUtc = (Get-Date).ToUniversalTime().ToString("o")

    $State |
        ConvertTo-Json -Depth 100 |
        Set-Content $script:DistributedStateFile
}

function Initialize-FederationCoordination {

    $state = Get-FederationState

    if (-not $state.federationVotes) {

        $state | Add-Member `
            -MemberType NoteProperty `
            -Name federationVotes `
            -Value @()
    }

    Save-FederationState -State $state

    Write-Host "[federation-coordination] coordination initialized"
}

function Start-FederationVote {
    param(
        [string]$VoteId,
        [string]$VoteTopic,
        [string[]]$Participants
    )

    $state = Get-FederationState

    $vote = @{
        voteId = $VoteId

        voteTopic = $VoteTopic

        participants = $Participants

        votes = @()

        voteState = "active"

        createdUtc = (
            Get-Date
        ).ToUniversalTime().ToString("o")
    }

    $state.federationVotes += $vote

    Save-FederationState -State $state

    Write-Host "[federation-coordination] vote started: $VoteId"
}

function Submit-FederationVote {
    param(
        [string]$VoteId,
        [string]$RuntimeId,
        [string]$Decision
    )

    $state = Get-FederationState

    $vote = $state.federationVotes |

        Where-Object {
            $_.voteId -eq $VoteId
        } |

        Select-Object -First 1

    if (-not $vote) {
        throw "Vote not found."
    }

    $vote.votes += @{
        runtimeId = $RuntimeId
        decision = $Decision

        submittedUtc = (
            Get-Date
        ).ToUniversalTime().ToString("o")
    }

    if ($vote.votes.Count -ge $vote.participants.Count) {

        $vote.voteState = "completed"
    }

    Save-FederationState -State $state

    Write-Host "[federation-coordination] vote submitted: $RuntimeId"
}

function Get-FederationVotes {

    $state = Get-FederationState

    return $state.federationVotes
}

Export-ModuleMember -Function `
    Get-FederationState,
    Save-FederationState,
    Initialize-FederationCoordination,
    Start-FederationVote,
    Submit-FederationVote,
    Get-FederationVotes
