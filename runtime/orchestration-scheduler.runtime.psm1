$script:DistributedStateFile = ".\distributed-runtime-state\distributed-runtime-state.json"

function Get-SchedulerState {

    if (-not (Test-Path $script:DistributedStateFile)) {
        throw "Distributed state file missing."
    }

    return Get-Content $script:DistributedStateFile -Raw | ConvertFrom-Json
}

function Save-SchedulerState {
    param(
        [Parameter(Mandatory=$true)]
        $State
    )

    $State.lastUpdatedUtc = (Get-Date).ToUniversalTime().ToString("o")

    $State |
        ConvertTo-Json -Depth 100 |
        Set-Content $script:DistributedStateFile
}

function Add-ExecutionTask {
    param(
        [string]$TaskId,
        [string]$ExecutionType,
        [string]$RequiredCapability
    )

    $state = Get-SchedulerState

    $task = @{
        taskId = $TaskId
        executionType = $ExecutionType
        requiredCapability = $RequiredCapability

        status = "queued"
        assignedRuntime = $null

        executionStartedUtc = $null
        executionCompletedUtc = $null

        createdUtc = (
            Get-Date
        ).ToUniversalTime().ToString("o")
    }

    $state.executionQueue += $task

    Save-SchedulerState -State $state

    Write-Host (
        "[orchestration-scheduler] task queued: " +
        $TaskId
    )
}

function Get-RuntimeLoad {
    param(
        [string]$RuntimeId
    )

    $state = Get-SchedulerState

    return (
        $state.executionQueue |

        Where-Object {
            $_.assignedRuntime -eq $RuntimeId
        } |

        Where-Object {
            $_.status -in @("assigned","executing")
        }
    ).Count
}

function Get-RuntimePerformanceScore {
    param(
        [string]$RuntimeId
    )

    $state = Get-SchedulerState

    $record = $state.runtimeIntelligence |

        Where-Object {
            $_.runtimeId -eq $RuntimeId
        } |

        Select-Object -First 1

    if (-not $record) {
        return 0
    }

    return $record.performanceScore
}

function Get-RuntimeAffinityScore {
    param(
        [string]$RuntimeId,
        [string]$ExecutionType
    )

    switch ($ExecutionType) {

        "architecture-analysis" {

            if ($RuntimeId -like "*architecture*") {
                return 100
            }
        }

        "retrieval-analysis" {

            if ($RuntimeId -like "*retrieval*") {
                return 100
            }
        }

        "telemetry-processing" {

            if ($RuntimeId -like "*telemetry*") {
                return 100
            }
        }

        "runtime-analysis" {

            if ($RuntimeId -like "*execution*") {
                return 100
            }
        }
    }

    return 0
}

function Get-TopologyScore {
    param(
        [string]$RuntimeId,
        [string]$ExecutionType
    )

    $state = Get-SchedulerState

    $relationships = $state.federationTopology |

        Where-Object {
            $_.sourceRuntime -eq $RuntimeId `
            -or `
            $_.targetRuntime -eq $RuntimeId
        }

    $score = 0

    foreach ($relationship in $relationships) {

        switch ($ExecutionType) {

            "retrieval-analysis" {

                if ($relationship.relationshipType `
                    -eq "context-dependency") {

                    $score += 50
                }
            }

            "telemetry-processing" {

                if ($relationship.relationshipType `
                    -eq "telemetry-stream") {

                    $score += 50
                }
            }

            "runtime-analysis" {

                if ($relationship.relationshipType `
                    -eq "memory-coordination") {

                    $score += 50
                }
            }
        }
    }

    return $score
}

function Invoke-OrchestrationScheduling {

    $state = Get-SchedulerState

    foreach ($task in $state.executionQueue) {

        if ($task.status -ne "queued") {
            continue
        }

        $eligibleRuntimes = $state.activeAgents |

            Where-Object {
                $_.state -eq "active"
            } |

            Where-Object {
                $_.capabilities -contains `
                    $task.requiredCapability
            }

        if (-not $eligibleRuntimes) {
            continue
        }

        $selectedRuntime = $eligibleRuntimes |

            Sort-Object `
                @{ Expression = {
                    Get-RuntimeLoad `
                        -RuntimeId $_.agentId
                }},
                @{ Expression = {
                    -1 * (
                        Get-RuntimeAffinityScore `
                            -RuntimeId $_.agentId `
                            -ExecutionType `
                                $task.executionType
                    )
                }},
                @{ Expression = {
                    -1 * (
                        Get-TopologyScore `
                            -RuntimeId $_.agentId `
                            -ExecutionType `
                                $task.executionType
                    )
                }},
                @{ Expression = {
                    -1 * (
                        Get-RuntimePerformanceScore `
                            -RuntimeId $_.agentId
                    )
                }}

        $selectedRuntime = $selectedRuntime |
            Select-Object -First 1

        $task.assignedRuntime = `
            $selectedRuntime.agentId

        $task.status = "assigned"
    }

    Save-SchedulerState -State $state

    Write-Host (
        "[orchestration-scheduler] " +
        "topology-aware scheduling completed"
    )
}

function Get-ExecutionQueue {

    $state = Get-SchedulerState

    return $state.executionQueue
}

Export-ModuleMember -Function `
    Get-SchedulerState,
    Save-SchedulerState,
    Add-ExecutionTask,
    Get-RuntimeLoad,
    Get-RuntimePerformanceScore,
    Get-RuntimeAffinityScore,
    Get-TopologyScore,
    Invoke-OrchestrationScheduling,
    Get-ExecutionQueue
