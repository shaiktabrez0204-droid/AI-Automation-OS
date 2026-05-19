$script:DistributedStateFile = ".\distributed-runtime-state\distributed-runtime-state.json"

function Get-WorkerState {

    if (-not (Test-Path $script:DistributedStateFile)) {
        throw "Distributed state file missing."
    }

    return Get-Content $script:DistributedStateFile -Raw | ConvertFrom-Json
}

function Save-WorkerState {
    param(
        [Parameter(Mandatory=$true)]
        $State
    )

    $State.lastUpdatedUtc = (Get-Date).ToUniversalTime().ToString("o")

    $State |
        ConvertTo-Json -Depth 100 |
        Set-Content $script:DistributedStateFile
}

function Invoke-ExecutionWorker {
    param(
        [string]$RuntimeId
    )

    $state = Get-WorkerState

    $tasks = $state.executionQueue |

        Where-Object {
            $_.assignedRuntime -eq $RuntimeId
        } |

        Where-Object {
            $_.status -eq "assigned"
        }

    foreach ($task in $tasks) {

        $task.status = "executing"
        $task.executionStartedUtc = (
            Get-Date
        ).ToUniversalTime().ToString("o")

        Write-Host "[execution-worker] executing: $($task.taskId)"

        Start-Sleep -Seconds 2

        $task.status = "completed"
        $task.executionCompletedUtc = (
            Get-Date
        ).ToUniversalTime().ToString("o")

        $state.distributedTelemetry.eventsProcessed += 1

        Write-Host "[execution-worker] completed: $($task.taskId)"
    }

    Save-WorkerState -State $state
}

function Get-ExecutionTasksByStatus {
    param(
        [string]$Status
    )

    $state = Get-WorkerState

    return $state.executionQueue |

        Where-Object {
            $_.status -eq $Status
        }
}

Export-ModuleMember -Function `
    Get-WorkerState,
    Save-WorkerState,
    Invoke-ExecutionWorker,
    Get-ExecutionTasksByStatus
