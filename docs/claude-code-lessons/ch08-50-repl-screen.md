# REPL.tsx Architecture

## Ref-Based State Management

Reads state via refs inside callbacks to prevent cascading recreation. Synchronously sync refs on every render, async reads via `.current`.

## QueryGuard State Machine

Generation counter prevents stale `finally` blocks from corrupting state. Handles concurrent cancellation without race conditions.

## Dialog Priority Queue

`getFocusedInputDialog()` returns single string union deterministically. No ad-hoc boolean proliferation.

## Turn Lifecycle Chain

onSubmit (entry) → onQuery (concurrency guard) → onQueryImpl (API call + streaming). Immediate commands bypass queue.

## Three Independent Loading Sources

isQueryActive, isExternalLoading, hasRunningTeammates. Combined for spinner visibility.

## Ephemeral Progress Replacement

Replaces previous tick for same tool ID in-place instead of appending (prevents 13k+ entries).

## Deferred Rendering

`useDeferredValue(messages)` renders at transition priority, keeping input responsive during streaming.

## Fullscreen vs Transcript Mode

Two render paths from single state toggle. Transcript: VirtualMessageList (250MB saved). Fullscreen: FullscreenLayout + ScrollBox.

## Session Resume: 14-Step Atomic

Deserialize, hooks, plan slug, file history, agent definition, costs, state reset, session ID switch, metadata clear/restore, worktree, state reconstruct.

## Performance

Timing refs (not state) for elapsed spinner. Unseen divider caching. Isolated animation leaf component.
