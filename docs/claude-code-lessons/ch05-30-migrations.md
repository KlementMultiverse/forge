# Migration System Architecture

## Core Design

Idempotent, one-shot functions that detect their own completion state. Runs synchronously during startup. Single version number (`CURRENT_MIGRATION_VERSION = 11`) short-circuits when all applied.

## Two Idempotency Patterns

**Pattern A: Completion Flags** — Boolean/timestamp in GlobalConfig.
**Pattern B: Self-Idempotent Data Checks** — Current value indicates completion.

## Critical Constraint: Settings Layer Discipline

Only reads/writes `userSettings`, never merged settings. Prevents scope-collapse bugs where project-level configs get accidentally globalized.

## Five Migration Categories

1. Settings promotions
2. Model alias upgrades
3. Config key renames
4. One-shot resets
5. Async file migrations

## Safeguards

- All migrations wrap in try/catch; failures never break startup
- Analytics instrumentation tracks data shape disappearance
- Version bump required for new migrations
