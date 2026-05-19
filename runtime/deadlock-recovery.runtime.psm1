$script:DistributedStateFile = ".\distributed-runtime-state\distributed-runtime-state.json"

function Get-RecoveryState {

    if (-not (Test-Path $script:DistributedStateFile)) {
        throw "Distributed state file missing."
    }

    return Get-Content $script:DistributedStateFile -Raw | ConvertFrom-Json
}

function Save-RecoveryState {
    param(
        [Parameter(Mandatory=$true)]
        $State
    )

    $State.lastUpdatedUtc = (Get-Date).ToUniversalTime().ToString("o")

    $State |
        ConvertTo-Json -Depth 100 |
        Set-Content $script:DistributedStateFile
}

function Invoke-DeadlockRecovery {

    $state = Get-RecoveryState

    $suspectedDeadlocks = $state.deadlockEvents |

        Where-Object {
            $_.deadlockState -eq "suspected"
        }

    foreach ($deadlock in $suspectedDeadlocks) {

        $activeLocks = $state.distributedLocks |

            Where-Object {
                $_.runtimeId -eq $deadlock.runtimeId
            } |

            Where-Object {
                $_.lockState -eq "active"
            }

        foreach ($lock in $activeLocks) {

            $lock.lockState = "force-released"

            Write-Host (
                "[deadlock-recovery] force released: " +
                $lock.resourceId
            )
        }

        $deadlock.deadlockState = "recovered"

        $deadlock.recoveredUtc = (
            Get-Date
        ).ToUniversalTime().ToString("o")

        Write-Host (
            "[deadlock-recovery] deadlock recovered: " +
            $deadlock.runtimeId
        )
    }

    Save-RecoveryState -State $state

    Write-Host "[deadlock-recovery] recovery cycle completed"
}

function Get-RecoveredDeadlocks {

    $state = Get-RecoveryState

    return $state.deadlockEvents |

        Where-Object {
            $_.deadlockState -eq "recovered"
        }
}

Export-ModuleMember -Function `
    Get-RecoveryState,
    Save-RecoveryState,
    Invoke-DeadlockRecovery,
    Get-RecoveredDeadlocks
