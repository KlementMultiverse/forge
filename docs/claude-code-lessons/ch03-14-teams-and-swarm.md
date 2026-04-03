# Teams & Swarms Architecture: Technical Deep Dive

## Core Pattern: File-Based Coordination

Multi-agent coordination through persistent file-based messaging. Each agent writes to `~/.claude/teams/<team>/inbox/<agent-name>/` as JSON files, with the leader polling directories.

## Backend Abstraction Layer

Three execution backends share a unified `TeammateExecutor` interface:

**tmux**: Highest priority when `TMUX` exists. Pane creation serialized via mutex.
**iTerm2**: Uses `it2 session list` for API availability. Dead-session recovery by pruning stale UUIDs.
**in-process**: Runs in leader's Node.js process with isolated identity via `AsyncLocalStorage`. Independent `AbortController`.

Detection uses environment variables captured at module load time.

## Permission Escalation

Workers create `SwarmPermissionRequest` objects written to leader's inbox. In-process teammates bypass file I/O through `leaderPermissionBridge.ts`.

## Lifecycle Management

**Creation**: Atomic setup — uniqueness check, config.json write, task directory creation, AppState update, cleanup registration.
**Shutdown**: `TeamDelete` blocks if any member has `isActive !== false`.
**Safety Net**: SIGINT triggers `cleanupSessionTeams()` which kills pane-backed processes first.

## Identity & Addressing

Agent IDs follow `agentName@teamName`. Lead is deterministically `team-lead@<team>`. Plan mode: bypass-permissions flags not propagated.

## State Persistence

Everything under `~/.claude/` with no global state: teams config, permissions (pending/resolved), tasks.
