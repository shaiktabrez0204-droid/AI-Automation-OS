# System Overview

AI-Automation-OS is an infrastructure repository built around replayable execution and persistent engineering cognition.

## Mental Model

Think of the system as a set of runtime stages connected by timestamped JSON artifacts. Each stage creates a new view of runtime state while leaving prior artifacts available for audit and replay.

## Main Execution Spine

```text
Propagation -> Events -> Queue -> Workers -> Lifecycle -> Recovery -> Journal -> Replay
```

## Important Runtime Scripts

| Script | Role |
|---|---|
| `runtime/event-driven-cognition-bus.runtime.ps1` | Converts propagation deltas to normalized events. |
| `runtime/distributed-execution-queue.runtime.ps1` | Converts events to queue entries. |
| `runtime/distributed-worker-runtime.runtime.ps1` | Produces worker execution results. |
| `runtime/persistent-worker-lifecycle.runtime.ps1` | Projects durable worker state. |
| `runtime/execution-lifecycle-orchestration.runtime.ps1` | Marks lifecycle transitions and retry intent. |
| `runtime/failure-recovery-engine.runtime.ps1` | Produces recovery actions. |
| `runtime/append-only-execution-journal.runtime.ps1` | Commits replayable execution records. |
| `runtime/deterministic-replay-reconstruction.runtime.ps1` | Reconstructs replay state from the journal. |

## Operating Identity

This repository should remain infrastructure-oriented. Prefer clear state transitions, explicit artifacts, and documented operational constraints over generalized abstractions.

## Navigation

- Start with `README.md`.
- Read `docs/architecture.md` for system boundaries.
- Read `docs/runtime-flow.md` for execution sequencing.
- Read `docs/journal-system.md` and `docs/replay-system.md` before changing recovery, replay, or journaling behavior.
