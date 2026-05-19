$script:DistributedStateFile = ".\distributed-runtime-state\distributed-runtime-state.json"

function Get-DeadlockState {

    if (-not (Test-Path $script:DistributedStateFile)) {
        throw "Distributed state file missing."
    }

    return Get-Content $script:DistributedStateFile -Raw | ConvertFrom-Json
}

function Save-DeadlockState {
    param(
        [Parameter(Mandatory=$true)]
        $State
    )

    $State.lastUpdatedUtc = (Get-Date).ToUniversalTime().ToString("o")

    $State |
        ConvertTo-Json -Depth 100 |
        Set-Content $script:DistributedStateFile
}

function Initialize-DeadlockDetection {

    $state = Get-DeadlockState

    if (-not $state.deadlockEvents) {

        $state | Add-Member `
            -MemberType NoteProperty `
            -Name deadlockEvents `
            -Value @()
    }

    Save-DeadlockState -State $state

    Write-Host "[deadlock-detection] detection initialized"
}

function Invoke-DeadlockDetection {

    $state = Get-DeadlockState

    $activeLocks = $state.distributedLocks |

        Where-Object {
            $_.lockState -eq "active"
        }

    $runtimeLockMap = @{}

    foreach ($lock in $activeLocks) {

        if (-not $runtimeLockMap.ContainsKey($lock.runtimeId)) {

            $runtimeLockMap[$lock.runtimeId] = @()
        }

        $runtimeLockMap[$lock.runtimeId] += $lock.resourceId
    }

    foreach ($runtimeId in $runtimeLockMap.Keys) {

        $heldLocks = $runtimeLockMap[$runtimeId]

        if ($heldLocks.Count -gt 1) {

            $deadlockEvent = @{
                deadlockId = [guid]::NewGuid().ToString()

                runtimeId = $runtimeId

                heldResources = $heldLocks

                detectionUtc = (
                    Get-Date
                ).ToUniversalTime().ToString("o")

                deadlockState = "suspected"
            }

            $state.deadlockEvents += $deadlockEvent

            Write-Host (
                "[deadlock-detection] suspected deadlock: " +
                $runtimeId
            )
        }
    }

    Save-DeadlockState -State $state

    Write-Host "[deadlock-detection] detection cycle completed"
}

function Get-DeadlockEvents {

    $state = Get-DeadlockState

    return $state.deadlockEvents
}

Export-ModuleMember -Function `
    Get-DeadlockState,
    Save-DeadlockState,
    Initialize-DeadlockDetection,
    Invoke-DeadlockDetection,
    Get-DeadlockEvents
