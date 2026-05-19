<#
AI-Automation-OS runtime stage: deterministic replay reconstruction.

This stage rebuilds replay state from the latest append-only journal artifact.
It preserves journal replay sequences and emits reconstruction lineage so later
verification can tell restored entries from entries that still need validation.
#>

param(
    [string]$JournalRoot = ".\append-only-execution-journal\execution-log",
    [string]$OutputRoot = ".\deterministic-replay-reconstruction"
)

$ErrorActionPreference = "Stop"

<#
============================================================
   ARTIFACT DISCOVERY
============================================================
#>

function Get-LatestFile {
    param([string]$Root)

    # Replay currently reconstructs from the newest journal only. Historical
    # journals remain available on disk, but this stage does not fold multiple
    # journal files into a single replay timeline yet.
    Get-ChildItem `
        -Path $Root `
        -Filter "*.json" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

<#
============================================================
   REPLAY RECONSTRUCTION
============================================================
#>

function Invoke-ReplayReconstruction {
    param([array]$Journal)

    $reconstruction = @()

    foreach ($entry in $Journal) {

        $replayState = "RESTORED"

        # Recovery checkpoints are intentionally restored as partial state.
        # They are visible to operators but still require validation before
        # being treated as fully reconstructed execution.
        if (
            $entry.CheckpointState -eq
            "RECOVERY_CHECKPOINT"
        ) {
            $replayState = "PARTIAL_RESTORE"
        }

        $verificationState = "VERIFIED"

        # A recovery commit carries useful history, not final confidence.
        # Keeping it in a validation state protects replay consumers from
        # silently accepting recovered work as clean execution.
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

        # RestorationLineage identifies this reconstruction pass. ReplaySequence
        # remains the cross-artifact correlation id from the journal.
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

<#
============================================================
   RUNTIME ENTRYPOINT
============================================================
#>

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
