$script:DistributedStateFile = ".\distributed-runtime-state\distributed-runtime-state.json"

function Get-MemoryState {

    if (-not (Test-Path $script:DistributedStateFile)) {
        throw "Distributed state file missing."
    }

    return Get-Content $script:DistributedStateFile -Raw | ConvertFrom-Json
}

function Save-MemoryState {
    param(
        [Parameter(Mandatory=$true)]
        $State
    )

    $State.lastUpdatedUtc = (Get-Date).ToUniversalTime().ToString("o")

    $State |
        ConvertTo-Json -Depth 100 |
        Set-Content $script:DistributedStateFile
}

function Initialize-RuntimeMemory {

    $state = Get-MemoryState

    if (-not $state.runtimeMemory) {

        $state | Add-Member `
            -MemberType NoteProperty `
            -Name runtimeMemory `
            -Value @()
    }

    Save-MemoryState -State $state

    Write-Host "[runtime-memory] memory initialized"
}

function Add-RuntimeMemoryRecord {
    param(
        [string]$RuntimeId,
        [string]$MemoryType,
        [hashtable]$Payload
    )

    $state = Get-MemoryState

    $memoryRecord = @{
        memoryId = [guid]::NewGuid().ToString()

        runtimeId = $RuntimeId

        memoryType = $MemoryType

        createdUtc = (
            Get-Date
        ).ToUniversalTime().ToString("o")

        payload = $Payload
    }

    $state.runtimeMemory += $memoryRecord

    Save-MemoryState -State $state

    Write-Host "[runtime-memory] memory recorded: $($memoryRecord.memoryId)"
}

function Get-RuntimeMemory {
    param(
        [string]$RuntimeId
    )

    $state = Get-MemoryState

    return $state.runtimeMemory |

        Where-Object {
            $_.runtimeId -eq $RuntimeId
        }
}

function Get-RuntimeMemoryByType {
    param(
        [string]$MemoryType
    )

    $state = Get-MemoryState

    return $state.runtimeMemory |

        Where-Object {
            $_.memoryType -eq $MemoryType
        }
}

Export-ModuleMember -Function `
    Get-MemoryState,
    Save-MemoryState,
    Initialize-RuntimeMemory,
    Add-RuntimeMemoryRecord,
    Get-RuntimeMemory,
    Get-RuntimeMemoryByType
