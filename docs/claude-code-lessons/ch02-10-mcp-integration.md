# MCP Integration System: Technical Architecture

## Core Architecture Layers

1. **services/mcp/** — connection lifecycle, config loading, OAuth, transport construction
2. **tools/MCPTool/** — proxy tool wrapper for remote MCP calls
3. **commands/mcp/** — user-facing slash commands
4. **components/mcp/** — React UI panels

## Transport Type System

Eight transport implementations: stdio, sse, http, ws, sse-ide, in-process, sdk. The `InProcessTransport` uses `queueMicrotask` to prevent stack overflow in synchronous request-response cycles.

## Configuration Cascade (7-Level Priority)

1. enterprise (MDM control, exclusive)
2. dynamic (CLI flag)
3. claudeai (remote connector API)
4. project (`.mcp.json` directory-tree walk)
5. local
6. user
7. managed (plugin-provided)

**Enterprise Lock**: `addMcpConfig()` throws immediately when `managed-mcp.json` exists.

## Connection State Machine

Eight-step lifecycle per server including batched connection (3 stdio, 20 remote per batch), transport instantiation with auth, timeout handling, capability negotiation, and live notification subscriptions.

## Tool Proxying & Normalization

Names normalize to `mcp__<server>__<tool_name>`. Descriptions hard-capped at 2048 characters; results >100KB trigger truncation.

## OAuth & Token Management

Full PKCE flow. Slack quirk handling: normalizes non-standard error codes to `invalid_grant`. McpAuthTool pseudo-tool injected when server needs auth.

## Deduplication Strategy

Content-signature matching (not name-based): `stdio:["cmd","arg1"]` or `url:https://vendor.example.com/mcp`.

## Elicitation (User Input Requests)

Form mode (JSON Schema) and URL mode (OAuth step-up). Hooks can satisfy requests programmatically before UI surfaces them.

## Error Handling

- Timeout race with transport closure
- Stderr capture (64MB cap) to log, never to UI
- SSE stream protection: GET requests skip 60s POST timeout
