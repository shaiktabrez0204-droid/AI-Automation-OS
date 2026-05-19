# Journal System

The journal system records runtime execution history in append-only artifacts. It has two related surfaces:

- Runtime-local event journaling.
- Append-only execution journaling.

## Runtime-Local Event Journaling

Script:

```text
runtime/runtime-local-event-journaling.runtime.ps1
```

Inputs:

- `event-driven-cognition-bus/event-streams/*.json`
- `runtime-local-governance/local-policy-state/*.json`

Output:

```text
runtime-local-event-journaling/event-journals/runtime-event-journal-*.json
```

Purpose:

Local event journals attach governance posture to event records. This captures whether a runtime was active, restricted, or locked when its events were journaled.

## Append-Only Execution Journal

Script:

```text
runtime/append-only-execution-journal.runtime.ps1
```

Inputs:

- `failure-recovery-engine/execution-recovery/*.json`
- `execution-lifecycle-orchestration/execution-transitions/*.json`

Output:

```text
append-only-execution-journal/execution-log/append-only-journal-*.json
```

Purpose:

The append-only journal commits lifecycle and recovery state into replayable execution records. Prior journals are left intact so recovery decisions can be audited later.

## Important Fields

| Field | Meaning |
|---|---|
| `QueueId` | Correlates queue, worker, lifecycle, recovery, journal, and replay records. |
| `JournalState` | Distinguishes clean commits from recovery commits. |
| `CheckpointState` | Distinguishes ordinary checkpoints from recovery checkpoints. |
| `ReplaySequence` | Correlation id emitted by the journal and preserved by replay. |
| `RecoveryAction` | Recovery decision that influenced the journal entry. |

## Constraints

- Journals are append-only by convention. Do not edit historical journal artifacts during normal operation.
- `ReplaySequence` is generated as a GUID. It is not a deterministic content hash.
- The current journal script reads the newest recovery and lifecycle artifacts independently.

## Extension Points

- Add content hashes alongside generated lineage ids.
- Add run ids to guarantee recovery and lifecycle artifacts came from the same pass.
- Add journal schema validation before replay consumes a file.
- Add summary reports for recovery-heavy journals.
