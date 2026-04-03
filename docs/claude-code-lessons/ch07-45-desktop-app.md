# Claude Code Desktop Integration

## Four Subsystems

1. Desktop Handoff (`/desktop` via deep links)
2. IDE Integration (lockfile-based auto-detection)
3. Browser Native Messaging (Chrome extension protocol)
4. Computer Use MCP (OS automation, gated)

## Desktop Handoff State Machine

checking → prompt_download/flushing → opening → success/error. Session flush before deep link opens.

## Platform Detection

macOS: path + plist version. Linux: xdg-mime query. Windows: registry query.

## Lockfile-Based IDE Discovery

JSON at `~/.claude/ide/<port>.lock`. Process liveness via `kill(pid, 0)`. Sorted by mtime.

## Fast-Path CLI

Special flags bypass normal boot: --chrome-native-host, --computer-use-mcp, --daemon-worker.

## Portable Storage Module

Dependency-free `sessionStoragePortable.ts` for cross-boundary code sharing.

## Computer Use Gating

Build-time DCE + runtime subscription + GrowthBook + sub-gates. Coordinate mode frozen at first read.

## Portable Binary Management

XDG-compliant paths. Multi-process PID-based coordination. 2 versions retained. 7-day stale lock timeout.
