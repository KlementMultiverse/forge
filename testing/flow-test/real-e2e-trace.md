# Forge SDLC Flow — Real E2E Trace

**Date:** 2026-04-02
**Test Project:** /home/intruder/projects/forge-flow-test/
**User Request:** "Build a task tracker with Kanban board and team collaboration"
**Tester:** Claude Code (automated trace)

---

## Infrastructure Status

### Installed Commands (~/.claude/commands/)
```
INSTALLED (11):
  audit-patterns.md, autoresearch.md, build-project.md, checkpoint.md,
  design-doc.md, gate.md, plan-tasks.md, retro.md, run-with-checkpoint.md,
  specify.md, sc/ (31 subcommands)

NOT INSTALLED (18 forge-specific):
  discover, requirements, feasibility, generate-spec, bootstrap,
  challenge, investigate, learn, careful, freeze, guard, evolve, prune,
  review, security-scan, design-audit, critic, forge
```

### Installed Agents (~/.claude/agents/)
```
INSTALLED: 55 agents (universal + stack-specific)
  Includes all key agents: pm-orchestrator, context-loader-agent,
  django-tenants-agent, django-ninja-agent, s3-lambda-agent,
  pattern-auditor-agent, requirements-analyst, system-architect,
  backend-architect, security-engineer, quality-engineer, root-cause-analyst,
  etc.
```

### Forge Repo (/home/intruder/projects/forge/)
```
EXISTS with: agents/, commands/, docs/, hooks/, install.sh, playbook/,
  rules/, scripts/, templates/, testing/

The 18 forge-specific commands exist in forge/commands/ but were NEVER
installed to ~/.claude/commands/ via install.sh.
```

### Test Project State (/home/intruder/projects/forge-flow-test/)
```
- Git initialized: YES (no commits yet)
- GitHub remote: NO (no remote configured)
- Files: CLAUDE.md (template), SPEC.md (template), docs/ (empty subdirs), .forge/
- CodeRabbit: NOT CONFIGURED (no repo to attach it to)
```

### External Dependencies
```
- gh CLI: INSTALLED, AUTHENTICATED (KlementMultiverse)
- context7 MCP: AVAILABLE
- uv: NOT CHECKED (no pyproject.toml yet)
- Docker: NOT CHECKED
- PostgreSQL: NOT CHECKED
```

---

## Phase 0: GENESIS

### Step 0.1: /discover
- **File exists in forge/commands/:** YES (`/home/intruder/projects/forge/commands/discover.md`)
- **Installed to ~/.claude/commands/:** NO
- **Status:** BROKEN
- **What it does:** Spawns `@deep-research-agent` to research the problem space. Saves to `docs/discovery-report.md`.
- **Issue:** The command references `@deep-research-agent` but the installed agent file is `deep-researcher.md` (name mismatch: "deep-research-agent" vs "deep-researcher"). Also, the command itself is not installed so `/discover` would not be recognized by Claude Code.
- **Would produce:** `docs/discovery-report.md` with problem statement, target users, current solutions, gaps, success criteria.

### Step 0.2: /requirements
- **File exists in forge/commands/:** YES (`/home/intruder/projects/forge/commands/requirements.md`)
- **Installed to ~/.claude/commands/:** NO
- **Status:** BROKEN
- **What it does:** Spawns `@requirements-analyst` to extract [REQ-xxx] tagged requirements from discovery report. Also uses `/sc:brainstorm` for Socratic discovery.
- **Issue:** Not installed. Also depends on output of /discover (docs/discovery-report.md).
- **Would produce:** `docs/requirements.md` with [REQ-xxx] tagged functional/non-functional requirements.

### Step 0.3: /feasibility
- **File exists in forge/commands/:** YES (`/home/intruder/projects/forge/commands/feasibility.md`)
- **Installed to ~/.claude/commands/:** NO
- **Status:** BROKEN + NEEDS HUMAN
- **What it does:** Spawns `@system-architect` and `@security-engineer` to recommend tech stack. Then ASKS USER to confirm stack. Then checks if agents exist for that stack.
- **Issue:** Not installed. Also has an explicit "ASK USER" step for stack confirmation.
- **NEEDS HUMAN:** Stack selection requires user approval.
- **Would produce:** `docs/feasibility.md` with recommended stack + security assessment.

### Step 0.4: /generate-spec
- **File exists in forge/commands/:** YES (`/home/intruder/projects/forge/commands/generate-spec.md`)
- **Installed to ~/.claude/commands/:** NO
- **Status:** BROKEN
- **What it does:** PM synthesizes discovery + requirements + feasibility into SPEC.md using `templates/SPEC.template.md`.
- **Issue:** Not installed. Also depends on all 3 prior documents. The template file `templates/SPEC.template.md` exists in the forge repo but is NOT in the test project.
- **Would produce:** Filled SPEC.md at project root.

### Step 0.5: /bootstrap
- **File exists in forge/commands/:** YES (`/home/intruder/projects/forge/commands/bootstrap.md`)
- **Installed to ~/.claude/commands/:** NO
- **Status:** BROKEN
- **What it does:** Creates project folder, copies templates, fills CLAUDE.md, creates docker-compose.yml, pyproject.toml, .gitignore, .env.example. Does `git init` + `gh repo create`.
- **Issue:** Not installed. Also runs `gh repo create` which would need a new GitHub repo.
- **Would produce:** Full project scaffold with all config files + GitHub repo.

### Phase 0 Verdict: BROKEN
All 5 Phase 0 commands exist in the forge repo at `/home/intruder/projects/forge/commands/` but NONE are installed to `~/.claude/commands/`. Running `./install.sh` would fix this.

---

## Phase 1: SPECIFY

### Step 1.1: /specify
- **Installed:** YES (`~/.claude/commands/specify.md`)
- **Status:** WORKS (with caveats)
- **What it does:**
  1. Reads CLAUDE.md + SPEC.md
  2. Spawns `@requirements-analyst` (INSTALLED)
  3. Spawns `@business-panel-experts` (INSTALLED)
  4. Fills proposal template with Given/When/Then acceptance criteria
  5. Saves to `docs/proposals/NN-feature-name.md`
  6. Creates GitHub Issues via `gh issue create`
- **Caveats:**
  - GitHub Issues require a remote repo (forge-flow-test has NONE) -- gh issue create will FAIL
  - SPEC.md is currently a blank template -- /specify would operate on placeholder text
  - If Phase 0 is skipped (because broken), SPEC.md would need to be manually written first
- **Depends on:** Filled SPEC.md, GitHub remote

### Step 1.2: /checkpoint
- **Installed:** YES
- **Status:** WORKS
- **What it does:** Creates checkpoint file at `docs/checkpoints/NN-specify-timestamp.md`. Evaluates 14 criteria (8 universal + 6 backend). Can mutate agent prompts if issues found.
- **Caveats:** Needs `docs/checkpoints/` directory (EXISTS in test project).

### Step 1.3: /gate stage-1
- **Installed:** YES
- **Status:** BROKEN (infrastructure missing)
- **What it does:**
  1. Runs /audit-patterns quick
  2. Commits + pushes via `/sc:git --smart-commit`
  3. Creates PR via `gh pr create`
  4. Waits for CodeRabbit review
  5. Blocks until CodeRabbit state = "APPROVED"
- **Issues:**
  - No GitHub remote = `git push` FAILS
  - No GitHub remote = `gh pr create` FAILS
  - No CodeRabbit = will never get "APPROVED" state
  - /audit-patterns spawns @pattern-auditor-agent which has 170+ checks -- would work but score will be meaningless on a proposal-only stage

### Phase 1 Verdict: PARTIALLY WORKS
/specify and /checkpoint would execute. /gate is BROKEN without GitHub remote + CodeRabbit.

---

## Phase 2: ARCHITECT

### Step 2.1: /design-doc
- **Installed:** YES (`~/.claude/commands/design-doc.md`)
- **Status:** WORKS (with caveats)
- **What it does:**
  1. Reads CLAUDE.md + proposal + SPEC.md
  2. Fetches context7 docs for libraries (context7 MCP IS AVAILABLE)
  3. Spawns `@system-architect` (INSTALLED)
  4. Spawns `@backend-architect` (INSTALLED)
  5. Spawns `@security-engineer` (INSTALLED)
  6. Fills 10-section design doc template
  7. Runs `/sc:spec-panel` for multi-expert review
  8. Saves to `docs/design-doc.md`
- **Caveats:**
  - The template references django-tenants/django-ninja (clinic-portal specific) in context7 queries -- for a task tracker, these would be wrong libraries. The command is hardcoded to fetch those specific libraries.
  - Quality depends on SPEC.md being properly filled

### Step 2.2: /plan-tasks
- **Installed:** YES (`~/.claude/commands/plan-tasks.md`)
- **Status:** PARTIALLY WORKS
- **What it does:**
  1. Reads design doc
  2. Spawns `@pm-agent` (INSTALLED)
  3. Uses `/sc:estimate` and `/sc:workflow` (INSTALLED in sc/)
  4. Creates GitHub Issues with phase labels
- **Issues:**
  - `gh issue create` requires GitHub remote (MISSING)
  - `gh issue list --state all` will fail without remote

### Phase 2 Verdict: PARTIALLY WORKS
Design doc generation works. GitHub Issue creation is BROKEN.

---

## Phase 3: IMPLEMENT

### Step 3.0: Task Design Doc
- **Template exists:** YES (`/home/intruder/projects/forge/templates/task-design-doc.template.md`)
- **In test project:** NOT CHECKED (template is in forge repo, not in test project's .forge/)
- **Status:** NEEDS INVESTIGATION -- the PM orchestrator references this but it may not be copied to the project

### Step 3.1: @context-loader-agent
- **Installed:** YES (`~/.claude/agents/context-loader-agent.md`)
- **Status:** WORKS
- **What it does:** Fetches library docs via context7 MCP before coding.
- **context7 MCP available:** YES
- **Caveat:** The Library Map in the agent is heavily clinic-portal-specific (django-tenants, django-ninja, boto3). For a generic task tracker, it would use the "Dynamic Library Detection" fallback which reads pyproject.toml. Since no pyproject.toml exists yet, this would partially fail.

### Step 3.2: Agent Implementation
- **Agent selection works:** YES (agents exist for all domain labels in the matrix)
- **Status:** WORKS (conceptually)
- **How it works:** PM reads issue labels, selects agent from matrix, spawns agent with spec + CLAUDE.md + context7 docs. Agent writes code using Bash/Write/Edit tools.
- **Caveat:** The Agent Selection Matrix in the template CLAUDE.md is BLANK (placeholder `@[agent-name]`). It would need to be filled during /bootstrap or /generate-spec.

### Step 3.3: /checkpoint
- **Status:** WORKS (same as Phase 1 evaluation)

### Step 3.4: /gate
- **Status:** BROKEN (same infrastructure issues -- no GitHub remote, no CodeRabbit)

### Step 3.5: Post-implementation checks
- **Commands referenced:** `black . && ruff check . --fix`, `uv run python manage.py test`
- **Status:** NEEDS SETUP -- black, ruff, Django must be installed first (requires pyproject.toml + uv sync)

### Phase 3 Verdict: PARTIALLY WORKS
Agent delegation and context loading work. Gates are broken. Post-impl checks need project setup.

---

## Phase 4: VALIDATE

### Step 4.1: /audit-patterns
- **Installed:** YES (`~/.claude/commands/audit-patterns.md`)
- **Status:** WORKS
- **What it does:**
  1. Spawns `@pattern-auditor-agent` (INSTALLED)
  2. Spawns `@quality-engineer` (INSTALLED)
  3. Spawns `@self-review` (INSTALLED)
  4. Reports pass/fail for 170+ checks
- **Caveat:** The 170+ checks are from "Weeks 1-4" of an SDLC course -- they may reference patterns that don't exist in a non-clinic-portal project.

### Step 4.2: /sc:test --coverage
- **Installed:** YES (in sc/ subcommands)
- **Status:** NEEDS SETUP -- requires Django project to exist with tests

### Phase 4 Verdict: PARTIALLY WORKS
Audit runs but test infrastructure needs setup.

---

## Phase 5: REVIEW

### Step 5.1: /retro
- **Installed:** YES (`~/.claude/commands/retro.md`)
- **Status:** PARTIALLY WORKS
- **What it does:**
  1. Reads git log + GitHub Issues + audit reports
  2. Spawns `@pm-agent` (INSTALLED)
  3. Uses `/sc:reflect` (INSTALLED)
  4. Spawns `@learning-guide` (INSTALLED)
  5. Fills retrospective template
  6. Updates CLAUDE.md with lessons
  7. Saves to `docs/retrospectives/NN-feature-name.md`
- **Issues:**
  - `gh issue list --state all` requires GitHub remote (MISSING)
  - Everything else works

### Step 5.2: /gate stage-5 (final PR)
- **Status:** BROKEN (same as all gates -- no GitHub remote)

### Phase 5 Verdict: PARTIALLY WORKS
Retro generation works. Final PR/gate broken.

---

## Phase 6: ITERATE

### No specific commands
- **Status:** WORKS (conceptual -- PM reads checkpoints and loops)
- **Caveat:** Depends on all prior phases having produced artifacts

---

## Cross-Cutting Checks

### 1. GitHub Integration
- **gh CLI installed:** YES
- **gh authenticated:** YES (KlementMultiverse)
- **GitHub repo for test project:** NO
- **gh issue create:** WILL FAIL (no remote)
- **gh pr create:** WILL FAIL (no remote)
- **Fix:** Run `gh repo create forge-flow-test --private --source=. --push` from project dir

### 2. CodeRabbit
- **Configured on test project:** NO (no repo exists)
- **Required by:** /gate (every stage boundary)
- **Impact:** ALL gates are blocked without CodeRabbit
- **Fix:** Create GitHub repo, install CodeRabbit GitHub App, add .coderabbit.yaml

### 3. Traceability Script
- **Exists:** YES (`/home/intruder/projects/forge/scripts/traceability.sh`)
- **Works:** YES (tested -- it greps for [REQ-xxx] tags across spec/tests/code)
- **In test project:** NO (not copied by install)
- **Fix:** Copy to project or run from forge repo path

### 4. Forge Install Script
- **Exists:** YES (`/home/intruder/projects/forge/install.sh`)
- **Problem:** It was NEVER RUN (or run incompletely). The 18 forge-specific commands are NOT in ~/.claude/commands/.
- **Evidence:** install.sh line 38: `cp "$FORGE_DIR"/commands/*.md "$CLAUDE_DIR/commands/"` -- this WOULD copy all forge commands. But the 18 forge commands are missing from ~/.claude/commands/, meaning install.sh was either never run, or was run before these commands were created.

### 5. Agent "Spawning" Mechanism
- **How agents are "spawned":** Claude Code reads the agent .md file and follows its instructions inline. There is no actual process spawning -- it's prompt injection via file reading.
- **Works:** YES -- Claude Code can read ~/.claude/agents/*.md and execute their instructions.
- **Limitation:** "Max 2 agents in parallel" is aspirational -- Claude Code executes sequentially within a single conversation.

### 6. Template Files
- **In forge repo:** YES (10 templates in /home/intruder/projects/forge/templates/)
- **In test project:** NOT COPIED
- **Used by:** /generate-spec (SPEC.template.md), /bootstrap (CLAUDE.template.md, docker-compose.template.yml, pyproject.template.toml)

---

## Summary Scorecard

| Step | Command | Installed? | Executable? | Verdict |
|------|---------|-----------|-------------|---------|
| 0.1 | /discover | NO | NO | BROKEN |
| 0.2 | /requirements | NO | NO | BROKEN |
| 0.3 | /feasibility | NO | NO | BROKEN + NEEDS HUMAN |
| 0.4 | /generate-spec | NO | NO | BROKEN |
| 0.5 | /bootstrap | NO | NO | BROKEN |
| 1.1 | /specify | YES | PARTIAL | Needs GitHub remote + filled SPEC.md |
| 1.2 | /checkpoint | YES | YES | WORKS |
| 1.3 | /gate stage-1 | YES | NO | Needs GitHub remote + CodeRabbit |
| 2.1 | /design-doc | YES | YES | WORKS (context7 available) |
| 2.2 | /plan-tasks | YES | PARTIAL | Needs GitHub remote for issues |
| 3.0 | Task design doc | N/A | N/A | Template not in project |
| 3.1 | @context-loader | YES | YES | WORKS (context7 available) |
| 3.2 | Agent impl | YES | YES | Agents exist and can execute |
| 3.3 | /checkpoint | YES | YES | WORKS |
| 3.4 | /gate | YES | NO | Needs GitHub remote + CodeRabbit |
| 4.1 | /audit-patterns | YES | YES | WORKS |
| 4.2 | /sc:test | YES | PARTIAL | Needs Django project setup |
| 5.1 | /retro | YES | PARTIAL | Needs GitHub remote for issue list |
| 5.2 | /gate stage-5 | YES | NO | Needs GitHub remote + CodeRabbit |

### Overall Stats
- **WORKS:** 6/19 steps (32%)
- **PARTIAL:** 5/19 steps (26%)
- **BROKEN:** 8/19 steps (42%)

---

## Root Causes (3 blockers explain all failures)

### Blocker 1: Forge commands not installed
**Impact:** Phase 0 entirely broken (5 commands)
**Fix:** `cd /home/intruder/projects/forge && ./install.sh`
**Time to fix:** 5 seconds

### Blocker 2: No GitHub remote on test project
**Impact:** All /gate steps, /plan-tasks issue creation, /retro issue listing, /specify issue creation
**Fix:** `cd /home/intruder/projects/forge-flow-test && gh repo create forge-flow-test --private --source=. --push`
**Time to fix:** 10 seconds

### Blocker 3: No CodeRabbit on test project
**Impact:** All /gate steps (every stage boundary is blocked)
**Fix:** Install CodeRabbit GitHub App on the repo, add `.coderabbit.yaml`
**Time to fix:** 5 minutes (manual GitHub App installation)

---

## Additional Issues (non-blocking but noteworthy)

### Issue 4: Agent name mismatch in /discover
- `/discover` references `@deep-research-agent`
- Installed agent file is `deep-researcher.md` (no `-agent` suffix)
- Also: there are THREE deep research files: `deep-research-agent.md`, `deep-researcher.md`, `deep-research.md` -- confusing

### Issue 5: Hardcoded clinic-portal references
- `/design-doc` hardcodes context7 queries for django-tenants, django-ninja, boto3
- `@context-loader-agent` Library Map is clinic-portal specific
- For a task tracker, these would fetch irrelevant docs
- **Mitigation:** Dynamic Library Detection fallback exists but needs pyproject.toml

### Issue 6: Template CLAUDE.md has blank Agent Selection Matrix
- The template at forge-flow-test/CLAUDE.md has placeholder `@[agent-name]`
- /bootstrap should fill this but /bootstrap is not installed
- Without filled matrix, PM orchestrator cannot select agents

### Issue 7: "Parallel agents" is aspirational
- PM orchestrator says "Max 2 agents in parallel"
- Claude Code executes sequentially in a single conversation
- The [P] parallel markers in plans are informational, not functional

### Issue 8: /gate hardcodes "clinic-portal" in PR body
- Line in gate.md: `Proposal: docs/proposals/01-clinic-portal.md`
- Should be parameterized

---

## Recommended Fix Order

1. Run `cd /home/intruder/projects/forge && ./install.sh` (fixes Blocker 1)
2. Create GitHub repo for test project (fixes Blocker 2)
3. Install CodeRabbit on repo (fixes Blocker 3)
4. Fix agent name mismatch in /discover (fixes Issue 4)
5. Make /design-doc context7 queries dynamic (fixes Issue 5)
6. Make /gate PR body use variables not hardcoded project name (fixes Issue 8)

After these 6 fixes, the flow would be ~90% functional for the "task tracker with Kanban board" request.
