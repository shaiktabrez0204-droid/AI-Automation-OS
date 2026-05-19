$script:DistributedStateFile = ".\distributed-runtime-state\distributed-runtime-state.json"

function Get-MessagingState {

    if (-not (Test-Path $script:DistributedStateFile)) {
        throw "Distributed state file missing."
    }

    return Get-Content $script:DistributedStateFile -Raw | ConvertFrom-Json
}

function Save-MessagingState {
    param(
        [Parameter(Mandatory=$true)]
        $State
    )

    $State.lastUpdatedUtc = (Get-Date).ToUniversalTime().ToString("o")

    $State |
        ConvertTo-Json -Depth 100 |
        Set-Content $script:DistributedStateFile
}

function Initialize-RuntimeMessaging {

    $state = Get-MessagingState

    if (-not $state.runtimeMessages) {

        $state | Add-Member `
            -MemberType NoteProperty `
            -Name runtimeMessages `
            -Value @()
    }

    Save-MessagingState -State $state

    Write-Host "[runtime-messaging] messaging initialized"
}

function Send-RuntimeMessage {
    param(
        [string]$SourceRuntime,
        [string]$TargetRuntime,
        [string]$MessageType,
        [hashtable]$Payload
    )

    $state = Get-MessagingState

    $message = @{
        messageId = [guid]::NewGuid().ToString()

        sourceRuntime = $SourceRuntime
        targetRuntime = $TargetRuntime

        messageType = $MessageType

        deliveryState = "pending"

        createdUtc = (
            Get-Date
        ).ToUniversalTime().ToString("o")

        payload = $Payload
    }

    $state.runtimeMessages += $message

    Save-MessagingState -State $state

    Write-Host "[runtime-messaging] message sent: $($message.messageId)"
}

function Receive-RuntimeMessages {
    param(
        [string]$RuntimeId
    )

    $state = Get-MessagingState

    $messages = $state.runtimeMessages |

        Where-Object {
            $_.targetRuntime -eq $RuntimeId
        } |

        Where-Object {
            $_.deliveryState -eq "pending"
        }

    foreach ($message in $messages) {

        $message.deliveryState = "delivered"

        Write-Host (
            "[runtime-messaging] delivered: " +
            $message.messageId
        )
    }

    Save-MessagingState -State $state

    return $messages
}

function Get-RuntimeMessages {

    $state = Get-MessagingState

    return $state.runtimeMessages
}

Export-ModuleMember -Function `
    Get-MessagingState,
    Save-MessagingState,
    Initialize-RuntimeMessaging,
    Send-RuntimeMessage,
    Receive-RuntimeMessages,
    Get-RuntimeMessages
