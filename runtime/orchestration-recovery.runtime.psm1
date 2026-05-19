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

function Invoke-OrchestrationRecovery {

    $state = Get-RecoveryState

    foreach ($task in $state.executionQueue) {

        if ($task.status -eq "executing") {

            $relatedSession = $state.executionSessions |

                Where-Object {
                    $_.taskId -eq $task.taskId
                } |

                Select-Object -First 1

            if (-not $relatedSession) {

                $task.status = "recovery-required"

                Write-Host "[orchestration-recovery] orphaned execution detected: $($task.taskId)"
            }

            elseif ($relatedSession.sessionState -eq "completed") {

                $task.status = "completed"

                $task.executionCompletedUtc = $relatedSession.completedUtc

                Write-Host "[orchestration-recovery] execution reconciled: $($task.taskId)"
            }
        }
    }

    Save-RecoveryState -State $state

    Write-Host "[orchestration-recovery] recovery cycle completed"
}

function Get-RecoveryRequiredTasks {

    $state = Get-RecoveryState

    return $state.executionQueue |

        Where-Object {
            $_.status -eq "recovery-required"
        }
}

Export-ModuleMember -Function `
    Get-RecoveryState,
    Save-RecoveryState,
    Invoke-OrchestrationRecovery,
    Get-RecoveryRequiredTasks
