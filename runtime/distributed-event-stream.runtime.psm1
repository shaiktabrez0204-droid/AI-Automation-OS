$script:EventStreamPath = ".\distributed-runtime-state\event-streams"

function Publish-DistributedEvent {
    param(
        [string]$EventType,
        [string]$SourceRuntime,
        [hashtable]$Payload
    )

    if (-not (Test-Path $script:EventStreamPath)) {

        New-Item `
            -ItemType Directory `
            -Path $script:EventStreamPath `
            -Force | Out-Null
    }

    $event = @{
        eventId = [guid]::NewGuid().ToString()
        eventType = $EventType
        sourceRuntime = $SourceRuntime
        timestampUtc = (Get-Date).ToUniversalTime().ToString("o")
        payload = $Payload
    }

    $fileName = "{0}.json" -f $event.eventId

    $event |
        ConvertTo-Json -Depth 100 |
        Set-Content (
            Join-Path `
                $script:EventStreamPath `
                $fileName
        )

    Write-Host "[distributed-event-stream] published: $($event.eventId)"
}

function Get-DistributedEvents {

    if (-not (Test-Path $script:EventStreamPath)) {
        return @()
    }

    return Get-ChildItem `
        $script:EventStreamPath `
        -Filter "*.json" |

        ForEach-Object {

            Get-Content $_.FullName -Raw |
            ConvertFrom-Json
        }
}

function Get-DistributedEventsByType {
    param(
        [string]$EventType
    )

    return Get-DistributedEvents |
        Where-Object {
            $_.eventType -eq $EventType
        }
}

Export-ModuleMember -Function `
    Publish-DistributedEvent,
    Get-DistributedEvents,
    Get-DistributedEventsByType
