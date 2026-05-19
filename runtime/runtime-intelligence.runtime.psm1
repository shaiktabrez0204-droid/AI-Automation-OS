$script:DistributedStateFile = ".\distributed-runtime-state\distributed-runtime-state.json"

function Get-IntelligenceState {

    if (-not (Test-Path $script:DistributedStateFile)) {
        throw "Distributed state file missing."
    }

    return Get-Content $script:DistributedStateFile -Raw | ConvertFrom-Json
}

function Save-IntelligenceState {
    param(
        [Parameter(Mandatory=$true)]
        $State
    )

    $State.lastUpdatedUtc = (Get-Date).ToUniversalTime().ToString("o")

    $State |
        ConvertTo-Json -Depth 100 |
        Set-Content $script:DistributedStateFile
}

function Initialize-RuntimeIntelligence {

    $state = Get-IntelligenceState

    if (-not $state.runtimeIntelligence) {

        $state | Add-Member `
            -MemberType NoteProperty `
            -Name runtimeIntelligence `
            -Value @()
    }

    Save-IntelligenceState -State $state

    Write-Host "[runtime-intelligence] intelligence initialized"
}

function Invoke-RuntimePerformanceAnalysis {

    $state = Get-IntelligenceState

    $executionMemories = $state.runtimeMemory |

        Where-Object {
            $_.memoryType -eq "execution-pattern"
        }

    $groupedRuntimes = $executionMemories |

        Group-Object runtimeId

    $state.runtimeIntelligence = @()

    foreach ($runtimeGroup in $groupedRuntimes) {

        $runtimeId = $runtimeGroup.Name

        $records = $runtimeGroup.Group

        $averageExecutionDuration = (
            $records |
            Measure-Object `
                -Property {
                    $_.payload.executionDurationSeconds
                } `
                -Average
        ).Average

        $intelligenceRecord = @{
            runtimeId = $runtimeId

            executionCount = $records.Count

            averageExecutionDurationSeconds = [math]::Round(
                $averageExecutionDuration,
                2
            )

            performanceScore = [math]::Round(
                (100 / ($averageExecutionDuration + 1)),
                2
            )

            analyzedUtc = (
                Get-Date
            ).ToUniversalTime().ToString("o")
        }

        $state.runtimeIntelligence += $intelligenceRecord
    }

    Save-IntelligenceState -State $state

    Write-Host "[runtime-intelligence] performance analysis completed"
}

function Get-RuntimeIntelligence {

    $state = Get-IntelligenceState

    return $state.runtimeIntelligence
}

Export-ModuleMember -Function `
    Get-IntelligenceState,
    Save-IntelligenceState,
    Initialize-RuntimeIntelligence,
    Invoke-RuntimePerformanceAnalysis,
    Get-RuntimeIntelligence
