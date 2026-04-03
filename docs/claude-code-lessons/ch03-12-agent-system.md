# Claude Code Agent System: Technical Architecture

## Core Architecture

**Agent Delegation Model**: Hierarchical agent spawning — each a separate LLM turn with own tool pool, system prompt, model, and optional filesystem isolation.

**Type System**: Three discriminated union types via `source` field:
- Built-in (dynamic prompts via `getSystemPrompt`)
- Custom (user/project/policy settings from `.claude/agents/*.md`)
- Plugin (bundled with `--plugin-dir`, admin-trusted)

## Priority Resolution

Policy settings override all others: built-in → plugin → userSettings → projectSettings → flagSettings → policySettings.

## Execution Model: Single Branch Point

**Sync path**: Blocks parent turn, returns `status: 'completed'`
**Async path**: Returns `status: 'async_launched'` immediately with `agentId`, `outputFile`, `canReadOutputFile`

## Fork Path Innovation

Maximizes prompt-cache sharing through byte-identical request prefixes:
1. Clones parent's full assistant message
2. Builds identical placeholders for every tool_result
3. Appends single per-child directive (only differing element)

Guards against recursion via `querySource === 'agent:builtin:fork'` and `isInForkChild(messages)`.

## Worktree Isolation

Creates temporary git worktree. Diffs against pre-spawn headCommit. Deletes worktree if no git-tracked changes; keeps branch if changes exist.

## Inter-Agent Messaging

`SendMessageTool` routing: teammate name → mailbox file, `"*"` → broadcast, `shutdown_request/response` → structured protocol, `"uds:<path>"` → Unix domain socket, `"bridge:<session-id>"` → remote.

## Built-In Agent Specializations

| Agent | Model | Tools | Lifecycle |
|-------|-------|-------|-----------|
| general-purpose | default | `['*']` | sync/async |
| Explore | haiku/inherit | read-only | sync |
| Plan | inherit | read-only | sync |
| verification | inherit | no Edit/Write; /tmp scripts | always async |

## Performance Optimization

`omitClaudeMd: true` on Explore and Plan saves ~5-15 Gtok/week by eliminating commit/PR/lint rules from system prompts.
