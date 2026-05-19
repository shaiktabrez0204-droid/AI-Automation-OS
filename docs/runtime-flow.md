# Runtime Flow

The runtime is a chain of artifact transforms. Each stage reads the newest upstream JSON artifact, derives state, and writes a new timestamped JSON file.

## Primary Execution Path

```text
incremental-cognition-propagation
  -> event-driven-cognition-bus
  -> distributed-execution-queue
  -> distributed-worker-runtime
  -> persistent-worker-lifecycle
  -> execution-lifecycle-orchestration
  -> failure-recovery-engine
  -> append-only-execution-journal
  -> deterministic-replay-reconstruction
```

## Stage Responsibilities

| Stage | Runtime script | Output |
|---|---|---|
| Event bus | `runtime/event-driven-cognition-bus.runtime.ps1` | Normalized runtime events. |
| Queue | `runtime/distributed-execution-queue.runtime.ps1` | Pending execution work. |
| Worker execution | `runtime/distributed-worker-runtime.runtime.ps1` | Worker execution results. |
| Worker lifecycle | `runtime/persistent-worker-lifecycle.runtime.ps1` | Durable worker state. |
| Lifecycle orchestration | `runtime/execution-lifecycle-orchestration.runtime.ps1` | Queue transition and retry intent. |
| Recovery | `runtime/failure-recovery-engine.runtime.ps1` | Recovery decisions and redistribution signals. |
| Execution journal | `runtime/append-only-execution-journal.runtime.ps1` | Committed replayable execution records. |
| Replay reconstruction | `runtime/deterministic-replay-reconstruction.runtime.ps1` | Reconstructed replay state. |

## Local Governance Path

```text
dynamic-governance-policy-engine + execution-governed-consensus
  -> runtime-local-governance
  -> runtime-local-event-journaling
```

Local event journaling records event replay posture with the governance constraints active for each runtime.

## Execution Assumptions

- Stages are expected to run in order.
- Input directories must already contain JSON artifacts.
- Output directories are expected to exist.
- The newest JSON file is treated as the current upstream state.
- Generated GUIDs are lineage markers, not content integrity checks.

## Operational Risks

- Independent "latest file" lookup can pair artifacts from different execution passes.
- Re-running a middle stage creates a newer artifact that can redirect downstream processing.
- Worker latency is currently modeled with random values, so degradation decisions are simulation-driven.
- Replay reconstruction reads only the latest journal artifact and does not merge historical journals.

## Recommended Next Hardening

- Introduce an execution-run id shared across all artifacts in a pass.
- Add schema checks for required fields before processing.
- Add preflight checks for missing upstream artifacts and missing output directories.
- Add a non-mutating verification command that reports which artifacts would be consumed by each stage.
