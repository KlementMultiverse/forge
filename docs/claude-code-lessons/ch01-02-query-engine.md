# Claude Code Query Engine & LLM API Architecture

## Core Design Pattern: Async Generators Throughout

The framework uses `async function*` at every layer—`submitMessage`, `query`, `queryLoop`, `queryModel`, `withRetry`, `handleStopHooks`—enabling composable streaming with natural backpressure handling via `yield*`.

## Single-Responsibility Loop Architecture

A `while(true)` loop in `queryLoop()` carries a typed `State` object between iterations rather than loose variables. Each continuation is tagged with an explicit `transition.reason`:

- `max_output_tokens_escalate` / `max_output_tokens_recovery`
- `reactive_compact_retry` / `collapse_drain_retry`
- `stop_hook_blocking`
- `token_budget_continuation`
- Normal tool-use follow-up (unnamed)

This makes state transitions auditable and testable without inspecting message content.

## Transcript-First Reliability Pattern

"The user message is written to disk before the API is called" ensures sessions remain resumable even after process termination mid-flight. This decouples persistence from success.

## Structured Retry Intelligence

Rather than naive exponential backoff, `withRetry()` implements conditional logic:

- **529 errors**: Foreground queries retry; background queries (summaries, classifiers) bail immediately to avoid cascade amplification
- **Opus fallback**: Trigger after 3 consecutive 529s on non-custom models
- **OAuth 401**: Force token refresh before retry
- **Context overflow 400**: Parse token counts from error message to compute `maxTokensOverride`
- **Socket stale**: Call `disableKeepAlive()` on ECONNRESET/EPIPE

## Context Reduction Pipeline

Five strategies run in order before each API call:

1. Tool result budgeting (byte caps, external storage refs)
2. snipCompact (remove provably-unneeded mid-history)
3. Microcompact (merge tool-result/user pairs)
4. contextCollapse (read-time projection over full history)
5. autoCompact (full summarization on limit approach)

Only the first unmet strategy fires, preventing redundant compaction.

## Token Budget Auto-Continue

Post-turn check: if under 90% budget consumption AND not diminishing (3+ continuations with <500 token deltas), inject a nudge and loop. Stops when budget exhausted OR two consecutive low-delta turns suggest spinning.

## Stop Hooks Lifecycle

Three ordered categories post-turn:
- User-configured hooks (can block)
- TaskCompleted hooks (teammate mode)
- TeammateIdle hooks (teammate mode)
- Fire-and-forget background tasks (memory extraction, prompt suggestions, auto-dream) skipped in bare mode

Critically: hooks are skipped on API errors to prevent death spirals.

## Streaming Tool Execution

When enabled, a `StreamingToolExecutor` starts tool execution mid-stream, parallelizing with model generation. Partially-received messages are "tombstoned" (yielded as `{ type: 'tombstone' }`) on fallback to prevent immutability API errors on retry.

## Feature-Gated Dead Code Elimination

`feature('HISTORY_SNIP')`, `feature('TOKEN_BUDGET')` etc. evaluated at Bun bundle time, preventing unreachable code and string leakage in external builds.
