# Claude Code Analytics Architecture

## Dependency Inversion: Pre-Sink Queue

`logEvent` has zero dependencies. Events queue until `attachAnalyticsSink` initializes. Drained via `queueMicrotask`.

## Three-Layer Event Routing

1. Sampling gate (GrowthBook rates)
2. Sink kill-switch (per-backend)
3. PII stripping (`_PROTO_` prefixed fields → privileged first-party only)

## PII via Type System

`AnalyticsMetadata_I_VERIFIED_THIS_IS_NOT_CODE_OR_FILEPATHS = never` — forces explicit `as` casts as code-review checkpoints.

## Cardinality Reduction

Model names canonicalized. User IDs hashed to 1 of 30 buckets. Version strings strip dev timestamps. MCP tool names → generic "mcp".

## Metadata Enrichment

Every event: EnvContext (memoized), ProcessMetrics (CPU/memory deltas), Agent attribution (AsyncLocalStorage then env vars).

## Datadog Transport

Batches up to 100 events or 15-second flush. `.unref()` timer. Graceful shutdown ensures final batch.

## Fail-Open Resilience

Missing configs → enabled. GrowthBook outage → sinks stay active. Kill-switch missing → enabled.

## Sampling & Reconstruction

Sampled events include `sample_rate` for inverse-probability weighting.
