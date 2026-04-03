# Claude Code Error Handling Architecture

## Typed Error Classification

Dedicated error classes (`ShellError`, `ConfigParseError`, `AbortError`) enable `instanceof` checks that survive minification.

## Four Layers

1. Typed Error Classes
2. API Retry Engine (exponential backoff, auth refresh, context overflow auto-adjust)
3. Terminal Overlay (inline source display)
4. Conversation Recovery (mid-turn session restoration)

## Retry Strategy

Exponential backoff: 500ms x 2^attempt, capped 32s, jitter +/-25%. 529 overload: background queries bail immediately. Context overflow: auto-reduces maxTokens (3k floor). Tool errors truncated to 10k chars (5k head + 5k tail).

## Telemetry Safety

`TelemetrySafeError_I_VERIFIED_THIS_IS_NOT_CODE_OR_FILEPATHS` — verbose naming as code-review forcing function.

## Conversation Recovery

Four-stage deserialization: legacy migration, permission cleanup, invalid message filtering, interrupt detection. Interrupted turns get synthetic "Continue from where you left off."

## Error Logging

Sink pattern decouples interface from implementation. Buffered JSONL writes (1s/50 entries). Gated to internal employees only.
