# Claude Code Task System

## Unified Task Abstraction

Seven types (local_bash, local_agent, remote_agent, in_process_teammate, local_workflow, monitor_mcp, dream) sharing common infrastructure.

## Atomic One-Way Latch

`notified` field uses compare-and-set within `updateTaskState` — ensures exactly one XML notification despite concurrent handlers.

## Five-State Lifecycle

Terminal states (completed, failed, killed) trigger: notification flag flip, enqueue XML message, eviction eligibility. Terminal states are absorbing.

## Output: Two-Layer Design

**File Mode** (bash): Stdout/stderr bypass JavaScript via OS file descriptors. Progress via 1-second file-tail polling.
**Pipe Mode** (agents): 8MB in-memory buffer with disk spillover.

Security: `O_NOFOLLOW` flag prevents symlink path traversal.

## Reference-Equality Optimization

Skip React re-renders when updater returns same object reference.

## Token Counting Asymmetry

input_tokens: cumulative → store latest. output_tokens: per-turn → sum all.

## Memory Safety: 50-Message Cap

Prevents 36.8GB RSS from swarm sessions (292 agents). FIFO eviction.

## DreamTask Lock Rewinding

Kill path includes explicit lock rollback to prevent permanent deadlock.

## Plugin Completion Checkers

`registerCompletionChecker()` decouples domain logic from framework poll machinery.

## UI-only Tasks

DreamTask sets `notified: true` immediately without enqueueing XML.
