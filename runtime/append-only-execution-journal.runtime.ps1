param(
    [string]$RecoveryRoot = ".\failure-recovery-engine\execution-recovery",
    [string]$LifecycleRoot = ".\execution-lifecycle-orchestration\execution-transitions",
    [string]$OutputRoot = ".\append-only-execution-journal"
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

function Build-ExecutionJournal {
    param(
        [array]$Recovery,
        [array]$Lifecycle
    )

    $journal = @()

    foreach ($execution in $Lifecycle) {

        $recoveryRecord = $Recovery |
        Where-Object {
            $_.QueueId -eq $execution.QueueId
        } |
        Select-Object -First 1

        $journalState = "COMMITTED"

        if (
            $recoveryRecord.RecoveryAction -eq
            "REQUEUE_TASK"
        ) {
            $journalState = "RECOVERY_COMMITTED"
        }

        $checkpointState = "CHECKPOINTED"

        if (
            $execution.RecoveryState -eq
            "RETRY_PENDING"
        ) {
            $checkpointState =
            "RECOVERY_CHECKPOINT"
        }

        $replaySequence = (
            [System.Guid]::NewGuid().Guid
        )

        $journal += [PSCustomObject]@{
            QueueId = $execution.QueueId
            Runtime = $execution.Runtime
            WorkerId = $execution.WorkerId
            JournalState = $journalState
            CheckpointState = $checkpointState
            ReplaySequence = $replaySequence
            RecoveryAction = $recoveryRecord.RecoveryAction
            JournalTimestamp = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $journal
}

Write-Host ""
Write-Host "======================================="
Write-Host "APPEND-ONLY EXECUTION JOURNAL"
Write-Host "======================================="
Write-Host ""

$recoveryFile = Get-LatestFile `
    -Root $RecoveryRoot

$lifecycleFile = Get-LatestFile `
    -Root $LifecycleRoot

$recovery = Get-Content `
    $recoveryFile.FullName `
    -Raw |
ConvertFrom-Json

$lifecycle = Get-Content `
    $lifecycleFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[recovery-records] $($recovery.Count)"
Write-Host "[lifecycle-records] $($lifecycle.Count)"

$journal =
Build-ExecutionJournal `
    -Recovery $recovery `
    -Lifecycle $lifecycle

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "execution-log\append-only-journal-$timestamp.json"

$journal |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[append-only-journal-written] $outputFile"
Write-Host ""
