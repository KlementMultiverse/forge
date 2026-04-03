# Claude Code Architecture: Technical Deep Dive

## Core Architectural Patterns

**Async Generator Threading**: The entire data pipeline uses async generators rather than callbacks or event buses. `query()` yields `StreamEvent`s, which flow to `QueryEngine.submitMessage()` yielding `SDKMessage`s, consumed by the REPL. This enables true streaming without architectural complexity.

**Two-Layer State Model**:
- `bootstrap/state.ts`: Plain JS module singleton for process-lifetime constants (sessionId, cwd, totalCostUSD, model). Accessible by non-React code.
- `AppStateStore.ts`: React context holding `DeepImmutable<AppState>` for UI rendering. Prevents accidental mutations.

**Dead Code Elimination**: Uses Bun's bundle-time `feature('FLAG_NAME')` to completely remove disabled branches. The tool registry becomes deterministic per build—critical for Anthropic's prompt cache keying.

## QueryEngine Design

The `QueryEngine` class owns conversation lifecycle with one instance per session:

```typescript
class QueryEngine {
  private config: QueryEngineConfig
  private mutableMessages: Message[]
  private abortController: AbortController
  private permissionDenials: SDKPermissionDenial[]
  private totalUsage: NonNullableUsage
}
```

**Turn Lifecycle**: Each `submitMessage()` call:
1. Processes slash commands
2. Persists user message to disk (before API call for crash resilience)
3. Assembles system prompt from multiple parts
4. Loads skills/plugins
5. Enters query loop with streaming API calls
6. Executes tools in parallel
7. Checks token budget and compacts if needed

**Critical Design**: "The transcript is written before the API call, not after" to ensure resumability if the process dies mid-request.

## Tool System Architecture

**Flat Registry Pattern**: `getAllBaseTools()` returns authoritative tool list. MCP tools are dynamically added via `getMcpToolsCommandsAndResources()` at startup, not included in the base registry.

**Tool Interface**:
```
name, description, inputSchema (Zod validation)
isEnabled() → bool
call(input, context) → AsyncGenerator
renderToolResult() → React component
```

**ToolUseContext Bundle**: Passes everything tools need without coupling to global state.

## Permission Architecture

Single choke point: `canUseTool()` called before every tool execution. Three permission modes:
- `default`: Ask user for unlisted tools
- `auto`: Automatically allow safe tools
- `bypass`: Allow all tools

## Boot Sequence Optimization

**Parallel from Import Time**:
- `startMdmRawRead()` (MDM policy subprocesses)
- `startKeychainPrefetch()` (macOS keychain reads)
- Both complete before ~135ms module evaluation finishes

**Network Warm-up**: `preconnectAnthropicApi()` establishes TCP connection before user types.

## Session Management

Sessions stored as JSONL transcript files: `~/.claude/projects/<cwd-hash>/<session-id>.jsonl`

**Write Queue Pattern**: Transcript writes use lazy 100ms drain timer for performance. User message writes are awaited; assistant message writes are fire-and-forget.

## Context Compaction

Triggers at ~80% context window fill. `buildPostCompactMessages()` sends conversation to Claude for summarization. Supports feature-gated `snipCompact` alternative using compact boundaries.

## Hook Security Model

Hooks configuration snapshotted once at startup via `captureHooksConfigSnapshot()`—must run after `setCwd()` but before any query. Prevents malicious projects from injecting hook commands mid-session.
