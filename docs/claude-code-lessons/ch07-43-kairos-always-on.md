# KAIROS: Always-On Agent Architecture

## State Pivot

Single boolean `kairosActive` cascades through memory mode, BriefTool, fast-mode, AutoDream, bridge registration.

## Feature Flag Hierarchy

Build-time: positive ternaries for DCE. Sub-features (KAIROS_BRIEF, AGENT_TRIGGERS) ship independently.

## Agent Lifespan: Tick Loop Heartbeat

Model receives periodic `<tengu_tick>` messages. Guided to call `SleepTool` if idle. Model made aware of infrastructure costs.

## Queue Priority

User interruptions: 'now' (immediate), 'next' (wait for current tool), 'later' (end-of-turn). Sleep progress stripped from transcripts.

## Memory Architecture Shift

Standard: single MEMORY.md. Assistant: append-only daily logs. Nightly `/dream` consolidation.

## Dream Consolidation Gates (Cheapest-First)

boolean → time (24h) → filesystem scan throttle (10min) → session count → file-mtime lock.

## Dual-Layer Brief

`isBriefEntitled()` (may use) vs `isBriefEnabled()` (is active). Separation prevents silent opt-ins.

## Scheduling: Dual Durability

`durable: true` (persisted, survives restarts) vs `durable: false` (in-memory, session-only). Jitter: model taught to avoid :00/:30 marks.

## Permanent Tasks

`permanent: true` exempts from age-based expiry. `writeIfMissing()` never overwrites user customizations.

## GrowthBook

Refresh every 5 minutes. Comments note incident response capability.
