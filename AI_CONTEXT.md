# AI Context

Use this file as the quick operating brief for AI coding agents.

## Project Purpose

AI-Automation-OS is runtime infrastructure for replayable execution, distributed orchestration, repository cognition, and persistent engineering memory.

## Current Shape

- Active runtime code lives primarily in `runtime/`.
- Runtime systems usually read the newest upstream JSON artifact and write a new timestamped artifact.
- Replay is implemented through `runtime/deterministic-replay-reconstruction.runtime.ps1` and artifacts under `deterministic-replay-reconstruction/`.
- Journaling is implemented through `runtime/append-only-execution-journal.runtime.ps1`, `runtime/runtime-local-event-journaling.runtime.ps1`, and their artifact folders.
- There are no root `replay/` or `journal/` directories at this time.

## Constraints

- Preserve architecture and flow unless a change is explicitly required.
- Do not rewrite working runtime stages into a framework.
- Do not mutate historical JSON artifacts unless the task specifically asks for cleanup.
- Comments should explain why, sequencing, risk, or architecture. Avoid syntax narration.
- Generated GUID fields are lineage markers unless code proves they are content hashes.

## High-Risk Areas

- Independent latest-file selection can mix artifacts from different runs.
- Replay reconstruction reads only one latest journal.
- Worker degradation is currently based on simulated latency.
- Empty placeholder runtime files exist and should not be assumed complete.

## Good Next Steps

- Add explicit run ids across pipeline artifacts.
- Add preflight validation for missing inputs and malformed JSON.
- Document subsystem ownership before reorganizing folders.
- Keep cleanup passes incremental and focused.
