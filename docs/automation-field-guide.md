# Building Automation on Claude Code — Field Guide

Everything we learned building Forge: what works, what breaks, and why.

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

*This document is a living artifact. Every build teaches something new. Update it.*
