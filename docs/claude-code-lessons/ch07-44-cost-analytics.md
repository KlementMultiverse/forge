# Claude Code: Cost Analytics & Observability

## Dual Pipeline Design

Internal 1P (OpenTelemetry proto) and Datadog HTTP-intake in parallel.

## Cost Tracking

Single entry `addToTotalSessionCost()` fans to: in-memory accumulators, OTel counters, analytics log. Microdollar storage prevents floating-point errors.

## Analytics Sink & Queue

Zero dependencies. Events queue until sink attached. Drain via `queueMicrotask`.

## Datadog Controls

Allowlist-based dispatch (~40 events). Cardinality reduction: model names → canonical, user IDs → 30 buckets, MCP tools → "mcp". Batching: 15s flush or 100 entries.

## PII Segregation

Compile-time `never` type forces explicit casts. `_PROTO_` prefix keys for privileged BigQuery only.

## 1P Resilience

Disk-backed retry: JSONL files for failed events. Quadratic backoff (base x attempts^2, 30s cap, 8 max). Isolated LoggerProvider.

## Customer Telemetry

Opt-in via env vars. Session ID included by default. Version excluded by default. BigQuery metrics every 5 minutes regardless.

## Auth-Aware Dispatch

Events never dropped solely because auth unavailable — degrade to unauthenticated delivery.
