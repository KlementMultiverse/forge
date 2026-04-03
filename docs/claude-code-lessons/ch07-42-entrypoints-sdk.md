# Claude Code Entrypoints & Agent SDK

## Layered Entrypoint System

`cli.tsx` as pure dispatcher before loading full module graph. Build-time feature gates strip code from binaries (not just branched over).

## Initialization Pipeline

Sequential: config validation → env vars → TLS → shutdown handlers → analytics → OAuth cache → IDE detection → enterprise policy → TCP preconnection (~150ms parallel).

Telemetry splits: consent-independent setup, then consent-gated exporters.

## Agent SDK: Stub-and-Inject

All function bodies throw 'not implemented' — actual implementations injected at runtime by transport layer. JSON over stdio for external SDK implementations.

## Control Protocol

26 named hook events for observation. Key control requests: initialize, can_use_tool, interrupt, set_model, mcp_status.

## MCP Server Symmetry

Claude Code can both provide and consume MCP servers. `--mcp` mode: thinking disabled, only review command exposed.

## Process Isolation

Centralized sandbox config: network (domains, sockets), filesystem (write/read allow/deny), failure modes.

## Remote Control Patterns

**Daemon mode**: WebSocket in parent process, agent subprocesses can crash/respawn.
**query.enableRemoteControl**: WebSocket in child process, dies with it.
