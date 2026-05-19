$script:DistributedStateFile = ".\distributed-runtime-state\distributed-runtime-state.json"

function Get-SessionState {

    if (-not (Test-Path $script:DistributedStateFile)) {
        throw "Distributed state file missing."
    }

    return Get-Content $script:DistributedStateFile -Raw | ConvertFrom-Json
}

function Save-SessionState {
    param(
        [Parameter(Mandatory=$true)]
        $State
    )

    $State.lastUpdatedUtc = (Get-Date).ToUniversalTime().ToString("o")

    $State |
        ConvertTo-Json -Depth 100 |
        Set-Content $script:DistributedStateFile
}

function Initialize-ExecutionSessions {

    $state = Get-SessionState

    if (-not $state.executionSessions) {

        $state | Add-Member `
            -MemberType NoteProperty `
            -Name executionSessions `
            -Value @()
    }

    Save-SessionState -State $state

    Write-Host "[execution-session] session registry initialized"
}

function Start-ExecutionSession {
    param(
        [string]$TaskId,
        [string]$RuntimeId
    )

    $state = Get-SessionState

    $session = @{
        sessionId = [guid]::NewGuid().ToString()

        taskId = $TaskId
        runtimeId = $RuntimeId

        sessionState = "running"

        startedUtc = (
            Get-Date
        ).ToUniversalTime().ToString("o")

        completedUtc = $null

        executionEvents = @(
            @{
                eventType = "session.started"
                timestampUtc = (
                    Get-Date
                ).ToUniversalTime().ToString("o")
            }
        )
    }

    $state.executionSessions += $session

    Save-SessionState -State $state

    Write-Host "[execution-session] session started: $($session.sessionId)"

    return $session
}

function Add-ExecutionSessionEvent {
    param(
        [string]$SessionId,
        [string]$EventType,
        [hashtable]$Payload
    )

    $state = Get-SessionState

    $session = $state.executionSessions |

        Where-Object {
            $_.sessionId -eq $SessionId
        }

    if (-not $session) {
        throw "Execution session not found."
    }

    $event = @{
        eventType = $EventType

        timestampUtc = (
            Get-Date
        ).ToUniversalTime().ToString("o")

        payload = $Payload
    }

    $session.executionEvents += $event

    Save-SessionState -State $state

    Write-Host "[execution-session] event added: $EventType"
}

function Complete-ExecutionSession {
    param(
        [string]$SessionId
    )

    $state = Get-SessionState

    $session = $state.executionSessions |

        Where-Object {
            $_.sessionId -eq $SessionId
        }

    if (-not $session) {
        throw "Execution session not found."
    }

    $session.sessionState = "completed"

    $session.completedUtc = (
        Get-Date
    ).ToUniversalTime().ToString("o")

    $completionEvent = @{
        eventType = "session.completed"

        timestampUtc = (
            Get-Date
        ).ToUniversalTime().ToString("o")
    }

    $session.executionEvents += $completionEvent

    Save-SessionState -State $state

    Write-Host "[execution-session] session completed: $SessionId"
}

function Get-ExecutionSessions {

    $state = Get-SessionState

    return $state.executionSessions
}

Export-ModuleMember -Function `
    Get-SessionState,
    Save-SessionState,
    Initialize-ExecutionSessions,
    Start-ExecutionSession,
    Add-ExecutionSessionEvent,
    Complete-ExecutionSession,
    Get-ExecutionSessions
