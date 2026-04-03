# Technical Deep Dive: Claude Code Skills System Architecture

## Core Architecture: Six-Stage Pipeline

Discovery → Load → Parse → Substitute → Execute → Inject

### Multi-Source Skill Registry (4 Sources)

| Priority | Source | Location |
|----------|--------|----------|
| 1 | Managed/Policy | `managed/.claude/skills/` |
| 2 | User | `~/.claude/skills/` |
| 3 | Project | `.claude/skills/` |
| 4 | Bundled | Compiled in binary |

Deduplication by resolved file path allows symlinked skills to shadow real ones.

## Argument Substitution Engine

Ordered pattern matching: Named args ($foo) → Indexed args ($ARGUMENTS[0]) → Full string ($ARGUMENTS) → Auto-append.

## Conditional Skills (Path-Based Activation)

Skills with `paths` frontmatter remain loaded but invisible until matching files open. Uses `.gitignore` syntax.

## Forked Execution Model

`context: fork` spawns isolated sub-agents with independent token budgets. Parent receives only final text output.

## MCP Skills Security

Shell injection hard-blocked in source code regardless of `allowed-tools` settings.

## Permission Waterfall

1. Deny rules → Block
2. Remote canonical skills → Auto-allow (experimental)
3. Allow rules → Proceed
4. Safe properties check → Auto-allow if no tools/model/hooks/paths
5. User prompt → Request explicit approval

## Budget Constraints

Skill listing capped at 1% of context window. Bundled descriptions never truncated; custom descriptions shortened if budget exceeded.

## Live Reload

Chokidar file watcher debounces 300ms, fires ConfigChange hooks, clears memoization caches.
