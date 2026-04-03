# Claude Code Auto-Memory & Dream System — Technical Deep Dive

## Two-Layer Memory Lifecycle

### Layer 1: Per-Turn Extraction

Uses forked agent pattern sharing parent's prompt cache. Maintains cursor (`lastMemoryMessageUuid`) to process only new messages. Overlap coalescing: if extraction running, new context stashed in `pendingContext`.

**Two-turn strategy**: Turn 1 = all Read ops in parallel. Turn 2 = all Write/Edit ops in parallel.

### Layer 2: Auto Dream (Consolidation)

Three gates (cheapest first):
1. Time gate: >=24 hours since last consolidation (one `stat()` call)
2. Session gate: >=5 transcript files newer than `lastConsolidatedAt`
3. Lock gate: No other process mid-consolidation

**Lock file design**: mtime of `.consolidate-lock` IS `lastConsolidatedAt`. Body stores only PID. One `stat()` call with zero parsing.

Four-phase consolidation: Orient → Gather recent signal → Consolidate → Prune and index.

## Memory Taxonomy Exclusions

Code patterns, architecture, file paths, git history, and debugging recipes explicitly banned — derivable from live code, generate false authority when stale.

## Recall Strategy

Sonnet side-query (256-token budget) selects up to 5 relevant topic files. Tool suppression: if model actively using a tool, that tool's reference docs suppressed. Staleness caveat for memories >1 day old.

## State Management: Closure Pattern

All mutable state in extraction lives inside `initExtractMemories()` closure, not at module level. Enables test isolation.

## Team Memory (TEAMMEM Flag)

Scope tags per memory type. Sensitive data (API keys) must never be saved to team memories.

## KAIROS / Assistant Mode

Shifts to append-only daily logs. Nightly `/dream` skill distills logs into topic files. Path pattern cached to avoid cache invalidation at midnight.

## Key Pattern: Mutual Exclusion

Main agent and forked extractor are mutually exclusive per turn. Detection via `hasMemoryWritesSince()`. Analytics log skips.
