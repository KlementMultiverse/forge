# Coordinator Mode: Technical Architecture & Patterns

## Core Design

The coordinator operates as a **pure dispatcher**, never executing tools directly. Activated via `CLAUDE_CODE_COORDINATOR_MODE=1`, read live (no caching) for mid-session mode flips.

## Tool Restriction

Coordinator has exactly 4 tools: Agent, SendMessage, TaskStop, SyntheticOutput. Workers receive full tool set (Bash, Read, Edit, Glob, Grep, etc.).

## Worker-Coordinator Communication

Workers notify via `<task-notification>` XML envelopes with task-id, status, summary, result, and usage metrics.

## Four-Phase Workflow

1. **Research** (workers, parallel) – investigation with no modifications
2. **Synthesis** (coordinator only) – understanding into specific file paths/line numbers
3. **Implementation** (workers) – targeted changes per spec
4. **Verification** (fresh workers) – independent validation

## Continue vs. Spawn Decision

- High context overlap → continue via SendMessage
- Low overlap or fresh verification → spawn new worker
- Wrong approach → spawn fresh to avoid context pollution

## Context Injection

`getCoordinatorUserContext()` dynamically computes worker tool list, connected MCP servers, and scratchpad directory path.

## Session Resume Consistency

`matchSessionMode()` mutates `process.env.CLAUDE_CODE_COORDINATOR_MODE` directly for immediate propagation.

## Simple Mode Variant

`CLAUDE_CODE_SIMPLE=1` restricts workers to Bash, Read, and Edit only.
