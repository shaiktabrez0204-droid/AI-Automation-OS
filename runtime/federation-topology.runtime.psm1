$script:DistributedStateFile = ".\distributed-runtime-state\distributed-runtime-state.json"

function Get-TopologyState {

    if (-not (Test-Path $script:DistributedStateFile)) {
        throw "Distributed state file missing."
    }

    return Get-Content $script:DistributedStateFile -Raw | ConvertFrom-Json
}

function Save-TopologyState {
    param(
        [Parameter(Mandatory=$true)]
        $State
    )

    $State.lastUpdatedUtc = (Get-Date).ToUniversalTime().ToString("o")

    $State |
        ConvertTo-Json -Depth 100 |
        Set-Content $script:DistributedStateFile
}

function Initialize-FederationTopology {

    $state = Get-TopologyState

    if (-not $state.federationTopology) {

        $state | Add-Member `
            -MemberType NoteProperty `
            -Name federationTopology `
            -Value @()
    }

    Save-TopologyState -State $state

    Write-Host "[federation-topology] topology initialized"
}

function Register-TopologyRelationship {
    param(
        [string]$SourceRuntime,
        [string]$TargetRuntime,
        [string]$RelationshipType
    )

    $state = Get-TopologyState

    $relationship = @{
        relationshipId = [guid]::NewGuid().ToString()

        sourceRuntime = $SourceRuntime
        targetRuntime = $TargetRuntime

        relationshipType = $RelationshipType

        createdUtc = (
            Get-Date
        ).ToUniversalTime().ToString("o")
    }

    $state.federationTopology += $relationship

    Save-TopologyState -State $state

    Write-Host (
        "[federation-topology] relationship registered: " +
        $SourceRuntime +
        " -> " +
        $TargetRuntime
    )
}

function Get-FederationTopology {

    $state = Get-TopologyState

    return $state.federationTopology
}

function Get-RuntimeTopology {
    param(
        [string]$RuntimeId
    )

    $state = Get-TopologyState

    return $state.federationTopology |

        Where-Object {
            $_.sourceRuntime -eq $RuntimeId `
            -or `
            $_.targetRuntime -eq $RuntimeId
        }
}

Export-ModuleMember -Function `
    Get-TopologyState,
    Save-TopologyState,
    Initialize-FederationTopology,
    Register-TopologyRelationship,
    Get-FederationTopology,
    Get-RuntimeTopology
