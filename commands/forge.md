# /forge -- One Command to Build Everything

## Input
$ARGUMENTS -- optional. Can be:
- "Build a task tracker" (new project)
- "Add dark mode" (new feature)
- "Fix login bug" (bug fix)
- Empty (forge detects and asks)

## How It Works

When user types `/forge`, the following happens DETERMINISTICALLY:

### STEP 0: DETECT (hook-enforced, cannot be skipped)

The UserPromptSubmit hook already ran and injected one of:
- [FORGE] NEW_PROJECT
- [FORGE] BUG_FIX
- [FORGE] NEW_FEATURE
- [FORGE] IMPROVEMENT
- [FORGE] UNKNOWN

Read the hook output. Then route to the correct case below.

### STEP 1: READ FORGE.md (if exists)

If FORGE.md exists in the project:
1. Read it
2. Find the first QUEUED item
3. Set it to ACTIVE
4. Route to the correct flow based on `type`:
   - NEW_PROJECT → CASE 1
   - FEATURE → CASE 3
   - BUG → CASE 4
   - IMPROVEMENT → CASE 5
5. If no QUEUED items → ask user what to do

If FORGE.md does NOT exist:
1. Route based on hook detection (current behavior)
2. Create FORGE.md during execution

If hook output is missing or ambiguous, run detection manually:
```
1. CLAUDE.md? NO. Code exists? NO.              → CASE 1 (greenfield — new project)
2. CLAUDE.md? NO. Code exists? YES.              → CASE 7 (brownfield — existing code, no forge)
3. CLAUDE.md? YES (placeholders). Code? NO.      → CASE 1 (template only — same as greenfield)
4. CLAUDE.md? YES (real). Code? NO.              → CASE 2 (has spec, needs implementation)
5. CLAUDE.md? YES. Code? YES. Bug keywords?      → CASE 4 (bug fix)
6. CLAUDE.md? YES. Code? YES. Feature keywords?  → CASE 3 (new feature)
7. CLAUDE.md? YES. Code? YES. Improve keywords?  → CASE 5 (improvement)
8. None of the above                             → CASE 6 (ask user)
```

---

### CASE 1: NEW PROJECT (no CLAUDE.md or placeholder CLAUDE.md)

#### Phase A -- Interactive Discovery

<system-reminder>
You are having a friendly conversation to understand the project.
Do NOT dump all questions at once. Ask ONE thing at a time.
After each answer, RESEARCH what they said before asking the next question.
Example: user says "clinic management" -> you web search "clinic management software features 2025" -> then ask informed follow-up.
This is NOT a questionnaire. It's a discovery conversation.
</system-reminder>

**Flow:**

1. "What are you building?"
   - Listen to the answer
   - Web search the domain (e.g., "task tracker software features 2025")
   - Log to timeline: `/discover started`

2. "Who uses it?"
   - Listen to the answer
   - Research user personas for that domain

3. "What's the main problem it solves?"
   - Listen to the answer
   - Web search for existing solutions and competitors

4. Present what you learned:
   ```
   "I found that [competitors] exist. Your differentiator seems to be [X].
   Here's what I think the core features are:
   - [feature 1]
   - [feature 2]
   - [feature 3]
   Anything I'm missing?"
   ```

5. "Any tech preferences? Or should I recommend?"
   - If recommend: analyze project needs, suggest stack with ONE-LINE rationale per choice
   - If user specifies: confirm and note

6. "What should it NEVER include?"
   - Listen and confirm anti-scope

7. Present the complete understanding:
   ```
   PROJECT: [name]
   USERS: [who]
   PROBLEM: [what]
   STACK: [tech choices]
   CORE FEATURES: [list]
   EXCLUDED: [list]
   ```
   "Does this look right? (yes / change something)"

8. On "yes" -- Generate ALL files:
   - CLAUDE.md (under 100 lines, real rules with code snippets, MUST/NEVER format)
   - SPEC.md (with [REQ-xxx] tags for every requirement)
   - .claude/rules/sdlc-flow.md
   - .claude/rules/agent-routing.md
   - .claude/settings.json (hooks from templates/hooks.json)
   - .gitignore (based on stack)
   - pyproject.toml / package.json (based on stack)
   - Dockerfile
   - docker-compose.yml
   - Project scaffold (config/, apps/ or src/)
   - .env.example
   - docs/forge-timeline.md (from templates/forge-timeline.template.md)

9. Log to timeline:
   ```
   ## [TIMESTAMP] Phase A: Discovery + Scaffold
   **Flow:** NEW_PROJECT
   **Agent:** PM (interactive discovery)
   **Input:** "$ARGUMENTS"
   **Output:** [CLAUDE.md](CLAUDE.md), [SPEC.md](SPEC.md), scaffold
   **Duration:** [time]
   **Status:** DONE
   **REQs:** REQ-001 through REQ-xxx created
   ```

10. Git commit: `init: scaffold project with forge`

11. CONTINUE to Phase B automatically (no stopping)

#### Phase B -- Full SDLC (CHAINED EXECUTION — each step MUST complete before next)

<system-reminder>
CHAINED EXECUTION PROTOCOL:
Each step below MUST be executed using the Skill tool (for commands) or Agent tool (for agents).
After EACH step:
  1. VERIFY the output file exists (use Read or Bash ls)
  2. VERIFY it has real content (not empty, not placeholder)
  3. LOG to docs/forge-trace/{NNN}-{step}/ (input.md + output.md + meta.md)
  4. LOG to docs/forge-timeline.md
  5. ONLY THEN proceed to next step

If verification FAILS → retry the step (max 2) → still fails → STOP and report.
If a step produces no output file → the step did NOT run → DO NOT PROCEED.

You are EXECUTING these commands, not describing them.
Use the Skill tool: `skill: "discover"` or `skill: "requirements"` etc.
Use the Agent tool for specialist agents: `subagent_type: "security-engineer"` etc.
</system-reminder>

**Phase 0: Genesis**

STEP 1 — /discover
  Execute: `skill: "discover", args: "$ARGUMENTS"`
  Verify: `ls docs/discovery-report.md` → file exists, >500 bytes
  Trace: save to docs/forge-trace/001-discover/
  If missing → step failed → retry

STEP 2 — /requirements
  Execute: `skill: "requirements", args: "docs/discovery-report.md"`
  Verify: `grep -c "REQ-" docs/requirements.md` → at least 15 REQs
  Trace: save to docs/forge-trace/002-requirements/
  If <15 REQs → step incomplete → retry with "need more requirements"

STEP 3 — /feasibility
  Execute: `skill: "feasibility", args: "docs/requirements.md"`
  Verify: `ls docs/feasibility.md` → file exists
  ASK USER: "Recommended: [stack]. Confirm? (yes/change)"
  Trace: save to docs/forge-trace/003-feasibility/

STEP 4 — /generate-spec
  Execute: `skill: "generate-spec"`
  Verify: `grep -c "REQ-" SPEC.md` → at least 15 REQs in SPEC
  Verify: SPEC.md has ## Models, ## API Endpoints, ## Tech Stack sections
  Trace: save to docs/forge-trace/004-generate-spec/
  If SPEC incomplete → retry

STEP 5 — /challenge
  Execute: `skill: "challenge", args: "SPEC.md"`
  Verify: output contains PROCEED or REFINE or RETHINK
  If RETHINK → STOP, ask user
  If REFINE → update SPEC → re-run /challenge (max 2)
  Trace: save to docs/forge-trace/005-challenge/

STEP 6 — /bootstrap
  Execute: `skill: "bootstrap"`
  Verify: `ls manage.py pyproject.toml Dockerfile docker-compose.yml config/settings.py` → all exist
  Trace: save to docs/forge-trace/006-bootstrap/
  If any missing → step failed → retry

STEP 7 — /checkpoint
  Execute: `skill: "checkpoint", args: "phase-0 | Genesis complete"`
  Trace: save to docs/forge-trace/007-checkpoint-p0/

STEP 8 — /gate phase-0
  Execute: `skill: "gate", args: "phase-0"`
  Verify: gate output says PASS
  If BLOCKED → fix issues → re-run /gate
  Trace: save to docs/forge-trace/008-gate-p0/

**Phase 1: Specify**

STEP 9 — /specify
  Execute: `skill: "specify", args: "SPEC.md"`
  Verify: `ls docs/proposals/01-*.md` → proposal exists
  Verify: proposal has ## Acceptance Criteria with Given/When/Then
  Trace: save to docs/forge-trace/009-specify/

STEP 10 — /checkpoint
  Execute: `skill: "checkpoint", args: "specify | proposal created"`
  Trace: save to docs/forge-trace/010-checkpoint-s1/

STEP 11 — /gate stage-1
  Execute: `skill: "gate", args: "stage-1"`
  Verify: gate PASS
  Trace: save to docs/forge-trace/011-gate-s1/

**Phase 2: Architect**

STEP 12 — /plan-review
  Execute: `skill: "plan-review", args: "docs/proposals/01-*.md"`
  Verify: review output exists with feedback
  Trace: save to docs/forge-trace/012-plan-review/

STEP 13 — @api-architect (API contracts)
  Execute: spawn Agent with subagent_type="general-purpose"
    prompt: "You are @api-architect. Read docs/proposals/01-*.md and SPEC.md. Design API contracts for every endpoint: method, path, request JSON, response JSON, error codes, Pydantic schemas."
  Verify: output has endpoint tables with JSON shapes
  Trace: save to docs/forge-trace/013-api-contracts/

STEP 14 — /design-doc
  Execute: `skill: "design-doc", args: "docs/proposals/01-*.md"`
  Verify: `ls docs/design-doc.md` → exists, >5000 bytes
  Verify: has all 10 sections (## 1. through ## 10.)
  Verify: has "Will implement" decisions (at least 8)
  Verify: has Pydantic Schema classes
  Verify: has test scenarios (at least 15)
  Trace: save to docs/forge-trace/012-design-doc/
  If any verify fails → retry with specific feedback

STEP 15 — /plan-tasks
  Execute: `skill: "plan-tasks", args: "docs/design-doc.md"`
  Verify: `ls docs/issues/*.md | wc -l` → at least 10 issue files
  Verify: each issue has [REQ-xxx] reference
  Trace: save to docs/forge-trace/015-plan-tasks/

STEP 16 — /sc:estimate
  Execute: `skill: "sc:estimate", args: "docs/design-doc.md"`
  Verify: effort estimates per phase exist
  Trace: save to docs/forge-trace/016-estimate/

STEP 17 — /sc:workflow
  Execute: `skill: "sc:workflow", args: "docs/design-doc.md"`
  Verify: dependency ordering validated
  Trace: save to docs/forge-trace/017-workflow/

STEP 18 — /checkpoint
  Execute: `skill: "checkpoint", args: "architect | design doc + tasks created"`
  Trace: save to docs/forge-trace/018-checkpoint-s2/

STEP 19 — /gate stage-2
  Execute: `skill: "gate", args: "stage-2"`
  Verify: gate PASS
  Trace: save to docs/forge-trace/019-gate-s2/

**Phase 3: IMPLEMENT (per issue — strict agent separation)**

<system-reminder>
STRICT AGENT SEPARATION — MANDATORY:
- SPEC agent and CODE agent are DIFFERENT agents
- TEST agent and CODE agent are DIFFERENT agents
- TEST agent reads SPEC (not code) to write tests
- CODE agent reads SPEC + design doc + test expectations to write code
- REVIEW agent judges every output independently
- NO agent does more than ONE job per step

This prevents:
- Tests that are designed to pass (written after code)
- Specs that are reverse-engineered from implementation
- Code that ignores the spec because same agent wrote both
</system-reminder>

For EACH issue in dependency order, execute this chain.
Use N = issue number (e.g., issue 1 = steps 100-109, issue 2 = 110-119).

STEP N0 — TASK DESIGN DOC
  Execute: spawn Agent with subagent_type="backend-architect"
    prompt: "Read SPEC.md [REQ-xxx] for issue #{N} and design-doc Section 4. Write a task design doc: files to change, model fields, API contract, error format. Use templates/task-design-doc.template.md format."
  Verify: output contains "## Files to Change" and "## API Contract"
  Trace: docs/forge-trace/{N}0-design/

STEP N1 — CONTEXT LOAD
  Execute: spawn Agent with subagent_type="context-loader-agent"
    prompt: "Fetch library docs for this issue's stack via context7 MCP: {libraries from agent-routing.md}"
  Verify: agent reports docs fetched (not "unavailable")
  Trace: docs/forge-trace/{N}1-context/

STEP N2 — WRITE SPEC ENTRY
  Execute: spawn Agent with subagent_type="requirements-analyst"
    prompt: "Read task design doc from step N0. Add [REQ-xxx] to SPEC.md with Given/When/Then acceptance criteria."
  Verify: `grep -c "REQ-" SPEC.md` increased by at least 1
  Trace: docs/forge-trace/{N}2-spec/

STEP N3 — WRITE TESTS (from SPEC, NOT from code)
  Execute: spawn Agent with subagent_type="quality-engineer"
    prompt: "Read SPEC.md [REQ-xxx] for issue #{N} and the task design doc. Write tests in apps/{app}/tests.py. Do NOT read any implementation code. Every test has [REQ-xxx] in docstring. Minimum 5 tests."
  Verify: `grep -c "def test_" apps/{app}/tests.py` increased by at least 5
  Execute: `uv run python manage.py test apps.{app}` via Bash
  Verify: tests FAIL (code doesn't exist yet — if they PASS, something is wrong)
  Trace: docs/forge-trace/{N}3-tests/

STEP N4 — WRITE CODE
  Execute: spawn Agent with subagent_type="{domain-agent}" (from agent-routing.md)
    prompt: "Read SPEC.md [REQ-xxx], task design doc, and test file. Write models/api/services/schemas to make tests pass. Every function has [REQ-xxx] comment. Use context7 docs from step N1."
  Verify: `uv run python manage.py test apps.{app}` → ALL PASS via Bash
  Verify: `uv run python manage.py test` → ALL tests pass (no regression) via Bash
  If FAIL: agent retries (max 3)
  If still FAIL: spawn Agent with subagent_type="root-cause-analyst"
  Trace: docs/forge-trace/{N}4-code/

STEP N5 — LINT (hook-enforced, automatic)
  Happens via PostToolUse hook on every Write/Edit

STEP N6 — SYNC CHECK
  Execute: `bash scripts/traceability.sh` via Bash
  Verify: output shows 100% for this issue's [REQ-xxx] tags
  If gap found: STOP — fix before proceeding
  Trace: docs/forge-trace/{N}6-sync/

STEP N7 — SECURITY SCAN
  Execute: spawn Agent with subagent_type="security-engineer"
    prompt: "Review the code changes for issue #{N}. Check: input validation, auth, no hardcoded secrets, error exposure, tenant isolation."
  Verify: no CRITICAL or HIGH findings
  If found: fix before commit
  Trace: docs/forge-trace/{N}7-security/

STEP N8 — REVIEW
  Execute: spawn Agent with subagent_type="self-review"
    prompt: "Rate the output of issue #{N} on scale 1-5. Check: tests cover acceptance criteria, code matches spec, no orphan code, handoff format complete."
  Verify: rating >= 4
  If < 4: go back to STEP N4 (max 3 iterations)
  Trace: docs/forge-trace/{N}8-review/

STEP N9 — COMMIT + LEARN
  Execute: `git add apps/{app}/ && git commit -m "feat({app}): {description} [REQ-xxx]"` via Bash
  Execute: update FORGE.md — move item from Active to Done
  Execute: `skill: "checkpoint", args: "{agent} | issue #{N} complete"`
  Execute: `skill: "learn", args: "{any non-obvious pattern discovered}"` (if applicable)
  Trace: docs/forge-trace/{N}9-commit/

23. After each phase group:
    - /review (inline code review of ALL changes in this phase)
    - /gate (PR + CodeRabbit or manual checklist)
    - Log to timeline

**Phase 4: Validate**

STEP 40 — /sc:analyze
  Execute: `skill: "sc:analyze"`
  Verify: analysis report produced
  Trace: save to docs/forge-trace/040-analyze/

STEP 41 — /audit-patterns full
  Execute: `skill: "audit-patterns", args: "full"`
  Verify: pass rate > 90% — if not, fix top 5 failures then re-run
  Trace: save to docs/forge-trace/041-audit/

STEP 42 — /sc:test --coverage
  Execute: `skill: "sc:test", args: "--coverage"`
  Verify: tests pass, coverage report generated
  Trace: save to docs/forge-trace/042-coverage/

STEP 43 — traceability check
  Execute: `bash scripts/traceability.sh` via Bash
  Verify: 100% REQ coverage, 0 orphans, 0 drift
  If gaps → fix before proceeding
  Trace: save to docs/forge-trace/043-traceability/

STEP 44 — /security-scan
  Execute: `skill: "security-scan"`
  Verify: no CRITICAL or HIGH findings
  If found → fix → re-scan
  Trace: save to docs/forge-trace/044-security/

STEP 45 — /design-audit + /critic (if project has UI)
  Execute: `skill: "design-audit"` (if templates/ exist)
  Execute: `skill: "critic"` (if Playwright available)
  Trace: save to docs/forge-trace/045-design/

STEP 46 — /gate stage-4
  Execute: `skill: "gate", args: "stage-4"`
  Verify: gate PASS
  Trace: save to docs/forge-trace/046-gate-s4/

**Phase 5: Review + Learn**

STEP 47 — /sc:cleanup
  Execute: `skill: "sc:cleanup"`
  Verify: dead code removed, no regressions (run tests)
  Trace: save to docs/forge-trace/047-cleanup/

STEP 48 — /sc:improve
  Execute: `skill: "sc:improve"`
  Verify: improvements applied, tests still pass
  Trace: save to docs/forge-trace/048-improve/

STEP 49 — /retro
  Execute: `skill: "retro"`
  Verify: `ls docs/retrospectives/*.md` → retro file exists
  Verify: CLAUDE.md Lessons Learned section updated
  Trace: save to docs/forge-trace/049-retro/

STEP 50 — /sc:reflect
  Execute: `skill: "sc:reflect"`
  Verify: task completion validated
  Trace: save to docs/forge-trace/050-reflect/

STEP 51 — /sc:document
  Execute: `skill: "sc:document"`
  Verify: documentation generated/updated
  Trace: save to docs/forge-trace/051-document/

STEP 52 — @playbook-curator
  Execute: spawn Agent with subagent_type="general-purpose"
    prompt: "You are @playbook-curator. Read docs/retrospectives/*.md. Delta-update .forge/playbook/strategies.md with new entries. Check duplicates. Increment counters."
  Verify: playbook file updated
  Trace: save to docs/forge-trace/052-playbook/

STEP 53 — /prune + /evolve
  Execute: `skill: "prune"`
  Execute: `skill: "evolve"`
  Trace: save to docs/forge-trace/053-prune-evolve/

STEP 54 — /autoresearch (improve agent prompts from this build)
  Execute: `skill: "autoresearch"`
  Trace: save to docs/forge-trace/054-autoresearch/

STEP 55 — /sc:save
  Execute: `skill: "sc:save"`
  Trace: save to docs/forge-trace/055-save/

STEP 56 — /gate stage-5 → MERGE
  Execute: `skill: "gate", args: "stage-5"`
  Verify: gate PASS → merge PR
  Trace: save to docs/forge-trace/056-gate-final/

**Phase 6: Iterate**

STEP 57 — Check FORGE.md for queued items
  Read FORGE.md → any QUEUED items?
  YES → loop back to Phase 3 (or Phase 1 if new feature)
  NO → project complete, report summary

---

### CASE 2: EXISTING PROJECT, NO CODE (has CLAUDE.md but no apps/)

1. Read CLAUDE.md
2. Check content quality:
   - Has `{{` placeholders or `[PROJECT NAME]` -> run Phase A discovery conversation (CASE 1)
   - Has real content -> continue
3. Read SPEC.md
   - Exists with [REQ-xxx] tags -> CONTINUE to Phase B (skip Phase A)
   - Missing or empty -> run `/generate-spec` first, then Phase B
4. Log to timeline:
   ```
   ## [TIMESTAMP] CASE 2: Existing project, resuming SDLC
   **Flow:** NEW_PROJECT (resumed)
   **Agent:** PM
   **Input:** existing CLAUDE.md + SPEC.md
   **Output:** resuming from [phase]
   **Status:** IN_PROGRESS
   ```
5. Execute Phase B from wherever it left off
   - Check docs/forge-timeline.md for last completed step
   - Resume from the next step

---

### CASE 3: EXISTING PROJECT WITH CODE -- New Feature

1. Read CLAUDE.md -> understand project rules, stack, architecture
2. Read SPEC.md -> understand existing [REQ-xxx] tags and requirements
3. Ask: "What feature do you want to add?" (if not in $ARGUMENTS)
   - Listen to the answer
   - Web search the feature domain for best practices
4. Present understanding:
   ```
   "I'll add [feature] which needs:
   - Models: [list]
   - Endpoints: [list]
   - Tests: [list]
   It connects to existing [X]. Sound right?"
   ```
5. On confirm:
   - Run `/specify` -> new [REQ-xxx] tags appended to SPEC.md
   - Run `/design-doc`
   - Run `/plan-tasks` -> GitHub Issues
   - Implement per issue (Forge Cell, 7 steps each)
   - Run `/gate` after each phase
   - Run `/retro` when feature complete
6. Log EVERY step to timeline:
   ```
   ## [TIMESTAMP] New Feature: [name]
   **Flow:** NEW_FEATURE
   **Agent:** [agent used]
   **Input:** [what was given]
   **Output:** [file] -> [link]
   **Duration:** [time]
   **Status:** [DONE|BLOCKED|NEEDS_REVIEW]
   **REQs:** [REQ-xxx addressed]
   ```

---

### CASE 4: EXISTING PROJECT WITH CODE -- Bug Fix

1. Read CLAUDE.md -> understand project rules, stack
2. Ask: "Describe the bug" (if not in $ARGUMENTS)
3. Ask: "Where does it happen? (file, endpoint, page)" (if not obvious)
4. Run `/investigate` -> @root-cause-analyst traces the code path:
   - Read relevant files
   - Grep for related patterns
   - Trace execution flow
   - Identify ROOT CAUSE (not just symptom)
5. Present root cause:
   ```
   "The issue is [X] in [file:line] because [Y].
   I'll fix it by [Z]. Sound right?"
   ```
6. On confirm:
   - Write task design doc
   - TDD fix: test reproduces bug (FAIL) -> fix code -> test PASSES -> ALL tests pass
   - Quality: black + ruff
   - Sync check: add/update [REQ-xxx] in SPEC.md if requirement was missing
   - Commit: `fix(domain): description [REQ-xxx]`
   - Run `/learn` if bug reveals non-obvious pattern
7. Log to timeline:
   ```
   ## [TIMESTAMP] Bug Fix: [description]
   **Flow:** BUG_FIX
   **Agent:** @root-cause-analyst -> [domain agent]
   **Input:** "[bug description]"
   **Output:** [files modified] -> [links]
   **Duration:** [time]
   **Status:** DONE
   **REQs:** [REQ-xxx]
   ```

---

### CASE 5: EXISTING PROJECT WITH CODE -- Improvement

1. Read CLAUDE.md -> understand project context
2. Ask: "What do you want to improve?" (if not in $ARGUMENTS)
3. Spawn appropriate agent:
   - Refactor -> @refactoring-expert analyzes target code
   - Performance -> @performance-engineer profiles and measures
   - Cleanup -> @code-archaeologist finds dead code, tech debt
4. Present analysis and plan:
   ```
   "Current state: [analysis]
   Proposed changes: [list]
   Expected improvement: [metrics]
   Risk: [assessment]
   Sound right?"
   ```
5. On confirm:
   - Run ALL existing tests (establish baseline)
   - Make changes (one at a time for refactors)
   - Run ALL tests after each change (no regressions)
   - For performance: measure before AND after with exact numbers
   - Commit: `refactor|perf|chore(domain): description`
   - Run `/learn` if improvement reveals pattern
6. Log to timeline:
   ```
   ## [TIMESTAMP] Improvement: [description]
   **Flow:** IMPROVEMENT
   **Agent:** [@agent-name]
   **Input:** "[improvement request]"
   **Output:** [files modified] -> [links]
   **Duration:** [time]
   **Status:** DONE
   **REQs:** [REQ-xxx if applicable]
   ```

---

### CASE 7: BROWNFIELD — Existing code but no CLAUDE.md

<system-reminder>
This project has code but was NOT built with Forge. Do NOT create requirements from scratch.
The requirements ALREADY EXIST in the code. You must DISCOVER them first.
NEVER ask "what are you building?" — the code TELLS you what was built.
</system-reminder>

1. **Scan the codebase** (automated, no questions):
   ```bash
   # Detect language and framework
   ls *.py manage.py pyproject.toml 2>/dev/null  # Python/Django
   ls package.json tsconfig.json 2>/dev/null       # Node/TypeScript
   ls Cargo.toml 2>/dev/null                        # Rust
   ls go.mod 2>/dev/null                            # Go

   # Count what exists
   find . -name "*.py" -not -path "*/.venv/*" | wc -l
   find . -name "test*" -name "*.py" | wc -l
   ```

2. **Index the project** — spawn @repo-index:
   - Directory structure, entry points, key files
   - Models/schemas found, API endpoints found, tests found
   - Present to user: "I found: [N] files, [framework], [N] models, [N] endpoints, [N] tests"

3. **Reverse-engineer requirements** — spawn @requirements-analyst in reverse mode:
   - Read models → extract data requirements [REQ-xxx]
   - Read API endpoints → extract functional requirements [REQ-xxx]
   - Read tests → extract verified behaviors [REQ-xxx]
   - Read config → extract infrastructure requirements

4. **Generate CLAUDE.md** from actual code:
   - Tech stack from pyproject.toml/package.json (not guessing)
   - Architecture rules from existing patterns (middleware order, test base classes, etc.)
   - "What NOT to build" from what's deliberately absent

5. **Generate SPEC.md** from reverse-engineered requirements:
   - Every [REQ-xxx] traced to existing code file
   - Mark as [IMPLEMENTED] — these already have code + tests

6. **Present to user**:
   ```
   I've analyzed your project:
   - Tech: [stack]
   - Models: [count] ([list])
   - Endpoints: [count]
   - Tests: [count]
   - Requirements: [count] reverse-engineered

   Generated:
   - CLAUDE.md ([N] lines, [N] rules from your patterns)
   - SPEC.md ([N] [REQ-xxx] tags from existing code)
   - .claude/rules/ (SDLC flow + agent routing)
   - .claude/settings.json (hooks)
   - docs/forge-timeline.md

   What would you like to do next?
   (a) Add a new feature
   (b) Fix a bug
   (c) Improve something
   ```
7. Route to CASE 3/4/5 based on answer
8. Log to timeline

---

### CASE 6: Can't determine

1. Ask:
   ```
   "I see an existing project. What would you like to do?
   (a) Add a new feature
   (b) Fix a bug
   (c) Improve/refactor something
   (d) Ask a question about the code"
   ```
2. Route to appropriate case:
   - (a) -> CASE 3
   - (b) -> CASE 4
   - (c) -> CASE 5
   - (d) -> Read CLAUDE.md, read relevant code, explain using real project code (no code changes)
3. Log to timeline

---

## TIMELINE TRACKING (MANDATORY -- every step logged)

<system-reminder>
After EVERY significant action, append to docs/forge-timeline.md.
This file is the audit trail. It MUST exist. It MUST be accurate.
If it doesn't exist, CREATE it before the first log entry.
Format is strict -- follows the template below.
</system-reminder>

Every entry in docs/forge-timeline.md:

```markdown
## [TIMESTAMP] [STEP-NAME]

**Flow:** [NEW_PROJECT | BUG_FIX | NEW_FEATURE | IMPROVEMENT]
**Agent:** [@agent-name or /command-name]
**Input:** [what was given to the agent]
**Output:** [file created/modified] -> [link to file](relative-path)
**Duration:** [time taken]
**Status:** [DONE | BLOCKED | NEEDS_REVIEW | IN_PROGRESS]
**REQs:** [which REQ-xxx tags were addressed]

---
```

### Timeline Rules
1. Every entry MUST have all 7 fields (Flow, Agent, Input, Output, Duration, Status, REQs)
2. Output MUST include relative links to artifacts: `[filename](relative-path)`
3. Newest entries go at the TOP (below the header)
4. Status transitions: IN_PROGRESS -> DONE | BLOCKED | NEEDS_REVIEW
5. BLOCKED entries MUST include reason in Output field
6. Every /gate result logged with pass/fail and CodeRabbit suggestion count
7. Every agent handoff logged (who handed off to whom, what was passed)

### Timeline Validation (PostToolUse hook enforces)
When writing to docs/forge-timeline.md, the hook validates:
- Entry has `## ` header with timestamp
- Entry has all 7 `**Field:**` lines
- Status is one of: DONE, BLOCKED, NEEDS_REVIEW, IN_PROGRESS
- If validation fails, the hook warns and the entry must be corrected

---

## EXECUTION TRACE (MANDATORY — full input/output saved per step)

<system-reminder>
After EVERY agent execution or command run, save a full trace entry.
This is NOT the same as the timeline — the timeline is a summary.
The trace has the FULL input and output content.
</system-reminder>

### How to save a trace entry

After each step completes:

1. Create folder: `docs/forge-trace/{NNN}-{step-name}/`
   - NNN is zero-padded step number (001, 002, 003...)
   - step-name is the command or agent name (discover, requirements, etc.)

2. Write `input.md`:
   ```markdown
   # Input to {{agent-name}}

   **Source:** {{where this input came from — previous step output, user message, etc.}}

   {{full input content that was given to the agent}}
   ```

3. Write `output.md`:
   ```markdown
   # Output from {{agent-name}}

   **Files created:** {{list of files}}
   **REQs:** {{REQ-xxx tags created or addressed}}

   {{full output content from the agent}}
   ```

4. Write `meta.md`:
   ```markdown
   # Step {{NNN}}: {{step-name}}

   - **Agent:** {{agent-name}}
   - **Timestamp:** {{ISO timestamp}}
   - **Duration:** {{time taken}}
   - **Status:** {{DONE / BLOCKED / NEEDS_REVIEW}}
   - **Flow:** {{CASE1_GREENFIELD / CASE3_FEATURE / CASE4_BUGFIX / etc.}}
   - **Previous step:** [{{prev step}}](../{{prev-folder}}/meta.md)
   - **Next step:** [{{next step}}](../{{next-folder}}/meta.md)
   ```

5. Update `docs/forge-trace/INDEX.md` (append one line):
   ```markdown
   | {{NNN}} | {{step-name}} | {{agent}} | {{status}} | [input]({{NNN}}-{{step}}/input.md) | [output]({{NNN}}-{{step}}/output.md) | {{duration}} |
   ```

### Trace Index file format

The INDEX.md at `docs/forge-trace/INDEX.md`:

```markdown
# Forge Execution Trace — {{PROJECT_NAME}}

Every step of the build process with full input/output.
Click any link to see exactly what happened.

| # | Step | Agent | Status | Input | Output | Duration |
|---|------|-------|--------|-------|--------|----------|
```

---

## COMPLETION

When ALL phases are done, output:

```
Forge complete.
- Project: [name]
- Location: [path]
- Flow: [NEW_PROJECT | NEW_FEATURE | BUG_FIX | IMPROVEMENT]
- Tests: [count] passing
- Coverage: [%]
- Traceability: [%] REQ coverage
- Audit: [%] pattern pass rate
- Timeline: docs/forge-timeline.md ([N] entries)
- Duration: [total time]
```
