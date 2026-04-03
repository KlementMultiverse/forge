# Claude Code Memory System — Technical Architecture

## Three-Layer Memory Model

1. **Auto Memory** (`~/.claude/projects/<slug>/memory/`): User-scoped, survives across sessions
2. **Session Memory** (`~/.claude/session-memory/<uuid>.md`): Ephemeral, powers context compaction
3. **Team Memory** (`memory/team/` via API): Server-synced per-repository, shared across collaborators

## Auto Memory Structure

### Index-Based Routing
Master index `MEMORY.md` (capped at 200 lines/25KB) loaded into every system prompt. Topic files with YAML frontmatter declaring name, description, type.

### Four-Type Closed Taxonomy
- **user**: Always private (role, expertise)
- **feedback**: Private by default; team for project-wide conventions
- **project**: Bias toward team (ongoing initiatives, absolute dates)
- **reference**: Usually team (external system pointers)

## Extraction Pipeline

Sequential, non-blocking after query completion:
1. Gate check (feature flag + cursor delta)
2. Directory scan (frontmatter headers only)
3. Fork agent (perfect clone, shared cache)
4. Max 5 extraction turns before cursor advance

### Mutual Exclusion
Main agent and extraction agent coordinate via `hasMemoryWritesSince()`. Extraction skips when main agent has written.

### Relevance Recall
Sonnet selector picks up to 5 relevant files reading only first 30 lines each (frontmatter range).

## Session Memory for Compaction

Fixed-section template: Current State, Task specification, Files/Functions, Workflow, Errors, Learnings, Results, Worklog.

**Dual throttling**: 10K minimum tokens to initialize; 5K growth + 3 tool calls between updates. 12K total cap.

## Team Memory Sync

Delta-based push with SHA-256 hash comparison. 35-rule secret scanner blocks pushes before transmission.

## Feature Gating

`CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`, `CLAUDE_CODE_SIMPLE=1`, GrowthBook flags, settings overrides (not from projectSettings for security).
