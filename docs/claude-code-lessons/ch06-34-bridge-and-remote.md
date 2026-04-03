# Claude Code Bridge & Remote Control Architecture

## Bidirectional Transport

**v1**: HybridTransport — WebSocket reads + HTTP POST writes.
**v2**: Asymmetric — SSE inbound, CCRClient outbound. SSE pause doesn't block heartbeats.

## FlushGate Pattern

Prevents history-to-live message interleaving: start() → queuing, end() → flush + return queued, deactivate() → preserve for reconnect, drop() → discard.

## Authentication Layering

OAuth for API calls. Worker JWT (short-lived, session_id + role=worker) for CCR endpoints — OAuth rejected.

## Session ID Compatibility

Dual-prefix: `cse_*` (infrastructure) vs `session_*` (client-facing). `sameSessionId()` ignores prefix.

## Permission Bridge

Remote permission requests synthesized as AssistantMessage. Unknown tools get stub implementations.

## Resilience

Epoch mismatch (409) → old transport closes, poll loop recovers. Sleep detection → immediate reconnect. SSE sequence numbers for gapless reconnection.

## Standalone Bridge

Spawn modes: single-session, worktree (isolated git), same-dir (shared cwd). 24-hour per-session timeout.

## Mirror Mode

Outbound-only bridge: streams to claude.ai without accepting inbound prompts.
