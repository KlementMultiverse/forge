# SuperClaude vs Forge PM — Feature Comparison

**Date:** 2026-04-02
**Files Compared:**
- SuperClaude: `~/.claude/commands/sc/pm.md`, `test.md`, `implement.md`, `workflow.md`
- Forge: `agents/universal/pm-orchestrator.md`, `commands/forge.md`

---

## 1. PDCA Cycle (Plan-Do-Check-Act)

### SuperClaude sc:pm
- Full PDCA cycle with **file-based artifacts** per feature:
  - `docs/pdca/[feature]/plan.md` — hypothesis + expected outcomes (quantitative)
  - `docs/pdca/[feature]/do.md` — chronological implementation log with timestamps
  - `docs/pdca/[feature]/check.md` — results vs expectations table (expected/actual/status)
  - `docs/pdca/[feature]/act.md` — formalized patterns, CLAUDE.md updates, checklist updates
- Lifecycle is explicit: plan.md created first, do.md updated continuously, check.md at completion, success -> docs/patterns/, failure -> docs/mistakes/

### Forge PM
- PDCA is mentioned in session lifecycle section but **lacks the structured file templates**
- Has `docs/pdca/[feature]/do.md` referenced once in error investigation
- No explicit plan.md/check.md/act.md templates
- No quantitative expected vs actual comparison

### Verdict: **Forge is MISSING structured PDCA artifacts**
- **Important: YES** — Without per-feature PDCA files, there's no traceable record of hypotheses vs outcomes. The PM says "PDCA" but doesn't enforce the artifact structure.
- **What's missing:** PDCA file templates (plan.md, do.md, check.md, act.md) with the quantitative metrics tables and lifecycle rules.

---

## 2. Session Context Save/Restore (Serena MCP Memory)

### SuperClaude sc:pm
- Uses **Serena MCP `write_memory()` / `read_memory()` / `list_memories()`** for cross-session persistence
- Structured memory key schema: `session/`, `plan/`, `execution/`, `evaluation/`, `learning/`, `project/`
- Session Start: reads `pm_context`, `current_plan`, `last_session`, `next_actions`
- Session End: writes `last_session`, `next_actions`, `pm_context`
- During work: `write_memory("checkpoint", progress)` every 30 minutes
- Memory is **semantic** (namespaced like Kubernetes) not file-based

### Forge PM
- Uses `/sc:load` and `/sc:save` (delegates to SuperClaude commands)
- Session start reads: `playbook/strategies.md`, `rules/universal.md`, `docs/ethos.md`, `checkpoints/INDEX.md`, `PROJECT_INDEX.md`
- Session end: `/sc:reflect` -> `/learn` -> `/sc:save`
- Context is **file-based** (checkpoints, playbook files)
- No direct Serena MCP memory calls in PM orchestrator itself

### Verdict: **Forge PARTIALLY has this, but different approach**
- **Important: MEDIUM** — Forge uses file-based persistence (checkpoints + /sc:save) which is more portable but less granular. Serena MCP gives semantic key-value storage that's faster to query. Forge already lists `serena` in its MCP servers but doesn't use it in the PM prompt.
- **What's missing:** Structured memory key schema, direct `write_memory`/`read_memory` calls in PM orchestrator, 30-minute checkpoint interval enforcement.

---

## 3. Testing (sc:test)

### SuperClaude sc:test
- Auto-detect test framework and configuration
- Flags: `--type unit|integration|e2e|all`, `--coverage`, `--watch`, `--fix`
- **Playwright MCP auto-activated** for `--type e2e` (browser testing, cross-browser, visual validation)
- Watch mode with auto-fix for simple failures
- Intelligent failure analysis with actionable recommendations
- QA Specialist persona activation
- Will NOT generate test cases — only runs existing tests

### Forge PM
- Testing is part of Phase 3 Step 3 (TDD) and Phase 4 (validate)
- References `/sc:test --coverage` directly (delegates to SuperClaude)
- Has more elaborate TDD enforcement (test first -> fail -> code -> pass -> all tests)
- Has traceability enforcement (every test needs [REQ-xxx])
- Has `@quality-engineer` and `@playwright-critic` agents
- Does NOT have its own test runner command — relies on sc:test

### Verdict: **Forge DELEGATES to sc:test — this is correct**
- **Important: LOW** — Forge correctly uses sc:test as a tool. The value-add is in the TDD enforcement and traceability, which Forge does better.
- **What's missing:** Nothing critical. Forge could add `--watch` mode awareness in its development workflow.

---

## 4. Implementation Delegation (sc:implement)

### SuperClaude sc:implement
- Persona-based: architect, frontend, backend, security, qa-specialist
- MCP integration: Context7 (docs), Magic (UI components), Sequential (planning), Playwright (validation)
- Flags: `--type component|api|service|feature`, `--framework react|vue|express`, `--safe`, `--with-tests`
- Completion criteria: code compiles, basic functionality works, ready for /sc:test
- Post-implementation: /sc:test -> /sc:git
- **Lightweight** — no TDD enforcement, no traceability, no judge review

### Forge PM
- 9-step Forge Cell: context load -> research -> TDD -> quality -> sync check -> judge -> commit
- Task design doc MANDATORY before any code
- Context7 fetched by @context-loader-agent (separate step)
- Per-agent judge rates 1-5, reject <4
- Sync check with [REQ-xxx] traceability
- Max 3 self-fix iterations with error classification
- Much more ceremony but much more rigor

### Verdict: **Forge is STRONGER here**
- **Important: N/A** — Forge's implementation flow is more rigorous than sc:implement. This is an area where Forge adds value ON TOP of SuperClaude.
- **What Forge does better:** TDD enforcement, task design docs, per-agent judges, traceability, self-fix loops.

---

## 5. Self-Correction and Error Investigation

### SuperClaude sc:pm
- "Root Cause First" protocol with 6 steps:
  1. Error -> STOP
  2. Root Cause Investigation (context7, WebFetch, Grep, Read) — MANDATORY
  3. Hypothesis Formation with evidence
  4. Solution Design — MUST BE DIFFERENT from failed approach
  5. Execute new approach
  6. Learning Capture (write_memory or docs/pdca)
- Anti-patterns explicitly listed (retry without investigation, dismiss warnings)
- Warning/Error Investigation Culture — zero tolerance for dismissal
- Categorize impact: Critical/Important/Informational
- Document decision: why fixed or why safe to ignore (with evidence)

### Forge PM
- Self-Correcting Execution section: error -> STOP -> "Why?" -> /investigate -> root cause -> different approach -> /learn
- Max 2 failed corrections -> STOP and ask user
- Tool Failure Handling: context7 unavailable -> web search -> training knowledge
- Chaos Resilience: no SPEC.md -> STOP, empty agent output -> retry once, multiple failures -> STOP
- @root-cause-analyst agent for investigation
- /investigate command for structured analysis

### Verdict: **ROUGHLY EQUIVALENT — different strengths**
- **Important: LOW** — Both systems have strong self-correction. SuperClaude has better-structured error documentation (hypothesis files, PDCA integration). Forge has better escalation (dedicated @root-cause-analyst agent, /investigate command, chaos resilience).
- **What Forge is missing:** Structured hypothesis files (`docs/pdca/[feature]/hypothesis-error-fix.md`), explicit impact categorization (Critical/Important/Informational), the "investigation culture" framing that encourages curiosity about every warning.

---

## 6. The Triangle (spec <-> test <-> code)

### SuperClaude
- **No explicit triangle mechanism.** sc:pm mentions "self-improvement" and "documentation" but does NOT have:
  - [REQ-xxx] tags
  - Traceability checking
  - Sync scripts
  - Spec-to-test-to-code linking
- sc:workflow generates a workflow plan from a PRD but doesn't track requirements through to tests
- sc:test runs tests but doesn't verify they map to requirements

### Forge PM
- **Explicit triangle enforcement:**
  - [REQ-xxx] tags on every requirement in SPEC.md
  - Every test MUST have [REQ-xxx] in docstring
  - Every model/function MUST have [REQ-xxx] in comment
  - `scripts/traceability.sh` — automated sync checker
  - `scripts/sync-report.sh` — comprehensive alignment report
  - Step 5 of Forge Cell: SYNC CHECK (bidirectional) — 100% coverage, 0 orphans, 0 drift
  - After /specify: verify tags exist
  - After /design-doc: verify Section 2 links to tags
  - After /plan-tasks: verify each issue links to tags
  - BLOCK if any gaps

### Verdict: **Forge is MUCH STRONGER here — this is Forge's killer feature**
- **Important: N/A** — SuperClaude has NO equivalent. This is the single biggest differentiator.
- **What SuperClaude is missing:** The entire traceability system. This is arguably the most valuable part of Forge.

---

## 7. What Makes sc:pm "Feel Better"

### Things SuperClaude sc:pm does that feel smoother:

| Feature | SuperClaude | Forge | Gap? |
|---------|-------------|-------|------|
| **Zero-token MCP loading** | Dynamic load/unload per phase (gateway pattern) | Lists MCP servers in header but no dynamic loading protocol | YES — Forge should have phase-based tool loading |
| **Strategy selection** | `--strategy brainstorm\|direct\|wave` — user picks approach | Always follows the full SDLC flow | YES — Forge lacks lightweight modes for small tasks |
| **Memory key schema** | Namespaced semantic keys (`session/context`, `plan/auth/hypothesis`) | File-based checkpoints | PARTIAL — different approach, both work |
| **MCP tool diversity** | context7, magic (UI gen), morphllm (bulk transform), serena (memory), tavily (search), chrome-devtools | context7, playwright, serena, sequential | YES — Forge lists fewer MCP integrations |
| **Persona activation** | Built into command metadata (`personas: [architect, frontend, backend]`) | Agent files in `agents/universal/` and `agents/stacks/` | EQUIVALENT — different mechanism, same result |
| **Brainstorming mode** | Socratic questioning for vague requests | /discover command does similar | EQUIVALENT |
| **Monthly maintenance** | Explicit "remove outdated patterns, merge duplicates" cycle | /prune + /evolve commands | FORGE BETTER — automated with scoring |
| **PDCA docs structure** | Templated files per feature | Referenced but not templated | YES — Forge should add PDCA templates |

---

## 8. Summary: What Forge Should Add

### HIGH PRIORITY (missing and important)
1. **PDCA artifact templates** — `plan.md`, `do.md`, `check.md`, `act.md` with quantitative metrics tables. Currently Forge says "PDCA" but doesn't enforce the file structure.
2. **Phase-based MCP tool loading/unloading** — Dynamic gateway pattern so tools aren't all loaded at once. Reduces token overhead.
3. **Lightweight execution modes** — `--strategy direct` for simple tasks that don't need full 9-step Forge Cell. Currently everything goes through the full ceremony.

### MEDIUM PRIORITY (nice to have)
4. **Structured memory key schema** — If using Serena MCP, adopt the namespaced key pattern (`session/`, `plan/`, `learning/`). Currently Forge uses file-based persistence.
5. **Warning investigation culture framing** — Explicit "zero tolerance for dismissal" with impact categorization. Forge has the mechanics but not the explicit protocol.
6. **Hypothesis files for errors** — `docs/pdca/[feature]/hypothesis-error-fix.md` with cause/evidence/solution format.

### LOW PRIORITY (Forge already handles differently)
7. **Watch mode awareness** — sc:test has `--watch`, Forge could reference this in dev workflow.
8. **MCP tool diversity** — Magic MCP (UI generation), chrome-devtools, tavily. These are stack-specific.

### Things Forge Does BETTER Than SuperClaude
- **Traceability triangle** ([REQ-xxx] tags, sync scripts, bidirectional checking) — SuperClaude has nothing equivalent
- **TDD enforcement** (test first -> fail -> code -> pass) — sc:implement has no TDD
- **Per-agent judges** (rate 1-5, reject <4) — SuperClaude trusts agent output
- **Quality gates** (/gate with CodeRabbit, >90% audit patterns) — SuperClaude has quality gates but less rigorous
- **Self-improving playbook** (helpful/harmful counters, /prune, /evolve) — SuperClaude has docs/patterns but no scoring
- **Constitution governance** (10 articles) — SuperClaude has no equivalent
- **Agent factory** (create new agents on demand) — SuperClaude has fixed personas
- **Multi-flow routing** (/forge detects: new project vs bug vs feature vs improvement vs question) — sc:pm tries to be one-size-fits-all
- **28+ specialist agents** vs SuperClaude's 5-7 personas
