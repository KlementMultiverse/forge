# /forge — Master Command

The single entry point for ALL work. Detects context and routes to the correct flow automatically.

## Input
$ARGUMENTS — What the user wants (can be anything: new project, new feature, bug fix, improvement)

## Step 0: DETECT INTENT (MANDATORY — run before anything else)

<system-reminder>
You MUST detect the correct flow BEFORE executing. Read the environment, then route.
NEVER assume new project. NEVER skip detection. The flow you choose determines EVERYTHING.
</system-reminder>

### Detection Logic

```
1. Check: does CLAUDE.md exist in current directory?

   NO  → FLOW A: NEW PROJECT
        The user wants to build something from scratch.
        Execute: Phase 0 Genesis → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5

   YES → Read CLAUDE.md. Check: does code already exist? (ls apps/ src/ or find *.py *.ts)

        NO code exists → FLOW A: NEW PROJECT (has CLAUDE.md from forge init but no code yet)

        YES code exists → Classify the user's request:

        2. Is it a BUG? (keywords: "fix", "broken", "error", "fails", "wrong", "302 instead of 401")
           YES → FLOW B: BUG FIX
                 Execute: /investigate → @root-cause-analyst → fix → test → commit

        3. Is it a NEW FEATURE? (keywords: "add", "build", "create", "implement", "new")
           YES → FLOW C: NEW FEATURE
                 Execute: /specify → /design-doc → /plan-tasks → Forge Cell per issue → /gate

        4. Is it an IMPROVEMENT? (keywords: "improve", "refactor", "optimize", "speed up", "clean up")
           YES → FLOW D: IMPROVEMENT
                 Execute: analyze current state → task design doc → implement → test → commit

        5. Is it a QUESTION? (keywords: "how", "why", "explain", "what is")
           YES → FLOW E: KNOWLEDGE
                 Execute: @learning-guide or @socratic-mentor → explain using actual project code

        6. Can't classify?
           → Ask user: "I see an existing project. Do you want to: (a) add a feature, (b) fix a bug, (c) improve something, (d) something else?"
```

### Flow Summary

| Flow | When | Entry Point | Stages |
|------|------|-------------|--------|
| A: New Project | No CLAUDE.md or no code | /discover → full SDLC | 0→1→2→3→4→5 |
| B: Bug Fix | User describes a bug | /investigate | investigate→fix→test→commit |
| C: New Feature | User wants new functionality | /specify | 1→2→3→4→5 |
| D: Improvement | Refactor, optimize, clean up | analysis→plan→implement | task design doc→implement→test |
| E: Knowledge | User asks a question | @learning-guide | explain→done |

## Prerequisites (check after intent detection)

1. **Git initialized?** `git rev-parse --is-inside-work-tree 2>/dev/null`. If not → `git init`.
2. **GitHub remote?** `git remote get-url origin 2>/dev/null`. If not → offer `gh repo create` or skip.
3. **context7 MCP?** Test with resolve-library-id. If unavailable → web search fallback.

---

## FLOW A: New Project — Full SDLC

## Execution

<system-reminder>
STRICT ENFORCEMENT — READ THIS BEFORE EVERY STEP:

You MUST execute EVERY step below in EXACT order. No skipping. No shortcuts. No "I'll do this later."
After EACH step, verify the output exists and is complete before moving to the next step.

MANDATORY AGENTS PER STEP (you MUST spawn these — not simulate, not summarize):
- Phase 0: @deep-research-agent, @requirements-analyst, @business-panel-experts, @system-architect, @security-engineer
- Phase 1: @requirements-analyst, @spec-panel review, @business-panel-experts validation
- Phase 2: @system-architect, @backend-architect, @security-engineer, @api-architect
- Phase 3: @context-loader-agent (BEFORE every implementation), domain agent, per-agent @reviewer judge
- Phase 4: @pattern-auditor-agent, @security-engineer, @quality-engineer
- Phase 5: @retrospective-miner, @playbook-curator

ENFORCEMENT RULES:
1. NEVER write code without first fetching library docs via @context-loader-agent (context7 MCP)
2. NEVER submit agent output without running /checkpoint on it
3. NEVER proceed to next phase without completing ALL steps in current phase
4. NEVER implement without a task-level design doc (templates/task-design-doc.template.md)
5. NEVER claim "tests pass" without actually running them via Bash tool
6. EVERY test method MUST have [REQ-xxx] in its docstring
7. EVERY model/function MUST have [REQ-xxx] in a comment
8. After EVERY agent output → spawn @reviewer to rate 1-5. If <4 → reiterate same agent (max 3)
9. After EVERY phase → run /gate (PR + review or manual checklist)
10. Target: 100+ tests for MVP, 100% REQ traceability, 0 orphan code

QUALITY GATES (each must pass before next step):
- After /discover: discovery report has real research (not just training knowledge)
- After /requirements: minimum 20 [REQ-xxx] tags with acceptance criteria
- After /feasibility: stack confirmed by user
- After /generate-spec: SPEC.md has models with field types, API endpoints with methods, [REQ-xxx] on every requirement
- After /specify: proposal has Given/When/Then for EVERY user story
- After /design-doc: ALL 10 sections complete, 8+ decisions with trade-offs, 15+ test scenarios, Pydantic schemas defined
- After /plan-tasks: every task has: files to change, [REQ-xxx] link, depends-on, acceptance criteria
- After EACH implementation task: test written FIRST (TDD), test FAILS, code written, test PASSES, ALL tests pass, lint clean
- After ALL implementation: sync check shows 100% traceability (no orphan REQs, no orphan code)

The ONLY times to stop and ask the user:
1. /feasibility → "Recommended stack: [X]. Confirm?"
2. Credentials needed (AWS keys, API keys, etc.)
3. After 3 reflexion failures on a single issue
4. /challenge verdict is RETHINK
Everything else runs autonomously — but EVERY step runs. No shortcuts.
</system-reminder>

---

### Phase 0: Genesis

1. Run `/discover` with the user's sentence
   - Output: docs/discovery-report.md
   - **REVIEW:** PM validates — problem real? users identified? market exists?
   - If review fails → reiterate @deep-research-agent with feedback (max 3)
   - Git: commit

2. Run `/requirements` on the discovery report
   - Output: docs/requirements.md with [REQ-xxx] tags
   - **REVIEW:** @business-panel-experts validates viability + completeness
   - If review fails → reiterate @requirements-analyst with feedback (max 3)
   - Git: commit

3. Run `/feasibility` on the requirements
   - Output: docs/feasibility.md with tech stack + risk matrix
   - **REVIEW:** @system-architect validates stack fits requirements
   - **ASK USER:** "Recommended: [stack]. Use this or pick your own?"
   - Check: agents exist for stack? If not → @agent-factory creates them
   - Git: commit

4. Run `/generate-spec` synthesizing discovery + requirements + feasibility
   - Output: SPEC.md with all [REQ-xxx] tags
   - **REVIEW:** @requirements-analyst verifies ALL requirements captured
   - If any REQ missing → fix SPEC.md → re-review
   - Git: commit

5. Run `/challenge` on the generated SPEC.md
   - 6 forcing questions: demand, status quo, specificity, scope, observation, future-fit
   - **REVIEW:** PM validates challenge verdict
   - Verdict PROCEED → continue
   - Verdict REFINE → update SPEC.md → re-run /challenge
   - Verdict RETHINK → STOP and ask user
   - Git: commit

6. Run `/bootstrap` to scaffold the project
   - Creates: project folder, CLAUDE.md, git init, dependencies, docker
   - **REVIEW:** PM verifies scaffold matches SPEC (correct apps, correct structure)
   - Push to GitHub
   - Git: commit "init: scaffold project"

7. Run @code-archaeologist on the scaffolded project
   - Baseline assessment: architecture, quality metrics, file structure
   - Identifies any scaffold issues before building on top

8. Run `/sc:index-repo` on the new project
   - Generates PROJECT_INDEX.md (94% token savings per session)
   - Every future agent loads the index instead of scanning the full repo

8. Run `/sc:load` to initialize session context
   - Load project state, playbook, rules into session memory

9. **GATE:** `/gate phase-0`
   - Git push → create PR
   - CodeRabbit reviews → fix ALL suggestions → 0 remaining → PASS
   - If CodeRabbit has suggestions → fix → push → wait for re-review → repeat

---

### Phase 1: Specify

8. Run `/specify` on SPEC.md
   - Output: docs/proposals/01-project.md + GitHub Issues
   - **REVIEW:** @spec-panel (multi-expert) validates:
     - All [REQ-xxx] covered in proposal?
     - Acceptance criteria (Given/When/Then) for each requirement?
     - Implementation phases ordered correctly?
     - Risk table complete?
   - If review fails → reiterate with feedback (max 3)

9. Run `/checkpoint` — evaluate proposal quality (PASS/FAIL score)
   - If score <80% → fix issues → re-checkpoint

10. **GATE:** `/gate stage-1`
    - Git push → create PR
    - CodeRabbit reviews → fix ALL suggestions → 0 remaining → PASS

---

### Phase 2: Architect

11. Run `/plan-review` on the proposal
    - Product scope: right thing to build? (@business-panel-experts)
    - Architecture: right approach? (@system-architect + @security-engineer)
    - Verdict: BUILD AS-IS / REDUCE SCOPE / NEEDS CHANGES

12. Run @api-architect to design API contracts
    - Technology-agnostic contracts for EVERY endpoint
    - Exact request/response/error shapes
    - Both backend and frontend agents read SAME contract
    - Output: docs/api-contracts.md

12. Run `/design-doc` on the proposal + API contracts
    - Output: docs/design-doc.md (10 sections, Section 4 references api-contracts.md)
    - **REVIEW:** @spec-panel validates:
      - Every design decision has "Will implement X because" + alternatives?
      - API contracts in Section 4 have exact request/response/error shapes?
      - Testing strategy has 15+ scenarios?
      - Security section covers auth, tenant isolation, data protection?
    - If review fails → reiterate with feedback (max 3)

12. Run `/plan-tasks` on the design doc
    - Output: docs/implementation-plan.md + GitHub Issues
    - **REVIEW:** PM validates:
      - Dependency order correct? (infra → models → APIs → frontend)
      - Each task links to [REQ-xxx]?
      - Parallel markers [P] correct? (no write conflicts)
    - If review fails → fix task ordering → re-review

13. Run `/sc:estimate` on each phase
    - Effort estimation with confidence intervals
    - Risk assessment per phase

14. Run `/sc:workflow` to validate the implementation plan
    - Structured workflow validation from PRD
    - Confirms dependency ordering and parallel safety

15. Run `/checkpoint` for each output

16. **GATE:** `/gate stage-2`
    - Git push → create PR
    - CodeRabbit reviews → fix ALL suggestions → 0 remaining → PASS

---

### Phase 3: Implement

15. For each GitHub Issue (in dependency order):

    **THE FORGE CELL (9 steps — NEVER skip any):**

    Every agent runs through `/run-with-checkpoint` (auto-checkpointing wrapper).

    Step 0: TASK DECOMPOSITION
      - Run `/sc:spawn` to break complex issues into subtasks
      - Simple issues → skip to Step 1
      - Complex issues → decompose → execute subtasks sequentially

    Step 1: CONTEXT LOAD + LIBRARY RESEARCH
      - @context-loader-agent fetches library docs via context7 MCP
      - Load relevant rules/ files for this domain
      - context7: resolve-library-id + query-docs for EVERY library used

    Step 2: AGENT RESEARCH (self-discovery + trends + alternatives)
      - Selected agent reads: spec [REQ-xxx], existing tests, current code, rules/, API contracts
      - Agent identifies: gaps, missing requirements, improvements
      - **WEB SEARCH:** best practices for this feature in current year
      - **ALTERNATIVES:** compare 2+ approaches, choose best with rationale
      - **TRENDS:** check for new libraries, deprecations, pattern changes
      - Output: research brief (approach chosen, alternatives, sources)
      - If new insight → flag for spec/test/code update

    Step 3: TDD IMPLEMENTATION (self-executing — agent RUNS its own code)
      - a) Write TEST first → references [REQ-xxx]
      - b) **RUN test via Bash** → MUST FAIL (proves test is real)
      - c) Write CODE → references [REQ-xxx]
      - d) **RUN test via Bash** → MUST PASS
      - e) **RUN ALL tests via Bash** → no regressions
      - f) **RUN quick verification** (import check, model field check, route check)
      - On ANY failure: classify error semantically (TEST_FAILURE, IMPORT_ERROR, etc.)
        → fix based on error type → re-run (max 3 self-fix iterations)

    Step 4: BUILD + QUALITY (self-verifying)
      - **RUN** `/sc:build` to compile/package if needed
      - **RUN** black + ruff (auto via PostToolUse hook)
      - **RUN** full test suite via Bash
      - **CLASSIFY** any errors semantically (don't just report exit code)
      - If FAIL:
        → Run `/sc:troubleshoot` first (diagnosis before fix)
        → Then `/investigate` (root cause analysis)
        → @root-cause-analyst reflexion (max 3 attempts)
        → Still fails? → STOP and ask user

    Step 5: SYNC CHECK (bidirectional)
      - New code? → verify [REQ-xxx] exists in SPEC
      - New behavior? → verify test exists
      - Gap found? → add to SPEC + add test + update code
      - Run traceability: 100% coverage, 0 orphans, 0 drift

    Step 6: PER-AGENT JUDGE (NEVER SKIP)
      - **REVIEW:** Domain-specific judge evaluates:
        - □ Output matches spec [REQ-xxx]?
        - □ Tests pass?
        - □ Architecture rules followed?
        - □ API contracts match design doc Section 4?
        - □ All documents in sync?
        - □ No security issues?
      - Rate quality: 1-5
      - Write mini-retrospective to: docs/retros/{agent}-{issue}.md
      - Rating ≥4 → ACCEPT
      - Rating <4 → REITERATE same agent with judge's feedback (max 3)
      - Judge's retro feeds into next attempt (agent reads what went wrong)

    Step 7: COMMIT + LEARN
      - Git commit with conventional message
      - GitHub: close issue
      - /checkpoint: evaluate agent output quality
      - If agent discovered improvements → /learn (save to playbook)

16. After each implementation phase (group of related issues):
    - **REVIEW:** Run `/review` on the phase's code
      - Staff-engineer level: completeness, security, architecture, edge cases
      - Fix-First mode: auto-fix obvious issues, flag design decisions
      - If issues found → fix → re-run /review until CLEAN
    - If frontend phase:
      - Run `/design-system` to create/verify design tokens (first frontend phase only)
      - **REVIEW:** Run `/design-audit` on templates
        - 7-pass audit: info architecture, states, journey, consistency, responsive, accessibility, edge cases
        - Score must be ≥50/70. If <50 → fix → re-audit
      - **CRITIC:** Run `/critic` on frontend pages
        - Maps ALL elements (buttons, forms, links, events)
        - Tests ALL paths (depth + breadth + edge cases)
        - Auto-creates GitHub Issues for EVERY failure
        - Each issue triggers internal fix cycle:
          spec updated → test updated → code fixed → re-verified
        - Repeats until 0 new failures
    - Git push → create PR
    - **GATE:** `/gate phase-N`
      - CodeRabbit reviews → fix ALL suggestions → 0 remaining → PASS

---

### Phase 4: Validate

17. Run `/sc:analyze` on full codebase
    - Quality, security, performance, architecture analysis
    - Identifies issues before formal audit

18. Run `/audit-patterns full` → must be >90%
    - If <90% → fix top 5 failures → re-audit

19. Run `/sc:test --coverage`
    - Gate tests (blocking): unit + integration → must all pass
    - Periodic tests (non-blocking): E2E, performance

19. Run traceability check (scripts/traceability.sh)
    - 100% coverage, 0 orphans, 0 drift
    - If gaps → fix → re-check

20. Run `/security-scan` → OWASP Top 10 + STRIDE threat model
    - **REVIEW:** @security-engineer validates findings
    - CRITICAL/HIGH findings → must fix before proceeding
    - MEDIUM/LOW → create GitHub Issues for future fix

21. Run `/design-audit` on all frontend pages (if UI exists)
    - **REVIEW:** Score must be ≥50/70
    - If <50 → fix top issues → re-audit

22. Run `/critic` — FULL autonomous frontend test (if UI exists)
    - Maps entire frontend graph (pages, elements, paths)
    - Tests every depth path, breadth path, and edge case
    - Auto-creates issues for failures → internal fix cycle
    - Repeats until 0 new failures found
    - All fixes sync spec↔test↔code via [REQ-xxx]

23. Run `/benchmark` — establish performance baseline
    - API response times, database query counts, page load times
    - Compare with targets: <200ms API, <3s page load

24. Run `/codex` — multi-model cross-review (OPTIONAL — requires secondary model API key)
    - Skip if no API key available
    - When available: second opinion catches blind spots single model misses

25. Run `/qa-report` — pure bug reporting (no fixes)
    - Find ALL remaining bugs across frontend, API, security, data
    - Auto-create GitHub Issues for each bug
    - Bugs fixed through normal Forge Cell flow

26. **GATE:** `/gate stage-4`
    - Git push → create PR
    - CodeRabbit reviews → fix ALL suggestions → 0 remaining → PASS

---

### Phase 5: Review + Learn

23. Run `/sc:cleanup` on full codebase
    - Remove dead code, unused imports, optimize structure
    - @refactoring-expert handles complex refactors

24. Run `/sc:improve` on critical paths
    - Systematic quality + performance improvements
    - Auto-fix style issues, flag architectural changes for approval

25. Run `/retro` → retrospective
    - What went well (with evidence)
    - What could improve (with root cause + fix)
    - Lessons learned → feed to playbook

26. Run `/sc:reflect` to validate task completion
    - Verify all requirements met, all issues closed

27. Run `/sc:document` to generate/update project docs
    - API documentation, component docs, user guides

28. **REVIEW:** @playbook-curator delta-updates playbook
    - Increment helpful/harmful counters based on retro outcomes
    - Add new strategies from lessons learned
    - NEVER rewrite — only delta-update

25. Run `/prune` → remove rules where harmful > helpful
    - Pruned entries → playbook/archived.md (never deleted)

26. Run `/evolve` → cluster strong strategies (helpful >3) into reusable skills
    - 3+ related strategies → new skill file in rules/ or agents/stacks/

27. Run `/autoresearch` on agent prompts that scored <100% in checkpoints
    - Self-improving prompt loop — mutates prompts to fix identified issues
    - Makes next build better

28. Run `/sc:save` to persist session context
    - Cross-session memory via playbook + checkpoint files
    - Next session starts informed

29. **GATE:** `/gate stage-5`
    - Git push → create FINAL PR
    - CodeRabbit reviews → fix ALL suggestions → 0 remaining
    - MERGE

30. Run `/ship` — full release engineering
    - Sync main, verify tests, audit, push, merge, deploy
    - One command: code complete → verified in production

31. Run `/canary` — post-deploy monitoring (30 min)
    - Health checks every 5 minutes
    - API latency, error rates, page loads
    - If issues found → auto-create GitHub Issues → fix cycle

---

### Phase 6: Iterate

28. Collect feedback → new GitHub Issues
29. Bug found → /investigate FIRST (root cause before fix)
30. Fix → grows system:
    - New code → spec updated [REQ-xxx]
    - New test added
    - Playbook updated (/learn)
31. Loop to Phase 1 (new features) or Phase 3 Step 15 (fixes)

---

### Output

```
Forge complete.
- Project: [name]
- Location: [path]
- Tests: [count] passing
- Coverage: [%]
- Traceability: [%] REQ coverage
- Audit: [%] pattern pass rate
- Security: [risk level]
- Design: [score]/70
- PR: #[number] merged
- Reviews passed: [count] (per-agent judges + /review + CodeRabbit)
- Playbook: [count] strategies learned
```

---

## FLOW B: Bug Fix (existing project, user reports a bug)

<system-reminder>
STRICT ENFORCEMENT — Bug Fix Flow:
1. NEVER fix without /investigate first (root cause before fix)
2. MUST spawn @root-cause-analyst agent (not just grep yourself)
3. MUST write task design doc BEFORE writing any fix code
4. MUST write test that reproduces the bug FIRST (TDD — test fails, then fix, then test passes)
5. MUST run ALL tests after fix (not just the new test)
6. MUST update SPEC.md with [REQ-xxx] if requirement was missing
7. MUST run /checkpoint after fix
8. MUST run /learn if bug reveals a non-obvious pattern
Every bug fix makes the system BETTER — new test, new REQ, new playbook entry.
</system-reminder>

1. **Read CLAUDE.md** → understand project context, rules, tech stack
2. **Understand the bug** → read the user's description, reproduce if possible
3. **Run /investigate** → @root-cause-analyst traces the code path:
   - Read the relevant files (user may give hints like file:line)
   - Grep for related patterns
   - Trace the execution flow
   - Identify the ROOT CAUSE (not just the symptom)
4. **Write task design doc** → using templates/task-design-doc.template.md:
   - What files to change
   - What the fix looks like (exact code)
   - What tests to add
   - Sync check: which [REQ-xxx] does this relate to?
5. **TDD fix**:
   - Write test that reproduces the bug → run → must FAIL (proves bug exists)
   - Write the fix → run test → must PASS
   - Run ALL tests → no regressions
6. **Quality**: `black . && ruff check . --fix`
7. **Sync check**:
   - Search SPEC.md for a [REQ-xxx] covering this behavior
   - If found → add test reference to sync check table
   - If NOT found → create new [REQ-xxx] in SPEC.md:
     - Determine next available number: `grep -oP 'REQ-\d+' SPEC.md | sort -t- -k2 -n | tail -1`
     - Append to SPEC.md Requirements Traceability section
     - Add to sync check table: [REQ-xxx] → test → code
   - This ensures EVERY bug fix GROWS the spec (system gets better with every fix)
8. **Commit**: `git commit -m "fix(domain): description [REQ-xxx]"`
9. **/learn**: if the bug reveals a non-obvious pattern → save to playbook

---

## FLOW C: New Feature (existing project, user wants new functionality)

<system-reminder>
STRICT ENFORCEMENT — New Feature Flow:
1. MUST run /specify with @requirements-analyst (not just list requirements yourself)
2. MUST spawn @business-panel-experts to validate the feature makes business sense
3. MUST run /design-doc with @system-architect + @backend-architect + @security-engineer
4. MUST produce ALL 10 sections in design doc (check templates/design-doc-completeness-checklist.md)
5. MUST run /plan-tasks to create phased issues with dependencies
6. For EACH issue:
   a. MUST write task design doc FIRST (templates/task-design-doc.template.md)
   b. MUST call @context-loader-agent to fetch library docs via context7
   c. MUST write test FIRST (TDD) — test must FAIL before code is written
   d. MUST run test after code — test must PASS
   e. MUST run ALL tests — no regressions
   f. MUST run black + ruff
   g. MUST spawn @reviewer to rate output 1-5 — reject if <4
   h. MUST run /checkpoint
   i. MUST verify sync: every [REQ-xxx] has test + code
7. After ALL issues in a phase → /gate
8. After feature complete → /retro + /learn
Target: 10+ tests per feature area, 100% REQ traceability, 0 orphan code.
This is NOT optional. Every step produces an artifact. No step is "assumed."
</system-reminder>

1. **Read CLAUDE.md** → understand project context, existing SDLC flow, agent selection matrix
2. **Read existing SPEC.md** → understand what already exists, what [REQ-xxx] tags are used
3. **Run /specify** on the user's feature request:
   - Spawns @requirements-analyst → extracts requirements with [REQ-xxx] tags
   - Produces proposal in docs/proposals/
   - Creates GitHub issues (or local markdown issues if no remote)
   - **Persist new [REQ-xxx] tags to SPEC.md** — append to Requirements Traceability section:
     - Read existing SPEC.md → find `## Requirements Traceability` table
     - If section missing → create it (see /generate-spec for format)
     - Append new [REQ-xxx] rows to the table
     - This ensures SPEC.md is ALWAYS the single source of truth for requirements
4. **Run /design-doc** on the proposal:
   - Spawns @system-architect + @backend-architect + @security-engineer
   - Produces 10-section design doc
   - Includes API contracts, model changes, test scenarios
5. **Run /plan-tasks** on the design doc:
   - Breaks into phased GitHub issues with dependencies
6. **Implement per issue** (Forge Cell):
   - Step 0: Task design doc (mini design doc per issue)
   - Step 1: @context-loader-agent fetches library docs
   - Step 2: Domain agent researches (reads spec, tests, code, rules)
   - Step 3: TDD (test first → fail → code → pass → all tests)
   - Step 4: Quality (black + ruff + full test suite)
   - Step 5: Sync check (spec↔test↔code, [REQ-xxx] traceability)
   - Step 6: Per-agent judge rates 1-5 (accept ≥ 4)
   - Step 7: Commit → close issue → /checkpoint → /learn
7. **Run /gate** after each phase
8. **Run /retro** when feature is complete

---

## FLOW D: Improvement (refactor, optimize, clean up)

1. **Read CLAUDE.md** → understand project context
2. **Analyze current state**:
   - If refactor: @refactoring-expert analyzes the target code
   - If performance: @performance-engineer profiles and measures
   - If cleanup: @code-archaeologist finds dead code, tech debt
3. **Write task design doc** → what changes, why, what tests verify the improvement
4. **Implement with safety**:
   - Run ALL existing tests first → establish baseline
   - Make changes (one at a time for refactors)
   - Run ALL tests after each change → no regressions
   - For performance: measure before AND after with exact numbers
5. **Commit**: `git commit -m "refactor|perf|chore(domain): description"`
6. **/learn**: if improvement reveals pattern → save to playbook

---

## FLOW E: Knowledge (user asks a question)

1. **Read CLAUDE.md** → understand project context
2. **Read relevant code** → find the actual implementation
3. **Explain** using @learning-guide or @socratic-mentor:
   - Use real code from THIS project (not generic examples)
   - Build explanation progressively
   - Connect to project's architecture decisions
4. **No code changes** — this is read-only
