# Replay System

The replay system reconstructs execution state from the latest append-only journal artifact.

Script:

```text
runtime/deterministic-replay-reconstruction.runtime.ps1
```

Input:

```text
append-only-execution-journal/execution-log/append-only-journal-*.json
```

Output:

```text
deterministic-replay-reconstruction/reconstructed-state/deterministic-replay-*.json
```

## Replay Flow

1. Select the newest journal artifact.
2. Read committed execution records.
3. Classify each entry as restored or partially restored.
4. Classify verification state.
5. Preserve `ReplaySequence` from the journal.
6. Emit a reconstruction artifact with new restoration lineage.

## State Mapping

| Journal input | Replay output |
|---|---|
| `CheckpointState = CHECKPOINTED` | `ReplayState = RESTORED` |
| `CheckpointState = RECOVERY_CHECKPOINT` | `ReplayState = PARTIAL_RESTORE` |
| `JournalState = COMMITTED` | `VerificationState = VERIFIED` |
| `JournalState = RECOVERY_COMMITTED` | `VerificationState = REQUIRES_VALIDATION` |

## Determinism Boundary

Replay is deterministic in its classification rules and in preserving the journal's `ReplaySequence`. It is not fully deterministic in generated lineage fields because `RestorationLineage` is a new GUID for each reconstruction run.

## Risks

- Only the latest journal is replayed.
- Historical journals are not merged into a timeline.
- Recovery commits are reconstructed but intentionally require validation.
- Missing or malformed journal fields are not validated before reconstruction.

## Extension Points

- Add multi-journal replay by chronological artifact order.
- Add validation that rejects records missing `QueueId`, `JournalState`, `CheckpointState`, or `ReplaySequence`.
- Add a replay report that separates verified restores from partial restores.
- Add content-addressed lineage if replay output needs stable identity across repeated runs.
