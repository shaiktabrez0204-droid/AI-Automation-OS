# Architecture

AI-Automation-OS is organized around inspectable runtime infrastructure. The main pattern is a sequence of PowerShell stages that read JSON artifacts, derive a new state projection, and write a new timestamped artifact.

## Architectural Intent

The repository favors operational visibility over hidden orchestration. Runtime state is left on disk so humans and AI agents can inspect the system after each pass, understand why recovery happened, and replay execution without depending on an opaque service process.

## Core Layers

| Layer | Primary locations | Responsibility |
|---|---|---|
| Runtime code | `runtime/` | Entry scripts and modules for orchestration, cognition, recovery, journaling, and replay. |
| Runtime artifacts | `event-driven-cognition-bus/`, `distributed-execution-queue/`, `failure-recovery-engine/`, others | Timestamped JSON outputs from runtime stages. |
| Execution history | `append-only-execution-journal/`, `runtime-local-event-journaling/`, `executions/` | Journaled execution and replay checkpoints. |
| Replay state | `deterministic-replay-reconstruction/` | Reconstructed state derived from journal artifacts. |
| Engineering memory | `memory/`, `architecture/`, `context/` | Persistent operating context and architecture records. |
| Repository cognition | `repository-cognition/`, `semantic-cognition/`, `infrastructure/` | Repository topology, semantic indexing, and capability inference. |

## Runtime Shape

Most runtime files follow the same structure:

1. Accept input and output roots as parameters.
2. Select the newest upstream JSON artifact.
3. Convert it from JSON.
4. Project a new operational state.
5. Write a timestamped JSON artifact.

This shape is intentionally simple. It allows stages to be run directly from a terminal and keeps intermediate state visible.

## State Ownership

Each subsystem owns its output folder. Downstream stages should consume those artifacts rather than mutate them.

Examples:

- `distributed-execution-queue/` owns pending execution queue artifacts.
- `persistent-worker-lifecycle/` owns durable worker state artifacts.
- `failure-recovery-engine/` owns recovery decisions.
- `append-only-execution-journal/` owns committed replayable execution records.
- `deterministic-replay-reconstruction/` owns reconstructed replay state.

## Architectural Constraints

- Do not replace artifact-based stages with a central framework without a specific operational reason.
- Do not fold generated history into source-controlled runtime code.
- Keep recovery, journaling, and replay decisions explicit. Hidden side effects make the system harder to audit.
- Shared helpers may become useful later, but introducing them now would change the current independent-stage operating model.

## Extension Points

- Add explicit artifact ids to stage parameters when strict causality matters.
- Add schema validation before journal and replay stages.
- Replace simulated worker latency with measured runtime telemetry.
- Introduce a runner that passes a single execution context through each stage while preserving the current stage boundaries.
