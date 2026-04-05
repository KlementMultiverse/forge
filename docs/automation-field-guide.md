# Building Automation on Claude Code — Field Guide

Everything we learned building Forge: what works, what breaks, and why.

---

## Part 0: The Two Pipes (Most Important Concept)

Claude Code reads files through **two different pipes**. Understanding this is the foundation of everything else.

### Pipe 1: Auto-Load (CLAUDE.md, .claude/rules/*.md)

```
File on disk → strip frontmatter → strip block-level HTML comments → system prompt → LLM
```

This happens **automatically** when Claude Code starts. You don't control it. The LLM sees the **stripped** version — no frontmatter, no block-level comments.

### Pipe 2: Read Tool (agent calls Read on a file)

```
File on disk → raw content as-is → tool result → LLM
```

This happens when an agent explicitly reads a file. The LLM sees **everything** — comments, frontmatter, all of it.

### Why this matters

Template files (CLAUDE.md, rules) get auto-loaded through Pipe 1. If they have placeholder text like `{{PROJECT_NAME}}` or fake instructions, the LLM treats them as real. That's **context poisoning**.

The fix: wrap template content in block-level HTML comments.

```markdown
# New Project
<!-- {{FORGE_PLACEHOLDER}} — detected by hooks, invisible to LLM -->

<!--
TEMPLATE (agents: Read this file, replace all {{PLACEHOLDERS}}):

# {{PROJECT_NAME}}

## Tech Stack
| Layer | Technology | Notes |
|---|---|---|
{{TECH_STACK_ROWS}}

## Architecture Rules
{{ARCHITECTURE_RULES}}
-->
```

**What each reader sees:**

| Reader | How it reads | Sees comments? | Sees `{{PLACEHOLDERS}}`? |
|--------|-------------|----------------|--------------------------|
| LLM (auto-load) | Pipe 1 (stripped) | No | No — sees only `# New Project` |
| Agent (Read tool) | Pipe 2 (raw) | Yes | Yes — knows what to replace |
| Bash hooks/scripts | `grep` on disk | Yes | Yes — can detect placeholders |

**Three audiences, one file, zero poisoning.**

### Rules for template files

1. Only visible text (outside comments) becomes LLM instructions
2. Keep visible text minimal — just enough to not confuse the LLM
3. Put all `{{PLACEHOLDERS}}` and structural references inside `<!-- ... -->` blocks
4. Block-level comments only (own line) — inline comments `text <!-- comment --> text` are NOT stripped
5. Detection scripts (`grep "{{" CLAUDE.md`) read from disk, so comments don't break detection

### Confirmed from source

Claude Code `src/utils/claudemd.ts` function `stripHtmlComments()` uses the CommonMark lexer to identify and remove block-level HTML comment tokens before content reaches the model. Frontmatter between `---` delimiters is also stripped via `frontmatterParser.ts`.

---

## Part 0.5: Command & Agent File Structure (from source code)

Claude Code has **three types of custom files**, each loaded differently:

### Agents (`~/.claude/agents/*.md`)
**YAML frontmatter is required.** Fields:
```yaml
---
name: agent-name          # Used in subagent_type= parameter
description: "..."        # Shown in agent list, used for routing
tools: Read, Glob, Grep   # Tools this agent can use
category: backend         # For organization
---
```
The `name:` field is what you pass to `subagent_type=`. The filename is secondary.

### Commands (`~/.claude/commands/*.md`)
**Frontmatter is optional but powerful.** Key fields:
```yaml
---
description: "..."        # Shown in skill list
allowed-tools: Read,Grep  # Restrict tools (default: all)
model: haiku              # Override model (haiku/sonnet/opus)
effort: high              # Thinking effort (low/medium/high/max)
user-invocable: true      # Can user type /command-name?
context: fork             # inline (default) or fork (run as sub-agent)
agent: backend-architect  # Agent type when forked
---
```

Without frontmatter, description comes from `# /name — description` on line 1.

**`context: fork` is powerful:** Commands with `context: fork` run as sub-agents in isolated context. Heavy commands that produce lots of output won't pollute the main conversation.

### `<system-reminder>` in Commands
System-reminder tags inside command markdown are seen as high-priority instructions by the LLM. Use them for **critical enforcement rules** that must not be ignored:
```markdown
<system-reminder>
Read CLAUDE.md FIRST — follow all architecture rules.
ALL credentials from env vars — NEVER hardcode secrets.
</system-reminder>
```
Not every command needs them. Use for: security-critical steps, data integrity rules, architectural constraints.

### Rules (`~/.claude/rules/*.md`)
Auto-loaded via Pipe 1 (stripped of frontmatter + comments). Frontmatter `paths:` field controls which directories the rule applies to:
```yaml
---
paths: ["apps/**", "tests/**"]
---
```

### Core Component Registry (forge-core.json)

When your automation has 100+ files, you need a single source of truth that tracks:
- **What exists** — every component with path, type, name
- **What's valid** — checksums detect unauthorized changes
- **How to change it** — protocols per component type
- **When it changed** — last verified date

```
forge-core.json:
  protocols:     what makes each component type valid
  components:    path → {type, name, checksum, lines, status}

Change protocol (ALL component types):
  1. GitHub issue first (describe what and why)
  2. Make the change
  3. Run validation (forge-lint.py)
  4. Update registry (forge-lint.py --update-registry)
  5. Commit with issue reference (#N)
```

**Key insight from Claude Code source:** Anthropic doesn't use a master manifest. Instead, they use Zod schemas for runtime type validation + memoized loading + feature gates. For a prompt-driven system like forge, a JSON registry with checksum verification achieves the same goal with simpler tooling.

---

## Part 1: The Mental Model

### Claude Code is not a chatbot — it's a runtime

Think of it as: **prompt → tool calls → state changes → repeat**. Your automation doesn't "talk to Claude" — it configures a runtime that happens to use an LLM as its decision engine.

The 3 levers you control:
1. **System prompt** (CLAUDE.md, rules/) — what the model believes
2. **Tools** (MCP servers, skills, bash) — what the model can do
3. **Context** (what you inject before each step) — what the model sees

Everything else — reasoning, planning, code generation — is emergent from these 3.

### The context window is your RAM

- Sweet spot: 40-60% utilization. Below = underusing the model. Above = degraded reasoning.
- Beginning and end of context are weighted most — the middle gets ignored (lost-in-the-middle effect).
- After ~20 turns, the model effectively forgets early instructions. Plan for this.
- Fresh context per agent is not a cost — it's a feature. Each spawned agent gets a clean window, free from accumulated drift.

### Rules decay. Hooks don't.

A rule in CLAUDE.md works until the context fills up and the model "forgets" it. A hook in settings.json fires every time, mechanically, regardless of context state. If a rule is critical, back it with a hook.

```
Rule:   "always run tests before commit"     → works 80% of the time
Hook:   pre-commit runs test suite            → works 100% of the time
```

**Principle:** Use rules for guidance, hooks for enforcement.

---

## Part 2: Agent Architecture

### The 5 Agent Archetypes

Every agent you'll ever build falls into one of these:

| Archetype | Instruction Ratio | Example |
|-----------|-------------------|---------|
| Domain Expert | 60% facts, 30% process, 10% boundaries | @django-ninja-agent |
| Process Orchestrator | 20% facts, 60% process, 20% boundaries | @forge-pm |
| Quality Judge | 30% facts, 30% process, 40% boundaries | @reviewer |
| Research Scout | 40% facts, 40% process, 20% boundaries | @deep-research-agent |
| Builder/Fixer | 40% facts, 40% process, 20% boundaries | @triangle-fixer |

The ratio matters. A judge with 60% facts and 10% boundaries will approve everything. An expert with 60% process will follow steps but write mediocre code.

### Agent Separation is non-negotiable

The PM orchestrator NEVER writes code. Specialist agents NEVER orchestrate. This isn't bureaucracy — it's context hygiene.

Why it works:
- **Clean context**: each agent sees only what it needs
- **Accountability**: you know which agent produced which output
- **Replaceability**: swap one agent without touching others
- **Fresh judgment**: the judge agent hasn't seen the implementation struggle, so it evaluates fairly

### The Coordinator Pattern

```
User request → PM reads and UNDERSTANDS (never delegates understanding)
            → PM SYNTHESIZES into specific task descriptions
            → PM DELEGATES with: exact task + relevant context + expected output + success criteria
            → Agent executes in FRESH context
            → PM evaluates result + routes to next agent
```

Key insight: the PM's job is to **compress** the problem into a task description that a specialist can execute without needing the full conversation history.

### The Forge Cell — Universal 7-Step Agent Wrapper

Every agent, regardless of domain, executes through this pipeline:

```
1. LOAD CONTEXT   → spec [REQ-xxx], tests, code, library docs, domain rules
2. RESEARCH        → what exists? what's missing? what's changed?
3. IMPLEMENT (TDD) → test FIRST (must FAIL) → code (must PASS) → all tests (no regressions)
4. QUALITY         → format + lint + full suite. Fail? → investigate root cause
5. SYNC            → spec ↔ test ↔ code triangle. Any gap → fix all three
6. JUDGE           → domain reviewer rates 1-5. Below 4 → rework (max 3 attempts)
7. COMMIT + LEARN  → git commit, close issue, save insight to playbook
```

The cell is the constant. The agent's domain expertise is the variable.

---

## Part 3: Context Engineering

### The 4 Context Failure Modes

| Mode | What happens | Fix |
|------|-------------|-----|
| Poisoning | Wrong information dominates → bad decisions | Clear context, start fresh with correct info |
| Distraction | Too much irrelevant detail → important things missed | Compress: only inject what this agent needs |
| Confusion | Contradictory information → inconsistent output | Single source of truth (SPEC.md, not multiple docs) |
| Clash | Context contradicts instructions → unpredictable | Rules in CLAUDE.md override in-context suggestions |

### The Rule of Two

After 2 failed corrections on the same issue: **stop, clear context, restart with a better prompt**. The 3rd attempt in a polluted context almost always fails. A fresh start with a refined prompt almost always succeeds.

### Layered Context Injection

Don't dump everything at once. Layer it:

```
Layer 1: CLAUDE.md          → always loaded, project-level rules
Layer 2: rules/*.md         → always loaded, domain-specific rules
Layer 3: Agent system prompt → loaded when agent spawns
Layer 4: Task-specific       → injected per-task (spec section, relevant code, test file)
Layer 5: Research            → fetched on-demand (context7 docs, web search)
```

Each layer is smaller and more specific than the last. Layer 1 is broad ("use TDD"). Layer 5 is precise ("Django Ninja v1.3 changed router syntax to X").

### HTML Comments = Invisible to the LLM (Confirmed from Source)

Claude Code strips block-level HTML comments (`<!-- ... -->` on their own lines) from CLAUDE.md and rules files BEFORE sending to the model. This is implemented in `stripHtmlComments()` in `src/utils/claudemd.ts`.

Use this for:
- **Template structure references** — keep the knowledge on disk, invisible to the LLM
- **Placeholder markers** — detection scripts (`grep`) read from disk, not LLM context
- **Author notes** — documentation for humans/scripts that the LLM shouldn't act on

```markdown
# New Project
<!-- {{FORGE_PLACEHOLDER}} — detected by hooks, invisible to LLM -->

<!--
STRUCTURE REFERENCE:
## Tech Stack
| Layer | Technology | Notes |
This structure is preserved for agents that read the file directly,
but the LLM never sees it as instructions.
-->
```

**Caveat:** Inline comments within paragraphs are NOT stripped:
```markdown
This text <!-- VISIBLE to LLM --> stays in context
```

**Also stripped:** YAML frontmatter between `---` delimiters (the `paths:` field for conditional rules).

### Front-Load Critical Information

Two micro-operations BEFORE any work:

1. **"Summarize this task in under 50 characters"** — forces the model to crystallize intent, prevents scope drift
2. **"List the files you'll need to touch"** — surfaces dependencies early, catches wrong assumptions

These take 5 seconds and prevent 20 minutes of rework.

---

## Part 4: What Actually Works (Patterns)

### 1. Research Before Building

Three knowledge layers, checked in order:
1. **Framework built-ins** — does the library already do this? (context7 docs)
2. **Community patterns** — what's the current best practice? (web search)
3. **First principles** — if no pattern exists, reason from fundamentals

**Why this matters:** Your training data is stale. Libraries change. APIs deprecate. context7 FIRST, always.

### 2. TDD as a Verification Loop

TDD isn't about "testing methodology" — it's about creating a **mechanical verification loop** that catches drift.

```
Write test (references [REQ-xxx]) → MUST FAIL (proves test is real, not a tautology)
Write code (references [REQ-xxx]) → MUST PASS
Run ALL tests                     → No regressions
```

If the test passes before you write code, the test is wrong. If all tests don't pass after, you broke something. Both are immediate signals.

### 3. The Spec ↔ Test ↔ Code Triangle

Every requirement [REQ-xxx] must exist in all three:
- **SPEC.md** — what it should do
- **test file** — proof it works
- **code file** — implementation

Orphan in any vertex = drift. Check all three after every change. The triangle-fixer agent exists specifically for this.

### 4. Per-Issue Commits (Not Monolithic)

One issue = one commit. Never batch. Why:
- **Bisectable**: `git bisect` finds exactly which issue broke things
- **Reviewable**: PRs are readable
- **Revertible**: bad change? revert one commit, not untangle a monolith

### 5. Quality Gates Block, Not Warn

A gate that warns is a gate that gets ignored. Gates must **block** — no proceeding until the check passes.

```
code → /review (inline) → fix → commit → /gate (blocks) → PR
```

Never skip /review before /gate. Never skip /gate before PR.

### 6. Self-Improving Playbook

Every rule has counters: `helpful=N harmful=M`. Rules that help get reinforced. Rules that hurt get pruned. The system literally gets smarter with every build.

```
New insight → /learn (helpful=0, harmful=0)
Used and worked → helpful++
Used and caused problems → harmful++
harmful > helpful → auto-pruned
```

### 7. Confidence Routing

Every agent output needs a confidence indicator:

```
HIGH (>90%)    → proceed automatically
MEDIUM (60-90%) → present alternatives, let PM decide
LOW (<60%)     → STOP, ask user, do NOT proceed
```

Without this, hallucinated answers look identical to well-researched ones.

---

## Part 5: What Breaks (Anti-Patterns)

### 1. "I know how to do this"
The model's training data is months old. Libraries change weekly. ALWAYS check context7 docs, even for libraries you've used 100 times.

### 2. Infinite retry loops
Agent fails → retry → fails → retry → fails. Cap at 3, then escalate. The 4th attempt in a poisoned context never works.

### 3. Monolithic agents
One agent that reads spec, writes code, runs tests, reviews itself, and commits. It will drift, lose context, and produce garbage by step 4.

### 4. PM writes code
The orchestrator touching implementation code means it's now biased when evaluating results. Separation of concerns isn't optional.

### 5. Skipping research
"Just implement it" without checking current library versions, API changes, or community patterns. Guaranteed to produce code that uses deprecated APIs.

### 6. Rules without enforcement
"Always validate input" in CLAUDE.md without a hook or gate that checks. Rules decay; hooks don't.

### 7. Context stuffing
Injecting entire files, full specs, complete test suites into agent prompts. The model drowns. Inject only the relevant section.

### 8. "I'll add tests later"
Later never comes. And when it does, you've forgotten the edge cases. Test first or don't test at all.

---

## Part 6: The Infrastructure

### Claude Code Extension Points

| Mechanism | What it does | When to use |
|-----------|-------------|-------------|
| CLAUDE.md | Project-level instructions, always loaded | Project rules, conventions, architecture notes |
| rules/*.md | Additional instruction files, always loaded | Domain-specific rules (security, logging, etc.) |
| settings.json hooks | Shell commands on events (pre-tool, post-tool) | Enforcement (block commits without tests, etc.) |
| Skills (/commands) | User-invocable prompt templates | Reusable workflows (/commit, /review, /gate) |
| MCP servers | External tool providers | API integrations (context7, GitHub, custom) |
| Agent definitions | Specialized subagent configs | Domain experts, judges, orchestrators |
| Memory system | Persistent cross-session storage | User prefs, project state, lessons learned |

### The Tool System (from Claude Code internals)

- Tools default to **most restrictive** (fail-closed): not concurrent, not read-only, not destructive
- Tools must explicitly opt INTO permissive behavior
- Three copies of input exist: API-bound (immutable), observable (for hooks), call input (hooks can modify)
- Tool descriptions are prompts — they guide the model's behavior as much as system instructions

### Hooks > Rules > Guidelines

Enforcement hierarchy:
```
Hooks (settings.json)     → mechanical, 100% reliable, can't be forgotten
Rules (CLAUDE.md, rules/) → prompt-based, ~80% reliable, degrades with context length
Guidelines (conversation) → ephemeral, works for current turn only
```

If something MUST happen every time → make it a hook.
If something SHOULD happen most times → make it a rule.
If something is nice-to-have → mention it in conversation.

---

## Part 7: The Build Philosophy

### Complete the Lake

- **Lakes** (achievable in a session) — do the FULL implementation. No half-done features.
- **Oceans** (unrealistic scope) — break into lakes. Each lake is 100% complete before the next.

Anti-pattern: "I'll add error handling later." No. Add it now.

### Deterministic Flow, Non-Deterministic Growth

The FLOW is fixed: phases 0→1→2→3→4→5→6, gates between each, reviews before gates.
The GROWTH is organic: new agents emerge, playbook grows, prompts improve, steps get added.

But growth ALWAYS goes through the flow: propose → review → gate → merge.

### User Sovereignty

AI recommends. Users decide. This overrides ALL rules.

If the user says "skip tests" → skip tests (warn about consequences).
If the user says "use React" and feasibility says "use templates" → use React.
The system serves the user, not the other way around.

---

## Part 8: Quick Reference Card

### Starting a new automation project
```
1. Define the 5 inputs: Problem, User, Data model, Tech stack, Rules
2. Write SPEC.md with [REQ-xxx] tags
3. Set up CLAUDE.md with project rules
4. Create agent definitions for your domain
5. /forge and let the pipeline run
```

### When things go wrong
```
Test fails?         → /investigate (root cause before fix)
Agent drifting?     → Clear context, restart with better prompt
Gate blocked?       → Fix the issue, don't bypass the gate
Model hallucinating? → Inject real data via context7/MCP
3 retries failed?   → STOP, document, ask user
```

### The numbers that matter
```
Context utilization: 40-60% (sweet spot)
Max retries per issue: 3
Agent judge threshold: ≥4 out of 5
Triangle coverage: 100% (0 orphans, 0 drift)
File size limit: 300 lines
```

---

## Part 9: Claude Code Internals (from source analysis)

Everything below comes from analyzing the Claude Code v2.1.88 source (~500K lines).
Source: `~/projects/claudecode-leak/claude-code-beita-buildable/`

### The Main Loop — How It Actually Works

```
User starts `claude`
    ↓
main.tsx (line 598): Entry point
  ├── Parallel init: keychain prefetch + MDM policy read
  ├── CLI arg parsing (commander.js)
  ├── Client type detection (CLI/SDK/VSCode/desktop)
  └── run() → preAction hook → init()
    ↓
buildEffectiveSystemPrompt() (systemPrompt.ts):
  Priority: override > coordinator > agent > custom > default
  Agent prompt either REPLACES or APPENDS to default
    ↓
getMemoryFiles() (claudemd.ts):
  Load order: /etc/ → ~/.claude/ → ./CLAUDE.md → .claude/rules/ → CLAUDE.local.md
  MAX_MEMORY_CHARACTER_COUNT = 40,000 chars
  @include directives for cross-file references
    ↓
launchRepl() → React REPL component (Ink framework)
    ↓
Message loop:
  1. User input → PromptInput
  2. UserPromptSubmit hooks fire
  3. normalizeMessagesForAPI()
  4. attachContext() → system prompt + memory + attachments
  5. checkTokenBudget()
  6. client.messages.create(stream: true)
  7. Stream events: text blocks + tool_use blocks
  8. For each tool_use:
     a. PreToolUse hooks
     b. Permission check (canUse())
     c. tool.invoke()
     d. PostToolUse hooks
  9. Continue until stop_reason === 'end_turn'
  10. Stop hooks fire
  11. Back to step 1
```

### CLAUDE.md Loading — The Exact Path

```
Source: src/utils/claudemd.ts

Load order (low to high priority):
  1. /etc/claude-code/CLAUDE.md     (enterprise policy — managed)
  2. ~/.claude/CLAUDE.md            (user global)
  3. ./CLAUDE.md                    (project root)
  4. ./.claude/CLAUDE.md            (project hidden)
  5. ./.claude/rules/*.md           (project rules)
  6. ./CLAUDE.local.md              (local private — not committed)

Processing:
  - YAML frontmatter stripped (--- ... ---)
  - Block-level HTML comments stripped (<!-- ... -->)
  - Inline comments NOT stripped
  - @include directives resolved (prevents circular refs)
  - Result injected as system prompt section

Key constant: MAX_MEMORY_CHARACTER_COUNT = 40,000
If total exceeds this, content is truncated.
```

### Hook System — Every Event Type

```
Source: src/utils/hooks.ts (3600+ lines)

ALL hook events (from source):
  Setup              → on init (before trust dialog)
  SessionStart       → on session start
  SessionEnd         → on shutdown (1500ms timeout!)
  PreToolUse:<tool>  → before tool execution (can BLOCK with exit 2)
  PostToolUse:<tool> → after tool execution
  PostToolUseFailure → tool execution failed
  Stop               → when model's turn stops
  UserPromptSubmit   → before user message sent to API
  Notification       → send notification to user
  PermissionDenied   → permission check failed
  ConfigChange       → settings changed
  FileChanged        → file modified on disk
  InstructionsLoaded → CLAUDE.md loaded/reloaded
  PermissionRequest  → permission decision needed
  SubagentStart      → sub-agent spawned
  SubagentStop       → sub-agent finished
  TaskCreated        → task tool used
  TaskCompleted      → task finished

Hook execution:
  1. Check trust dialog accepted (security — untrusted repos)
  2. Find hooks matching event + tool name (matcher field)
  3. Execute shell command
  4. Parse JSON output
  5. Return result to model (injected as context)

Timeout: 600 seconds for most hooks
         1500ms for SessionEnd (fast shutdown)

CRITICAL SECURITY: Hooks blocked until trust dialog accepted.
Reason: .claude/settings.json is attacker-controllable in cloned repos.
```

### Settings Merge — Priority Order

```
Source: src/utils/settings/settings.ts

Priority (highest wins):
  1. --settings <json>           (inline CLI flag)
  2. --settings <file>           (file CLI flag)
  3. .claude/settings.local.json (project local — gitignored)
  4. .claude/settings.json       (project — committed)
  5. ~/.claude/settings.json     (user global)
  6. managed-settings.json       (enterprise MDM)
  7. managed-settings.d/*.json   (enterprise drop-in, alphabetical)
  8. Built-in defaults

Merge rules:
  - Arrays: REPLACED (not merged/concatenated)
  - Objects: recursively deep-merged
  - Primitives: later values override earlier

Cache strategy:
  - In-memory cache per source
  - Cloned before returning (prevent mutation bugs)
  - Invalidated by file watcher events
```

### Agent Spawning — What Sub-Agents Get

```
Source: src/tools/AgentTool/runAgent.ts

When you spawn Agent with subagent_type="backend-architect":

  1. Create new agentId (UUID)
  2. Track parentAgentId (for nesting)
  3. Load agent definition:
     - System prompt from agent .md file
     - Tools filtered by agent's tools: field
     - Model override if specified
  4. Build messages array (prompt from parent)
  5. Enter SAME query loop as main thread:
     - normalizeMessages → API call → tool execution → repeat
  6. Sub-agent has ISOLATED context:
     - Own agentId
     - Own tool budget
     - Own token limits
     - Filtered tool set (only what frontmatter allows)
  7. Return result to parent when stop_reason = 'end_turn'

Key insight: Sub-agents run the EXACT same code as the main loop.
They're not a different system — they're the same loop with a different
system prompt and filtered tools.
```

### Skill Execution — /command Flow

```
Source: src/tools/SkillTool/SkillTool.ts

When you type /discover:

  1. SkillTool.invoke() called
  2. Skill found by name from:
     - Built-in skills (hardcoded)
     - Bundled skills (from plugins)
     - Plugin skills (from ~/.claude/commands/)
     - MCP skills (from MCP servers)
  3. Check context: field:
     - "inline" (default): skill prompt injected into CURRENT conversation
     - "fork": skill runs as SUB-AGENT in isolated context
  4. If forked:
     - New agentId created
     - Skill prompt loaded as agent system prompt
     - Runs in isolation (same as Agent spawning above)
  5. Result returned to main conversation

Key insight: context: fork is powerful.
Heavy skills that produce lots of output won't pollute the main window.
```

### Token Management — Context Window as RAM

```
Source: src/utils/tokens.ts (lines 226-261)

tokenCountWithEstimation() — THE source of truth:
  - Uses last API response usage (exact)
  - Adds rough estimation for new messages since
  - Handles parallel tool calls: walks back past siblings

Budget enforcement:
  - Checked BEFORE API call (checkTokenBudget)
  - Checked AFTER each response (applyTokenBudget)
  - Terminates query early if exhausted

Token types tracked separately:
  - input_tokens (prompt)
  - cache_creation_input_tokens (new cache writes)
  - cache_read_input_tokens (cache hits)
  - output_tokens (model response)

Context window vs billing:
  - Context = input + cache_read (what model "sees")
  - Billing = input + cache_creation + output (what you pay for)
```

### Permission System — Three-Way Decisions

```
Source: src/utils/permissions/

Permission modes:
  default      → ask user every time
  plan         → paused (no execution)
  acceptEdits  → auto-approve file edits
  bypassAll    → skip all checks
  dontAsk      → deny all
  auto         → classifier-based (Anthropic internal)

Denial tracking (denialTracking.ts):
  - 3 consecutive denials → fallback to prompting
  - 20 total denials → fallback to prompting
  - Prevents "classifier thrashing"

Rule sources (hierarchical):
  CLI args → settings files → command-level → session-only
```

### Memory System — Auto-Memory Implementation

```
Source: src/memdir/memdir.ts

Directory: ~/.claude/projects/<project-slug>/memory/
Index: MEMORY.md (max 200 lines, 25KB)

Truncation rules:
  - Lines > 200 → truncate + warning
  - Bytes > 25,000 → truncate at last newline + warning

Memory types: user, feedback, project, reference

Frontmatter format:
  ---
  name: "required"
  description: "required"
  type: user | feedback | project | reference
  ---

Key behavior: Memory directory pre-created.
The system prompt tells the model "directory already exists —
write to it directly, don't check existence."
This prevents wasted tool calls.
```

### Session Persistence

```
Source: src/services/SessionMemory/sessionMemory.ts

Session memory extraction:
  - Runs ASYNCHRONOUSLY in background
  - Uses forked sub-agent (isolated from main loop)
  - Tracks init threshold + update threshold
  - Uses same token count metric as autocompact
  - Last summarized message ID tracked (no re-summarize)

Session state (bootstrap/state.ts):
  - sessionId: unique per session
  - parentSessionId: for plan → implementation lineage
  - sessionSource: origin tracking
  - sessionPersistenceDisabled: for ephemeral sessions
```

### Worktree Isolation — How It Works

```
Source: src/utils/worktree.ts

When Agent runs with isolation: "worktree":
  1. Create git worktree (temporary branch)
  2. Validate slug (max 64 chars, no traversal)
  3. Symlink large dirs (node_modules) from main repo
  4. Agent works on isolated copy
  5. If changes made → return worktree path + branch
  6. If no changes → auto-cleanup

Security:
  - Path traversal blocked (.. sequences)
  - Segment validation (alphanumeric + dots/underscores/dashes)
  - commondir validation (prevents malicious gitdir: pointers)

Two roots tracked:
  - originalCwd: where session started
  - projectRoot: stable identity (never updated mid-session)
```

### Patterns to Replicate in Any Automation

```
1. PARALLEL INIT: Start expensive I/O (keychain, settings, git) in parallel
2. CACHE + CLONE: Cache settings, clone before returning (prevent mutation)
3. TRUST BOUNDARY: Block hooks until trust accepted (untrusted repos)
4. DENIAL STATE MACHINE: Track consecutive + total denials, fallback gracefully
5. MONOTONIC EVENTS: Use sequence counter for event ordering
6. FORKED CONTEXT: Heavy operations in sub-agents (isolated context window)
7. PRE-CREATE DIRS: Tell model "dir exists, write directly" (saves tool calls)
8. CHECKSUM REGISTRY: Detect unauthorized changes via hash comparison
9. FEATURE GATES: Compile-time (dead code elimination) + runtime (env vars)
10. SESSION LINEAGE: Track parent→child sessions for continuity
```

---

*This document is a living artifact. Every build teaches something new. Update it.*
