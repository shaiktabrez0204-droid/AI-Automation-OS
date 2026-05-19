param(
    [string]$LifecycleRoot = ".\execution-lifecycle-orchestration\execution-transitions",
    [string]$WorkerRoot = ".\persistent-worker-lifecycle\worker-state",
    [string]$OutputRoot = ".\failure-recovery-engine"
)

$ErrorActionPreference = "Stop"

function Get-LatestFile {
    param([string]$Root)

    Get-ChildItem `
        -Path $Root `
        -Filter "*.json" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

function Invoke-FailureRecovery {
    param(
        [array]$Lifecycle,
        [array]$Workers
    )

    $recovery = @()

    foreach ($execution in $Lifecycle) {

        $worker = $Workers |
        Where-Object {
            $_.WorkerId -eq $execution.WorkerId
        } |
        Select-Object -First 1

        $recoveryAction = "NONE"

        if (
            $execution.RecoveryState -eq
            "RETRY_PENDING"
        ) {
            $recoveryAction = "REQUEUE_TASK"
        }

        $redistributionState = "UNCHANGED"

        if (
            $worker.WorkerState -eq
            "DEGRADED"
        ) {
            $redistributionState =
            "REDISTRIBUTE_EXECUTION"
        }

        $retryCount = 0

        if (
            $recoveryAction -eq
            "REQUEUE_TASK"
        ) {
            $retryCount = 1
        }

        $recovery += [PSCustomObject]@{
            QueueId = $execution.QueueId
            Runtime = $execution.Runtime
            WorkerId = $execution.WorkerId
            RecoveryAction = $recoveryAction
            RedistributionState = $redistributionState
            RetryCount = $retryCount
            RecoveryTimestamp = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $recovery
}

Write-Host ""
Write-Host "======================================="
Write-Host "FAILURE RECOVERY ENGINE"
Write-Host "======================================="
Write-Host ""

$lifecycleFile = Get-LatestFile `
    -Root $LifecycleRoot

$workerFile = Get-LatestFile `
    -Root $WorkerRoot

$lifecycle = Get-Content `
    $lifecycleFile.FullName `
    -Raw |
ConvertFrom-Json

$workers = Get-Content `
    $workerFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[lifecycle-records] $($lifecycle.Count)"
Write-Host "[worker-records] $($workers.Count)"

$recovery =
Invoke-FailureRecovery `
    -Lifecycle $lifecycle `
    -Workers $workers

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "execution-recovery\failure-recovery-$timestamp.json"

$recovery |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[failure-recovery-written] $outputFile"
Write-Host ""
