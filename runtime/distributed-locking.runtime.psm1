$script:DistributedStateFile = ".\distributed-runtime-state\distributed-runtime-state.json"

function Get-LockingState {

    if (-not (Test-Path $script:DistributedStateFile)) {
        throw "Distributed state file missing."
    }

    return Get-Content $script:DistributedStateFile -Raw | ConvertFrom-Json
}

function Save-LockingState {
    param(
        [Parameter(Mandatory=$true)]
        $State
    )

    $State.lastUpdatedUtc = (Get-Date).ToUniversalTime().ToString("o")

    $State |
        ConvertTo-Json -Depth 100 |
        Set-Content $script:DistributedStateFile
}

function Initialize-DistributedLocks {

    $state = Get-LockingState

    if (-not $state.distributedLocks) {

        $state | Add-Member `
            -MemberType NoteProperty `
            -Name distributedLocks `
            -Value @()
    }

    Save-LockingState -State $state

    Write-Host "[distributed-locking] lock registry initialized"
}

function Acquire-DistributedLock {
    param(
        [string]$ResourceId,
        [string]$RuntimeId,
        [int]$LockTimeoutSeconds = 30
    )

    $state = Get-LockingState

    $existingLock = $state.distributedLocks |

        Where-Object {
            $_.resourceId -eq $ResourceId
        } |

        Where-Object {
            $_.lockState -eq "active"
        } |

        Select-Object -First 1

    if ($existingLock) {

        $expirationUtc = (
            Get-Date $existingLock.expiresUtc
        ).ToUniversalTime()

        if ($expirationUtc -gt (Get-Date).ToUniversalTime()) {

            Write-Host (
                "[distributed-locking] lock denied: " +
                $ResourceId
            )

            return $false
        }

        $existingLock.lockState = "expired"
    }

    $lock = @{
        lockId = [guid]::NewGuid().ToString()

        resourceId = $ResourceId

        runtimeId = $RuntimeId

        lockState = "active"

        acquiredUtc = (
            Get-Date
        ).ToUniversalTime().ToString("o")

        expiresUtc = (
            (Get-Date).ToUniversalTime()
        ).AddSeconds(
            $LockTimeoutSeconds
        ).ToString("o")
    }

    $state.distributedLocks += $lock

    Save-LockingState -State $state

    Write-Host (
        "[distributed-locking] lock acquired: " +
        $ResourceId
    )

    return $true
}

function Release-DistributedLock {
    param(
        [string]$ResourceId,
        [string]$RuntimeId
    )

    $state = Get-LockingState

    $lock = $state.distributedLocks |

        Where-Object {
            $_.resourceId -eq $ResourceId
        } |

        Where-Object {
            $_.runtimeId -eq $RuntimeId
        } |

        Where-Object {
            $_.lockState -eq "active"
        } |

        Select-Object -First 1

    if (-not $lock) {

        Write-Host (
            "[distributed-locking] no active lock: " +
            $ResourceId
        )

        return
    }

    $lock.lockState = "released"

    Save-LockingState -State $state

    Write-Host (
        "[distributed-locking] lock released: " +
        $ResourceId
    )
}

function Get-DistributedLocks {

    $state = Get-LockingState

    return $state.distributedLocks
}

Export-ModuleMember -Function `
    Get-LockingState,
    Save-LockingState,
    Initialize-DistributedLocks,
    Acquire-DistributedLock,
    Release-DistributedLock,
    Get-DistributedLocks
