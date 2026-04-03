# Claude Code Internals — Patterns for Forge

Extracted from 50-lesson deep dive into Claude Code v2.1.88 source (1,902 files, 512K+ lines).

## Tool System Patterns

### buildTool() Factory with Fail-Closed Defaults
Every tool defaults to most restrictive: `isConcurrencySafe=false`, `isReadOnly=false`, `isDestructive=false`. Tools must explicitly opt INTO permissive behavior.

### Three-Tier Registration Pipeline
1. `getAllBaseTools()` — exhaustive catalog
2. `getTools()` — context-specific filtering (deny rules, feature flags, per-tool veto)
3. `assembleToolPool()` — built-in + MCP tools combined, sorted for prompt cache stability

### Three Input Copies
- API-bound original (never mutated — protects cache serialization)
- Backfilled observable clone (for hooks to inspect)
- Call input (hooks can update before execution)

### Concurrent Batching
Consecutive `isConcurrencySafe=true` tools batch and run parallel. Non-safe tools break batches. Results yielded in insertion order despite concurrent execution. Bash errors abort siblings (implicit dependency chains).

### Execution Pipeline (9 steps)
1. Zod `safeParse(input)` → fails immediately
2. `validateInput()` — semantic checks (path traversal, limits)
3. Speculative classifier starts
4. `backfillObservableInput` — shallow clone
5. PreToolUse hooks (async generators, can update input)
6. `canUseTool()` gate (allow/deny/ask rules)
7. `tool.call()` — actual execution
8. PostToolUse hooks
9. Result serialization with size-budget

## MCP Integration Patterns

### Server State Machine
`pending` → `connected` / `failed` / `needs-auth` / `disabled`

### 7-Layer Config Scope Cascade
1. enterprise (MDM) — blocks all user changes
2. dynamic (CLI flags)
3. claudeai (Claude.ai connector)
4. project (`.mcp.json` nearest wins)
5. local (`~/.claude/projects/<hash>/`)
6. user (`~/.claude/settings.json`)
7. managed (plugin-provided)

### Timeout Race Pattern
```typescript
await Promise.race([connectPromise, timeoutPromise])
// timeout closes transport, rejects with error
// connect clears timeout on success or failure
```

### Tool Namespacing
`mcp__${normalize(server)}__${normalize(tool)}` — enables blanket deny rules per server.

### Reconnect with Exponential Backoff
1s → 2s → 4s → 8s → 16s → 30s (cap), max 5 attempts.

### Description Hard Cap
2048 chars for tool descriptions and server instructions.

## Agent System Patterns

### Sync vs Async Branching
Single `shouldRunAsync` boolean. 6 conditions trigger async: explicit background flag, coordinator mode, fork experiment, KAIROS, proactive mode.

### Fork with Byte-Identical Prefixes
Placeholder `"Fork started — processing in background"` for all `tool_result` blocks creates identical prefix across children → maximizes prompt cache hits.

### Tool Pool Management
`tools: ['*']` = all tools, then `disallowedTools: []` subtracts. Read-only agents (Explore, Plan) set `omitClaudeMd: true` to save tokens.

### Inter-Agent Communication
`SendMessageTool` supports: string to named teammate, broadcast (`"*"`), UDS socket, bridge session. Also structured `shutdown_request`/`shutdown_response`.

## Skills System Patterns

### SKILL.md with YAML Frontmatter
Skills are Markdown files with YAML frontmatter. Directory name = slash command. Four discovery locations: managed > user > project > bundled.

### Six-Stage Lifecycle
Discovery → Load → Parse → Substitute → Execute → Inject

### Execution Modes
- **Inline (default)**: expands into current conversation
- **Forked (`context: fork`)**: isolated sub-agent with own token budget

### Three Substitution Patterns
1. Named args: `$foo`, `$bar`
2. Indexed args: `$ARGUMENTS[0]`, `$0`, `$1`
3. Full arg string: `$ARGUMENTS`
4. Fallback: append as `ARGUMENTS: ...`

### Live Reloading
chokidar watches skill directories, 300ms debounce, fires ConfigChange hooks, clears caches.

## Memory System Patterns

### Extraction Timing
After each complete query loop (not during conversation). Uses extraction agent for max 5 turns.

### Extraction Throttling
- Minimum 10,000 tokens to initialize
- Minimum 5,000 tokens between updates
- 3 tool calls between updates

### MEMORY.md Index
Loaded into every conversation. Capped at 200 lines / 25,000 bytes. Contains pointer list only.

### Topic File Selection
Up to 5 files selected by lightweight model reading only first 30 lines (frontmatter). Files >1 day old get freshness warning.

### Token Enforcement
12,000 tokens total, 2,000 per section. Hard truncation at line boundary.

### Security
- Path traversal defense: `path.resolve()` + `realpath()` on deepest existing ancestor
- Secret scanning: 35+ patterns from gitleaks ruleset before push

## Hooks System Patterns

### 27 Hook Events
Spanning: session lifecycle, tool execution, agent/subagent, compaction, permission/policy, filesystem.

### 5 Hook Command Types
1. **command** — shell subprocess, JSON on stdin
2. **prompt** — LLM query (no recursion — doesn't trigger UserPromptSubmit)
3. **agent** — multi-turn sub-agent (max 50 turns)
4. **http** — POST to URL with SSRF guard
5. **function** — in-process TypeScript callback

### Universal Exit Code Protocol
- **Exit 0**: silent success
- **Exit 2**: model-visible blocking (tool BLOCKED)
- **Other non-zero**: user-visible noise only

### `once: true` Self-Destructing Hooks
One-shot initialization that auto-removes after first success.

### Async Hooks
`async: true` = fire and forget. `asyncRewake: true` = background, wakes model on exit code 2.

## Applicable to Forge

| Pattern | Where in Forge |
|---|---|
| Fail-closed defaults | Agent prompts — conservative by default, explicitly opt into permissive |
| Three-tier registration | PM orchestrator — catalog all agents, filter by project, assemble for task |
| Timeout race | context7 calls, web search — never hang indefinitely |
| 7-layer config cascade | .forge/ local > project CLAUDE.md > global ~/.claude/ |
| Exit code 2 blocking | hooks/hooks.json — PreToolUse blocking via exit codes |
| SKILL.md frontmatter | Our commands/*.md already follow this pattern |
| Memory extraction timing | /learn captures after task completion, not during |
| Prompt cache optimization | Fork byte-identical prefixes when spawning parallel agents |
| Tool namespacing | MCP tools get `mcp__server__tool` naming to enable deny rules |
