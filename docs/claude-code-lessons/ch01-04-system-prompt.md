# System Prompt Construction Architecture: Key Patterns

## Priority Waterfall Pattern
The framework implements a strict cascading resolver that prevents ambiguity:

```
override → coordinator → agent → custom → default
```

Only the first matching layer executes; lower tiers are skipped entirely. The `appendSystemPrompt` always appends regardless of branch, creating a predictable composition model.

## Static/Dynamic Boundary Optimization
The prompt splits into two halves separated by a marker token:

- **Static prefix** (globally cacheable, identical across sessions)
- **Dynamic tail** (session-specific: CWD, git state, CLAUDE.md files)

"Everything before the marker can use `scope: 'global'` in the API call — cacheable across all organisations. Everything after contains session-specific content."

## Memoized Section Registry
Dynamic sections use a named registry with two cache strategies:

```typescript
systemPromptSection(name, compute)  // memoized per-session
DANGEROUS_uncachedSystemPromptSection(name, compute, reason)  // recomputes every turn
```

Only `mcp_instructions` is volatile because "MCP servers can connect and disconnect mid-session." Others cache aggressively.

## Hierarchical CLAUDE.md Discovery
Files load in priority order (lower first, higher last):

1. Managed memory (`/etc/claude-code/CLAUDE.md`)
2. User memory (`~/.claude/CLAUDE.md`)
3. Project memory (`CLAUDE.md`, `.claude/rules/*.md`)
4. Local memory (`CLAUDE.local.md`)

Files closer to CWD appear later, gaining higher effective priority. The `@include` directive allows composition; frontmatter `paths` gates instructions to glob patterns.

## Subagent Enhancement Pattern
Subagents bypass full prompt assembly, starting from a lean default:

"You are an agent for Claude Code... Complete the task fully—don't gold-plate, but don't leave it half-done."

Then `enhanceSystemPromptWithEnvDetails()` appends context-specific notes about paths, emoji policies, and tool syntax.

## Escape Hatches for Different Modes

| Mode | Effect |
|------|--------|
| `CLAUDE_CODE_SIMPLE=1` | Three-line stub (benchmark mode) |
| Proactive/KAIROS | Short autonomous-agent prompt instead of interactive guidance |
| Undercover | Strip all model name references (internal builds) |

## Model Launch Annotation Pattern
Every "// @[MODEL LAUNCH]" comment marks knowledge-cutoff dates, model families, and capability references that require human review per new Claude release.
