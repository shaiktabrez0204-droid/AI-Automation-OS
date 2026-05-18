# Context Loading Workflow

## Purpose

This workflow defines how AI-Automation-OS should load operational context for different execution scenarios.

The objective is to:
- reduce context noise
- improve retrieval precision
- optimize AI reasoning quality
- preserve execution continuity

---

# Core Principle

Do NOT load the entire repository into AI context.

Load only:
- relevant operational memory
- relevant workflows
- relevant project state
- relevant architectural context

High-signal context produces significantly better execution quality.

---

# Context Loading Strategy

## Architecture Tasks

Load:
- README.md
- docs/system-architecture.md
- memory/architecture/
- core/operating-principles.md

Use For:
- system design
- architecture planning
- infrastructure decisions
- scaling discussions

---

## Workflow Tasks

Load:
- workflows/
- memory/workflows/
- current-context.md

Use For:
- workflow creation
- execution systems
- automation planning
- process optimization

---

## Project Tasks

Load:
- memory/projects/
- relevant project files
- current-context.md
- session-context.md

Use For:
- project implementation
- execution continuity
- feature development
- operational restoration

---

## Agent Tasks

Load:
- memory/agents/
- memory/architecture/
- workflows/
- operating-principles.md

Use For:
- autonomous systems
- orchestration logic
- agent workflows
- execution coordination

---

## Debugging Tasks

Load:
- operational logs
- relevant workflows
- current session context
- relevant project memory

Use For:
- troubleshooting
- issue investigation
- execution failure analysis

---

# Context Loading Philosophy

More context does NOT guarantee better intelligence.

AI execution quality depends on:
- relevance
- structure
- signal quality
- operational clarity

The objective is:
maximum relevant signal with minimum unnecessary noise.

---

# Foundational Insight

Retrieval quality is one of the highest-leverage multipliers in AI-native systems.

Well-structured context loading behaves like:
- reasoning amplification
- execution optimization
- operational intelligence infrastructure
