# Technical Deep Dive: Claude Code's Notification System

## Two Separate Pipelines

1. **In-REPL Toast Queue** — React state for interactive status messages
2. **OS/Terminal Notifier** — Raw OSC/BEL escape sequences for backgrounded sessions

## Toast Queue: Priority-Based Dequeue

`immediate` preempts current display; `high`/`medium`/`low` in order. Single active slot + unbounded queue. Module-level `currentTimeoutId` for synchronous timeout cancellation.

**Fold function**: Merges same-key notifications in place, preventing spam during rapid state changes.

**Timeout handling**: Dependencies passed as callback arguments, not closed over, preventing stale closure bugs.

## OS Notification Routing

Per-terminal protocols: iTerm2 (OSC 9), Kitty (OSC 99 three-step), Ghostty (single OSC), BEL (0x07 unwrapped for tmux).

## Hook Pattern: useStartupNotification

Encapsulates boilerplate for 14 specialized hooks. Ref-based latest compute function avoids stale closures and re-firing.

## Background Task Collapsing

`collapseBackgroundBashNotifications()` collapses only successful completions. Failed/killed tasks remain individual.

## MCP Channel Security

Six sequential validation layers for inbound messages: capability, feature flag, OAuth, org policy, session opt-in, plugin allowlist.
