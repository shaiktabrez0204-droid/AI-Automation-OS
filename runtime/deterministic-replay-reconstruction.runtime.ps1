param(
    [string]$JournalRoot = ".\append-only-execution-journal\execution-log",
    [string]$OutputRoot = ".\deterministic-replay-reconstruction"
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

function Invoke-ReplayReconstruction {
    param([array]$Journal)

    $reconstruction = @()

    foreach ($entry in $Journal) {

        $replayState = "RESTORED"

        if (
            $entry.CheckpointState -eq
            "RECOVERY_CHECKPOINT"
        ) {
            $replayState = "PARTIAL_RESTORE"
        }

        $verificationState = "VERIFIED"

        if (
            $entry.JournalState -eq
            "RECOVERY_COMMITTED"
        ) {
            $verificationState =
            "REQUIRES_VALIDATION"
        }

        $restorationLineage = (
            [System.Guid]::NewGuid().Guid
        )

        $reconstruction += [PSCustomObject]@{
            QueueId = $entry.QueueId
            Runtime = $entry.Runtime
            WorkerId = $entry.WorkerId
            ReplayState = $replayState
            VerificationState = $verificationState
            RestorationLineage = $restorationLineage
            ReplaySequence = $entry.ReplaySequence
            ReconstructionTimestamp = (
                Get-Date
            ).ToUniversalTime()
        }
    }

    return $reconstruction
}

Write-Host ""
Write-Host "======================================="
Write-Host "DETERMINISTIC REPLAY RECONSTRUCTION"
Write-Host "======================================="
Write-Host ""

$journalFile = Get-LatestFile `
    -Root $JournalRoot

$journal = Get-Content `
    $journalFile.FullName `
    -Raw |
ConvertFrom-Json

Write-Host "[journal-records] $($journal.Count)"

$reconstruction =
Invoke-ReplayReconstruction `
    -Journal $journal

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$outputFile = Join-Path `
    $OutputRoot `
    "reconstructed-state\deterministic-replay-$timestamp.json"

$reconstruction |
ConvertTo-Json -Depth 15 |
Set-Content $outputFile

Write-Host ""
Write-Host "[deterministic-replay-written] $outputFile"
Write-Host ""
