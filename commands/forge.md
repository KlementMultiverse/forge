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

#### Phase B -- Full SDLC (runs automatically after Phase A)

Execute the full SDLC pipeline. Every step is logged to timeline.

**Phase 0: Genesis (remaining steps)**
1. Run `/discover` with discovery report (formalize research)
   - Log to timeline
2. Run `/requirements` on discovery report
   - Log to timeline
3. Run `/feasibility` on requirements
   - ASK USER: "Recommended: [stack]. Use this or pick your own?"
   - Skip if already answered in Phase A
   - Log to timeline
4. Run `/generate-spec` synthesizing all outputs
   - Log to timeline
5. Run `/challenge` on SPEC.md
   - PROCEED -> continue | REFINE -> update + re-challenge | RETHINK -> STOP ask user
   - Log to timeline
6. Run `/bootstrap` to finalize scaffold
   - Log to timeline
7. Run @code-archaeologist baseline assessment
8. Run `/sc:index-repo`
9. Run `/sc:load`
10. **GATE:** `/gate phase-0`
    - Log to timeline

**Phase 1: Specify**
11. Run `/specify` on SPEC.md
    - Log to timeline
12. Run `/checkpoint`
13. **GATE:** `/gate stage-1`
    - Log to timeline

**Phase 2: Architect**
14. Run `/plan-review` on proposal
15. Run @api-architect for API contracts
    - Log to timeline
16. Run `/design-doc` on proposal + contracts
    - Log to timeline
17. Run `/plan-tasks` on design doc
    - Log to timeline
18. Run `/sc:estimate` per phase
19. Run `/sc:workflow` to validate plan
20. Run `/checkpoint` for each output
21. **GATE:** `/gate stage-2`
    - Log to timeline

**Phase 3: Implement (per issue, Forge Cell)**
22. For each GitHub Issue in dependency order:
    - Step 0: Task design doc (MANDATORY before code)
    - Step 1: @context-loader-agent fetches library docs
    - Step 2: Domain agent RESEARCH
    - Step 3: TDD (test first -> fail -> code -> pass -> all tests)
    - Step 4: Quality (black + ruff + full test suite)
    - Step 5: Sync check (spec<->test<->code)
    - Step 6: Per-agent judge (rate 1-5, accept >=4)
    - Step 7: Commit -> close issue -> /checkpoint -> /learn
    - Log EACH step to timeline
23. After each phase group:
    - Run `/review`
    - If frontend: `/design-audit` + `/critic`
    - **GATE:** `/gate phase-N`
    - Log to timeline

**Phase 4: Validate**
24. Run `/sc:analyze`
25. Run `/audit-patterns full` (must be >90%)
26. Run `/sc:test --coverage`
27. Run traceability check
28. Run `/security-scan`
29. If UI: `/design-audit` + `/critic`
30. **GATE:** `/gate stage-4`
    - Log to timeline

**Phase 5: Review + Learn**
31. Run `/sc:cleanup`
32. Run `/sc:improve`
33. Run `/retro`
34. Run `/sc:reflect`
35. Run `/sc:document`
36. Run @playbook-curator delta-update
37. Run `/prune` + `/evolve`
38. Run `/autoresearch`
39. Run `/sc:save`
40. **GATE:** `/gate stage-5` -> MERGE
    - Log to timeline

**Phase 6: Iterate**
41. Collect feedback -> new issues -> loop to Phase 1 or Phase 3

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
