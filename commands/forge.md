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

### STEP 0.5: CHECK FORGE STATE (HIGHEST PRIORITY — before anything else)

If `docs/forge-state.json` exists:
```bash
bash scripts/forge-enforce.sh check-state 2>/dev/null || bash ~/.claude/scripts/forge-enforce.sh check-state 2>/dev/null
bash scripts/forge-enforce.sh check-continuation 2>/dev/null || bash ~/.claude/scripts/forge-enforce.sh check-continuation 2>/dev/null
```

**VIOLATION REMEDIATION — AUTO-FIX (CASE 8):**
If forge-state.json has violations > 0 → ROUTE TO CASE 8 IMMEDIATELY.
Do NOT ask the user. Do NOT show options. Auto-fix violations.

**RESUME — AUTO-CONTINUE:**
If forge-state.json shows current_step < 57 → RESUME from next step.
Do NOT ask the user. Continue execution from where it left off.

### STEP 1: READ FORGE.md (if exists)

If FORGE.md exists in the project:
1. Read it
2. **FIRST:** Check forge-state.json for violations → if any → CASE 8 (auto-fix)
3. **SECOND:** Check forge-state.json for incomplete steps → if any → RESUME from next step
4. **THIRD:** Find the first QUEUED item
5. Set it to ACTIVE
6. Route to the correct flow based on `type`:
   - NEW_PROJECT → CASE 1
   - FEATURE → CASE 3
   - BUG → CASE 4
   - IMPROVEMENT → CASE 5
7. If no QUEUED items AND no violations AND all steps done → ask user what to do

If FORGE.md does NOT exist:
1. Route based on hook detection (current behavior)
2. Create FORGE.md during execution

If hook output is missing or ambiguous, run detection manually:
```
1. forge-state.json has violations?              → CASE 8 (violation remediation — AUTO)
2. forge-state.json has incomplete steps?        → RESUME from next step (AUTO)
3. CLAUDE.md? NO. Code exists? NO.              → CASE 1 (greenfield — new project)
4. CLAUDE.md? NO. Code exists? YES.              → CASE 7 (brownfield — existing code, no forge)
5. CLAUDE.md? YES (placeholders). Code? NO.      → CASE 1 (template only — same as greenfield)
6. CLAUDE.md? YES (real). Code? NO.              → CASE 2 (has spec, needs implementation)
7. CLAUDE.md? YES. Code? YES. Bug keywords?      → CASE 4 (bug fix)
8. CLAUDE.md? YES. Code? YES. Feature keywords?  → CASE 3 (new feature)
9. CLAUDE.md? YES. Code? YES. Improve keywords?  → CASE 5 (improvement)
10. None of the above                            → CASE 6 (ask user)
```

**CRITICAL: Cases 1-2 (violations and incomplete steps) are checked FIRST. They take priority over everything. Do NOT ask the user if violations exist — just fix them.**

---

### CASE 1: NEW PROJECT (no CLAUDE.md or placeholder CLAUDE.md)

#### Phase A — Setup (Session 1: creates all files agents need)

<system-reminder>
SESSION 1 RULES:
- PM orchestrates but NEVER writes CLAUDE.md, SPEC.md, or FORGE.md directly
- Each file is built by a SPECIALIST AGENT following a TEMPLATE
- Every agent output is VERIFIED before proceeding
- Session 1 ends with "Setup complete. Run forge again to build."
- NO CODE IS WRITTEN in Session 1 — only planning/spec/config files
</system-reminder>

**STEP S1: ASSESS** (PM scans folder — no agents)

```bash
# PM runs these checks automatically
ls CLAUDE.md 2>/dev/null          # exists?
ls SPEC.md 2>/dev/null            # exists?
ls FORGE.md 2>/dev/null           # exists?
ls .forge/ 2>/dev/null            # forge initialized?
ls .claude/ 2>/dev/null           # claude rules exist?
find . -maxdepth 2 -name "*.py" -o -name "*.ts" | head -1  # code exists?
cat CLAUDE.md 2>/dev/null | grep "{{" | head -1             # placeholder?
```

Based on scan:
- EMPTY folder → continue to STEP S2 (full setup)
- Code exists, no CLAUDE.md → jump to STEP S5-BROWNFIELD
- CLAUDE.md with placeholders → continue to STEP S2
- Everything exists → "Setup already complete. Run /forge again to build."

**STEP S2: DISCOVERY CONVERSATION** (PM only — gathers information)

PM asks questions ONE AT A TIME. Between each answer, PM researches:

Q1: "What are you building?"
  → PM web searches the domain
  → PM notes: project name, core purpose

Q2: "Who uses it?"
  → PM web searches user personas for this domain
  → PM notes: user types, access patterns

Q3: "What's the main problem it solves?"
  → PM web searches existing solutions in this space
  → PM presents: "I found [competitors]. Your gap is [X]. Sound right?"

Q4: "Tech preferences? Or should I recommend?"
  → If recommend: PM checks proven stacks FIRST:
    Run: `bash ~/.claude/scripts/forge-stack.sh list`
    Stacks with learnings > 0 are PROVEN (battle-tested from past builds).
    Stacks with learnings = 0 are AVAILABLE (registered but untested).
    PM presents: "Based on your project needs and our proven stacks:
      RECOMMENDED: {stack} — {N} learnings from {N} past builds
      Also available: {other stacks}
      Or I can research a new stack for this project."
    Proven stacks get priority because their rules/agents/scaffold have been refined.
  → If user specifies a stack: use that (user choice overrides recommendation)
  → PM notes: language, framework, database, cache, frontend, special features
  → STACK REGISTRY: Check ~/.claude/stacks/ for available stacks (ls ~/.claude/stacks/)
    If stack matches a registry folder (e.g., "django", "fastapi"):
    - Read ~/.claude/stacks/{stack}/rules.md → will be copied to project .claude/rules/
    - Read ~/.claude/stacks/{stack}/agents.md → will be used for agent-routing.md
    - Read ~/.claude/stacks/{stack}/learnings.md → include in agent prompts as context
    - Read ~/.claude/stacks/{stack}/scaffold.md → use for Step S7 scaffold
    If no match → AUTO-CREATE the stack registry:
      Run: `bash ~/.claude/scripts/forge-stack.sh create {stack} --auto`
      This creates ~/.claude/stacks/{stack}/ with template files.
      @system-architect will refine them during S3/S6 using context7 docs.
      After this build's /retro (Step 49), the templates get real learnings.
      Second build on this stack will be fully informed.

Q5: "Any of these apply?" (multi-select)
  - Multi-tenant
  - AI/LLM features
  - File uploads
  - Real-time features
  - Background jobs
  - Authentication

Q6: "What should it NEVER include?"
  → PM notes: anti-scope list

Q7: "Confirm everything:"
  ```
  PROJECT: [name]
  USERS: [who]
  PROBLEM: [what]
  STACK: [tech]
  FEATURES: [list]
  SPECIAL: [multi-tenant, AI, etc.]
  EXCLUDED: [list]
  ```
  "Correct? (yes / change)"

On confirm → proceed to STEP S3

**STEP S3: GENERATE CLAUDE.md** → @system-architect agent

Execute: spawn Agent with subagent_type="system-architect"
  prompt: |
    Generate CLAUDE.md for a new project. Follow these rules STRICTLY:

    PROJECT INFO (from discovery):
    - Name: {name}
    - Description: {description}
    - Stack: {stack}
    - Features: {features}
    - Excluded: {excluded}

    TEMPLATE (MUST follow this structure — under 100 lines):
    ```
    # {project_name}

    {one_line_description}

    ## Tech Stack

    | Layer | Technology | Notes |
    |---|---|---|
    {rows from stack choices — include version + "NOT X" exclusions}

    ## Architecture Rules

    <system-reminder>
    These rules override your defaults. Re-read before every task.
    </system-reminder>

    {numbered rules, MUST/NEVER format, with code snippets}
    RULES MUST INCLUDE (based on stack):
    - For Django: "Django Ninja for ALL API — NEVER import rest_framework"
    - For Django: "uv for packages — NEVER pip install"
    - For Django: "Run tests after EVERY change: uv run python manage.py test"
    - For multi-tenant: "TenantMainMiddleware MUST be position 0"
    - For multi-tenant: "Database MUST be django_tenants.postgresql_backend"
    - For AI/LLM: "LLM output MUST be sanitized with strip_tags() before storage"
    - For S3: "Presigned URLs expire after 15 minutes — NEVER serve files directly"
    - For all: "All credentials from os.environ — NEVER hardcoded"
    - Add stack-specific rules based on research

    ## What NOT to Build

    {bullet list from excluded items}

    ## Testing

    - {test command based on stack}
    - {lint command based on stack}
    - {test base class rule if applicable}

    ## Lessons Learned

    <!-- Updated by /retro. Each rule prevents a real past mistake. -->
    ```

    OUTPUT REQUIREMENTS:
    - Under 100 lines
    - Every rule is MUST or NEVER (no "prefer" or "consider")
    - Include code snippets where applicable
    - Tables for structured data
    - Anti-scope list from user's "NEVER include" answer

Verify: `wc -l CLAUDE.md` → under 100 lines
Verify: `grep -c "MUST\|NEVER" CLAUDE.md` → at least 5 binary rules
Verify: has ## Tech Stack, ## Architecture Rules, ## What NOT to Build, ## Testing sections
Trace: save to docs/forge-trace/S3-claude-md/

**STEP S4: GENERATE SPEC.md** → @requirements-analyst agent

Execute: spawn Agent with subagent_type="requirements-analyst"
  prompt: |
    Generate SPEC.md for the project. Follow templates/SPEC.template.md STRICTLY.

    PROJECT INFO:
    - Name: {name}
    - Stack: {stack}
    - Features: {features}
    - Users: {users}

    REQUIREMENTS:
    - Start from [REQ-001]
    - Every feature gets at least 2-3 requirements
    - Each requirement has ONE clear behavior (not compound)
    - Use domain-prefixed IDs where possible (REQ-AUTH-001, REQ-UI-001)
    - Include non-functional requirements (performance, security, observability)

    SPEC MUST INCLUDE:
    - ## Overview (2-3 paragraphs)
    - ## Tech Stack (table matching CLAUDE.md)
    - ## Architecture (project structure tree)
    - ## Models (with field types, relationships, constraints)
      - Each model tagged with [REQ-xxx]
      - Field types are EXACT (CharField(max_length=200), not just "string")
    - ## API Endpoints (table: method, path, auth, description, [REQ-xxx])
    - ## Frontend Pages (if applicable)
    - ## Requirements Traceability (table: [REQ-xxx] | description | status)

    Minimum 20 [REQ-xxx] tags.

Verify: `grep -c "REQ-" SPEC.md` → at least 20
Verify: has ## Models, ## API Endpoints, ## Requirements Traceability sections
Trace: save to docs/forge-trace/S4-spec-md/

**STEP S5: GENERATE FORGE.md** → PM (simple, no agent needed)

PM writes FORGE.md from template:
```markdown
# FORGE.md — Work Queue

## Active
<!-- Currently being worked on -->

## Queued
- type: NEW_PROJECT
  description: {project description from discovery}
  status: QUEUED
  created: {today's date}

## Done
<!-- Completed items -->
```

Verify: file exists with QUEUED entry
Trace: save to docs/forge-trace/S5-forge-md/

**STEP S6: GENERATE .claude/rules/** → PM + @system-architect agent

```bash
mkdir -p .claude/rules/
```

**STACK REGISTRY CHECK** (do this FIRST):
```bash
STACK_DIR="$HOME/.claude/stacks/{stack}"  # e.g., django, fastapi, nextjs
if [ -d "$STACK_DIR" ]; then
  # Copy stack rules into project
  cp "$STACK_DIR/rules.md" .claude/rules/{stack}-rules.md
  # Use stack agent routing as base for agent-routing.md
  STACK_AGENTS=$(cat "$STACK_DIR/agents.md")
  # Read stack learnings — include in all agent prompts this build
  STACK_LEARNINGS=$(cat "$STACK_DIR/learnings.md")
  # Read stack scaffold instructions for Step S7
  STACK_SCAFFOLD=$(cat "$STACK_DIR/scaffold.md")
fi
```

If stack registry exists: use agents.md as the base for agent-routing.md (customize for this project's specific apps).
If no registry: fall back to @system-architect generating from scratch (below).

For sdlc-flow.md: PM fills the template with project-specific stages.

For agent-routing.md: If stack registry provided agents.md, adapt it to this project's app structure.
Otherwise, @system-architect fills the agent matrix based on stack:

Execute: spawn Agent with subagent_type="system-architect"
  prompt: |
    Create .claude/rules/agent-routing.md for this project.

    Stack: {stack}
    Features: {features}

    IMPORTANT: Check if ~/.claude/stacks/{stack}/agents.md exists.
    If YES: use it as the BASE template, adapt for this project's specific apps/folders.
    If NO: create from scratch using the mappings below.

    Fill the agent matrix table:
    | Domain | Files | Agent | context7 Libraries |

    Default mappings (only if no stack registry):
    - Django models → @django-tenants-agent (if multi-tenant) or @backend-architect
    - Django API → @django-ninja-agent
    - FastAPI → @backend-architect (or @agent-factory creates one)
    - S3/Lambda → @s3-lambda-agent
    - AI/LLM → @llm-integration-agent
    - Frontend templates → /sc:implement
    - React/Next.js → @frontend-architect
    - Auth → @django-ninja-agent or stack-specific agent
    - Infrastructure → @devops-architect
    - AWS → @aws-setup-agent
    - GCP → @gcp-setup-agent

Verify: agent-routing.md has at least 3 rows in table
Trace: save to docs/forge-trace/S6-rules/

**STEP S7: GENERATE scaffold** → @devops-architect agent

Execute: spawn Agent with subagent_type="devops-architect"
  prompt: |
    Create project scaffold for {stack}.
    Read CLAUDE.md for rules. Read ~/.claude/rules/docker.md for Docker rules.
    Follow the Docker rules file — it covers volume mounts, dev vs prod, .dockerignore.
    Generate REAL files:

    For Django:
    - pyproject.toml (all deps from CLAUDE.md tech stack)
    - Dockerfile (Python 3.12, multi-stage, uv — production with gunicorn)
    - docker-compose.yml (PostgreSQL + Redis + Django — DEVELOPMENT with volume mount + runserver)
    - .dockerignore (.venv, __pycache__, .git, *.pyc)
    - config/settings.py (full Django settings)
    - config/urls.py
    - config/wsgi.py
    - manage.py
    - apps/__init__.py
    - .env.example
    - .gitignore

    For FastAPI:
    - pyproject.toml
    - Dockerfile
    - docker-compose.yml (with volume mount + uvicorn --reload for dev)
    - .dockerignore
    - app/main.py
    - app/config.py
    - .env.example
    - .gitignore

    For Next.js:
    - package.json
    - Dockerfile
    - docker-compose.yml (with volume mount + next dev for dev)
    - .dockerignore
    - next.config.js
    - .env.example
    - .gitignore

Verify: key files exist (pyproject.toml OR package.json, Dockerfile, docker-compose.yml)
Trace: save to docs/forge-trace/S7-scaffold/

**STEP S8: GENERATE hooks** → PM (copies template)

```bash
cp templates/hooks.json .claude/settings.json
```

Verify: .claude/settings.json exists and is valid JSON
Trace: save to docs/forge-trace/S8-hooks/

**STEP S9: REVIEW all generated files** → @reviewer agent

Execute: spawn Agent with subagent_type="self-review"
  prompt: |
    Review all generated files for this new project:
    1. CLAUDE.md — under 100 lines? Real rules? MUST/NEVER format? Code snippets?
    2. SPEC.md — at least 20 [REQ-xxx]? Models have field types? API endpoints listed?
    3. FORGE.md — has QUEUED entry?
    4. .claude/rules/ — SDLC flow complete? Agent routing filled?
    5. Scaffold — settings.py valid? Dependencies listed? Dockerfile works?
    6. .claude/settings.json — valid JSON? Hooks defined?

    Rate each 1-5. Report any issues.

Verify: all ratings >= 4
If any < 4 → fix → re-review
Trace: save to docs/forge-trace/S9-review/

**STEP S10: COMMIT + DONE**

```bash
git add -A
git commit -m "init: scaffold project with forge"
```

Output to user:
```
Setup complete!

Created:
  CLAUDE.md           — {N} lines, {N} architecture rules
  SPEC.md             — {N} [REQ-xxx] requirements
  FORGE.md            — 1 QUEUED item ready
  .claude/rules/      — SDLC flow + agent routing
  .claude/settings.json — hooks for lint + safety + flow detection
  Scaffold            — {list of files}

Next: exit Claude Code, then run `forge` again in this folder.
Session 2 will load CLAUDE.md and start building.
```

---

**STEP S5-BROWNFIELD: REVERSE-ENGINEER** (when code exists, no CLAUDE.md)

<system-reminder>
This project has code but was NOT built with Forge. Do NOT create requirements from scratch.
The requirements ALREADY EXIST in the code. You must DISCOVER them first.
NEVER ask "what are you building?" — the code TELLS you what was built.
</system-reminder>

Execute: spawn Agent with subagent_type="repo-index"
  prompt: "Index {project folder}. Report: language, framework, file count, models found, endpoints found, tests found."
Verify: index report exists

Execute: spawn Agent with subagent_type="requirements-analyst"
  prompt: "Reverse-engineer requirements from existing code. Read models → data requirements. Read API → functional requirements. Read tests → verified behaviors. Output [REQ-xxx] tags."
Verify: at least 10 [REQ-xxx] from existing code

Execute: spawn Agent with subagent_type="system-architect"
  prompt: "Generate CLAUDE.md from existing codebase. Read pyproject.toml/package.json for stack. Read config for settings. Extract patterns as rules."
Verify: CLAUDE.md has real stack, real rules

Then → STEP S5 (FORGE.md) → S6 → S7 (skip scaffold, code exists) → S8 → S9 → S10

#### Phase B -- Full SDLC (CHAINED EXECUTION — each step MUST complete before next)

<system-reminder>
CHAINED EXECUTION PROTOCOL — ENFORCED BY HOOKS AND SCRIPTS:

BEFORE ANYTHING: Run `bash scripts/forge-enforce.sh check-state` to load current state.
BEFORE ANYTHING: Run `bash scripts/forge-enforce.sh check-continuation` to find the NEXT step.
BEFORE ANYTHING: Run `bash scripts/docker-state.sh` to capture Docker state.

RESUME LOGIC — CRITICAL:
  Read docs/forge-state.json. For each step:
  - If status = "DONE" → SKIP IT. Do not re-run completed steps.
  - If status = "SKIPPED" → Note as historical violation. Do not re-run unless user asks.
  - If status = "NOT_STARTED" → EXECUTE this step.
  - If status = "IN_PROGRESS" → RESUME this step.
  The check-continuation command tells you the EXACT next step. Start there.

RETROACTIVE GATES — When phases are DONE but gates never ran:
  The gate only needs to VERIFY (run checks), not REDO work.
  Run: tests pass + lint clean + traceability pass + Docker healthy + no secrets.
  If all pass → mark gate passed with `forge-enforce.sh update-gate <N>`.
  Do NOT re-run the phase's work steps.

Each step below MUST be executed using the Skill tool (for commands) or Agent tool (for agents).
After EACH step:
  1. VERIFY the output file exists (use Read or Bash ls)
  2. VERIFY it has real content (not empty, not placeholder)
  3. LOG to docs/forge-trace/{NNN}-{step}/ — ALL 3 FILES: input.md + output.md + meta.md
  4. VERIFY trace: `bash scripts/forge-enforce.sh check-trace <STEP_NUMBER>`
  5. LOG to docs/forge-timeline.md
  6. UPDATE state: `bash scripts/forge-enforce.sh update-step <STEP_NUMBER> DONE`
  7. ONLY THEN proceed to next step

PHASE TRANSITIONS — HARD GATE:
  Before starting Phase N, you MUST verify Phase N-1 gate passed:
  `bash scripts/forge-enforce.sh check-gate <N-1>`
  If NOT passed → run /gate phase-<N-1> → verify → THEN proceed.
  NEVER skip a gate. NEVER proceed without a passing gate.

AGENT SEPARATION — ENFORCED:
  PM (you) NEVER writes to apps/**/*.py or templates/**/*.html
  Always spawn the specialist agent from .claude/rules/agent-routing.md
  Hook will warn if you attempt to write app code directly.

AUTO-CONTINUATION — MANDATORY:
  NEVER stop to ask "should I continue?" — always continue.
  NEVER ask which agent to use — consult agent-routing.md.
  ONLY stop for: gate BLOCKED, /challenge RETHINK, missing credentials, 3 failed retries.

If verification FAILS → retry the step (max 2) → still fails → STOP and report.
If a step produces no output file → the step did NOT run → DO NOT PROCEED.

You are EXECUTING these commands, not describing them.
Use the Skill tool: `skill: "discover"` or `skill: "requirements"` etc.
Use the Agent tool for specialist agents: `subagent_type: "security-engineer"` etc.

ON CONTEXT LIMIT: Save state with forge-enforce.sh, summarize in timeline, continue immediately.
ON SESSION RESTART: Run `bash scripts/forge-enforce.sh check-continuation` to find next step.
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
ENFORCEMENT CHECKPOINT — BEFORE Phase 3:
1. Run: `bash scripts/forge-enforce.sh check-gate 2` — Phase 2 gate MUST be passed
2. Run: `bash scripts/forge-enforce.sh check-docker` — all services MUST be healthy
3. Run: `bash scripts/docker-state.sh` — capture Docker state for agent prompts
4. If any check fails → FIX FIRST → do NOT proceed

STRICT AGENT SEPARATION — MANDATORY AND ENFORCED:
- SPEC agent and CODE agent are DIFFERENT agents
- TEST agent and CODE agent are DIFFERENT agents
- TEST agent reads SPEC (not code) to write tests
- CODE agent reads SPEC + design doc + test expectations to write code
- REVIEW agent judges every output independently
- NO agent does more than ONE job per step
- PM NEVER writes to apps/**/*.py — Hook will warn on violation

AGENT ROUTING (from .claude/rules/agent-routing.md):
- apps/tenants/ → @django-tenants-agent
- apps/users/ → @django-ninja-agent
- apps/search/ → @backend-architect
- apps/documents/ → @s3-lambda-agent + @django-ninja-agent
- apps/conversations/ → @llm-integration-agent + @s3-lambda-agent
- apps/audit/ → @django-tenants-agent
- templates/ → /sc:implement
- tests → @quality-engineer (reads SPEC.md ONLY)

TDD CYCLE — MANDATORY:
1. @quality-engineer writes tests from SPEC.md → tests MUST FAIL
2. @domain-agent writes code → tests MUST PASS
3. Full suite → NO regressions
If tests pass at step 1 → INVESTIGATE before coding

PER-ISSUE COMMITS — MANDATORY:
Each issue = one commit: `feat(<app>): <description> [REQ-xxx]`
NEVER batch multiple issues into one monolithic commit.

This prevents:
- Tests that are designed to pass (written after code)
- Specs that are reverse-engineered from implementation
- Code that ignores the spec because same agent wrote both
- Monolithic commits that are impossible to review or revert
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

STEP N8 — REVIEW (per-issue inline review — MANDATORY)
  Execute: spawn Agent with subagent_type="reviewer"
    prompt: "Review code for issue #{N}. Rate 1-5.
    CHECK: tests cover [REQ-xxx] acceptance criteria, code matches spec, no orphan code,
    no hardcoded secrets, files <300 lines, no TODO/FIXME, error paths handled,
    auth checks on protected routes, LLM output sanitized.
    If rating <4: list EXACT fixes needed. If >=4: approve."
  Verify: rating >= 4
  If < 4: fix issues → re-run review (max 3 iterations)
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

STEP 37 — /review (phase-level inline code review — MANDATORY before gate)
  Execute: `skill: "review", args: "all changes since last gate"`
  This reviews ALL code written in Phase 3 as a whole:
    - Cross-issue consistency (naming, patterns, imports)
    - API contract alignment with design-doc.md Section 4
    - Tenant isolation across all apps
    - No duplicate logic between issues
    - Test coverage gaps across the full suite
  Verify: review produces report with 0 CRITICAL, 0 HIGH findings
  If issues found: fix → re-run review
  Execute: `bash scripts/forge-enforce.sh update-step 37 DONE`
  Trace: save to docs/forge-trace/037-review-s3/

STEP 38 — /checkpoint phase-3
  Execute: `skill: "checkpoint", args: "phase-3 | Implementation complete"`
  Execute: `bash scripts/forge-enforce.sh update-step 38 DONE`
  Trace: save to docs/forge-trace/038-checkpoint-s3/

STEP 39 — /gate stage-3 (MANDATORY — blocks Phase 4)
  Execute: `skill: "gate", args: "stage-3"`
  Verify: gate PASS
  Execute: `bash scripts/forge-enforce.sh update-gate 3`
  Execute: `bash scripts/forge-enforce.sh update-step 39 DONE`
  If FAIL → fix issues → re-run /gate
  Trace: save to docs/forge-trace/039-gate-s3/

  **PHASE 3→4 TRANSITION:**
  1. Verify: `bash scripts/forge-enforce.sh check-gate 3` → MUST be PASSED
  2. Verify: `bash scripts/docker-state.sh --check` → DOCKER_HEALTHY
  3. Run: `bash scripts/run-e2e.sh` → unit + e2e tests MUST pass
  4. Update: `bash scripts/forge-enforce.sh update-step 40 IN_PROGRESS`
  5. Continue to Phase 4 immediately — DO NOT STOP

**Phase 4: Validate**

<system-reminder>
ENFORCEMENT CHECKPOINT — BEFORE Phase 4:
1. Run: `bash scripts/forge-enforce.sh check-gate 3` — Phase 3 gate MUST be passed
2. Run: `bash scripts/forge-enforce.sh check-docker` — Docker MUST be healthy
3. Run: `bash scripts/run-e2e.sh` — ALL tests (unit + e2e) MUST pass before validation
4. Update state: `bash scripts/forge-enforce.sh update-step 40 IN_PROGRESS`
5. If gate not passed → run /gate stage-3 first → THEN proceed
AUTO-CONTINUE: Do NOT stop to ask the user. Proceed through ALL Phase 4 steps.
</system-reminder>

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

STEP 45 — /design-audit + /critic + E2E TESTS (MANDATORY if project has UI)
  Execute: `skill: "design-audit"` (if templates/ exist)
  Execute: `skill: "critic"` (if Playwright available)
  Execute: `skill: "sc:test", args: "--type e2e"` — MANDATORY, run Playwright e2e tests
  Execute: `docker compose exec web uv run python manage.py test` — MANDATORY, full unit test suite
  Verify: ALL tests pass (both unit and e2e)
  Trace: save to docs/forge-trace/045-design/

STEP 45b — /review (Phase 4 validation review — MANDATORY before gate)
  Execute: `skill: "review", args: "validation findings"`
  Review all fixes made during Phase 4 (from audit-patterns, security-scan, etc.)
  Verify: no regressions introduced by fixes, all tests still pass
  Execute: `bash scripts/forge-enforce.sh update-step 45 DONE`

STEP 46 — /gate stage-4
  Execute: `skill: "gate", args: "stage-4"`
  Verify: gate PASS
  Execute: `bash scripts/forge-enforce.sh update-step 46 DONE`
  Execute: `bash scripts/forge-enforce.sh update-gate 4`
  Trace: save to docs/forge-trace/046-gate-s4/

**Phase 5: Review + Learn**

<system-reminder>
ENFORCEMENT CHECKPOINT — BEFORE Phase 5:
1. Run: `bash scripts/forge-enforce.sh check-gate 4` — Phase 4 gate MUST be passed
2. Update state: `bash scripts/forge-enforce.sh update-step 47 IN_PROGRESS`
AUTO-CONTINUE: Do NOT stop. Execute ALL steps 47-56 without pausing.
</system-reminder>

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
  STACK LEARNING FEEDBACK: After retro, append new learnings to the stack registry:
    ```bash
    STACK=$(grep -oP 'framework.*?:\s*\K\w+' CLAUDE.md | head -1 | tr '[:upper:]' '[:lower:]')
    STACK_LEARNINGS="$HOME/.claude/stacks/$STACK/learnings.md"
    if [ -f "$STACK_LEARNINGS" ]; then
      echo "" >> "$STACK_LEARNINGS"
      echo "## From $(basename $(pwd)) ($(date +%Y-%m-%d))" >> "$STACK_LEARNINGS"
      # Append each new lesson from retro that is stack-specific (not process-related)
    fi
    ```
    Read docs/retrospectives/*.md → extract stack-specific lessons → append to ~/.claude/stacks/{stack}/learnings.md
    This makes the NEXT build on this stack smarter.
  Trace: save to docs/forge-trace/049-retro/

STEP 50 — /sc:reflect
  Execute: `skill: "sc:reflect"`
  Verify: task completion validated
  Trace: save to docs/forge-trace/050-reflect/

STEP 51 — /sc:document + @deploy-guide-agent
  Execute: `skill: "sc:document"`
  Execute: spawn Agent with subagent_type="general-purpose"
    prompt: "You are @deploy-guide-agent. Read CLAUDE.md, docker-compose.yml, Dockerfile, .env.example. Generate docs/DEPLOY.md with: prerequisites, quick-start (Docker exists vs not), env vars table, services table, common operations, making changes, troubleshooting, architecture diagram, health checks. Every command must be copy-pasteable. Under 200 lines."
  Verify: `ls docs/DEPLOY.md` → exists and has ## Quick Start section
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

Routes to CASE 1, Phase A, STEP S1 → STEP S5-BROWNFIELD.

The brownfield flow is embedded in CASE 1's Phase A. When STEP S1 (ASSESS) detects
"Code exists, no CLAUDE.md", it jumps to STEP S5-BROWNFIELD which:

1. @repo-index agent indexes the codebase (language, framework, models, endpoints, tests)
2. @requirements-analyst agent reverse-engineers [REQ-xxx] from existing code
3. @system-architect agent generates CLAUDE.md from actual patterns
4. Then continues: S5 (FORGE.md) → S6 (rules) → S7 (skip scaffold) → S8 (hooks) → S9 (review) → S10 (commit)

After setup completes, present to user:
```
I've analyzed your project:
- Tech: [stack]
- Models: [count] ([list])
- Endpoints: [count]
- Tests: [count]
- Requirements: [count] reverse-engineered

What would you like to do next?
(a) Add a new feature
(b) Fix a bug
(c) Improve something
```
Route to CASE 3/4/5 based on answer

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

### CASE 8: VIOLATION REMEDIATION (auto-fix — NO user interaction)

<system-reminder>
CASE 8 IS FULLY AUTONOMOUS. Do NOT ask the user anything.
Read violations from forge-state.json. Fix each one. Update state. Continue.
This case runs when: forge-state.json exists AND violations array is non-empty.
PRIORITY ORDER: gates > review > Phase 5 steps > traces > checkpoints.
</system-reminder>

**STEP R1: Read violations and categorize**

```bash
bash scripts/forge-enforce.sh check-state
bash scripts/forge-enforce.sh check-continuation
bash scripts/forge-review-guard.sh status
```

Categorize violations by type:
- GATE_SKIPPED → run retroactive gates (verify only, don't redo work)
- REVIEW_SKIPPED → run /review now
- PHASE5_BATCH_SKIPPED → re-run skipped Phase 5 skills properly
- CHECKPOINT_SKIPPED → run /checkpoint for the phase
- TRACE_INCOMPLETE → backfill missing input.md/output.md
- AGENT_SEPARATION → log as historical (can't undo, note for future)
- TDD_SKIPPED → log as historical (can't undo, note for future)

**STEP R2: Fix gate violations (highest priority)**

For each phase with gate_passed = false AND status = DONE:
1. Run verification: tests pass + lint clean + traceability + Docker healthy + no secrets
2. If ALL pass → `bash scripts/forge-enforce.sh update-gate <phase>`
3. If ANY fail → fix the issue → re-verify → mark gate
4. Continue to next ungated phase

**STEP R3: Fix review violations**

If REVIEW_SKIPPED in violations:
1. Run `/review` (the skill) — this triggers PostToolUse hook that marks phase as reviewed
2. Fix any issues found
3. Commit fixes
4. Review guard marker is now set → gate and PR unblocked

**STEP R4: Fix Phase 5 batch-skip violations**

If PHASE5_BATCH_SKIPPED in violations:
For each step that was batch-marked without execution:
- Step 47: Run `skill: "sc:cleanup"` → verify no regressions
- Step 48: Run `skill: "sc:improve"` → verify tests still pass
- Step 49: Run `skill: "retro"` → verify retrospective file created
- Step 50: Run `skill: "sc:reflect"` → verify reflection report
- Step 51: Run `skill: "sc:document"` + @deploy-guide-agent → verify docs/DEPLOY.md
- Step 52: Run @playbook-curator → verify playbook updated
- Step 53: Run `skill: "prune"` + `skill: "evolve"`
- Step 54: Run `skill: "autoresearch"`
- Step 55: Run `skill: "sc:save"`

Each step: execute → verify output → update forge-state.json → trace.

**STEP R5: Fix checkpoint violations**

For each skipped checkpoint:
Run `skill: "checkpoint", args: "phase-<N> | retroactive checkpoint"`

**STEP R6: Fix trace violations**

For each step with trace_complete = false:
Backfill input.md and output.md from git history and forge-timeline.md.

**STEP R7: Handle CodeRabbit reviews on existing PRs**

```bash
# Check if any open PRs have CodeRabbit reviews
PR_NUM=$(gh pr list --state open --json number -q '.[0].number' 2>/dev/null)
if [ -n "$PR_NUM" ]; then
  REVIEWS=$(gh api repos/{owner}/{repo}/pulls/$PR_NUM/reviews \
    --jq '[.[] | select(.user.login | contains("coderabbit"))] | length' 2>/dev/null)
  COMMENTS=$(gh api repos/{owner}/{repo}/pulls/$PR_NUM/comments \
    --jq '[.[] | select(.user.login | contains("coderabbit"))] | length' 2>/dev/null)
fi
```

If CodeRabbit has reviewed (REVIEWS > 0):
1. Read ALL CodeRabbit comments
2. For each comment:
   - Read the file + line
   - Understand the suggestion
   - Apply fix using correct specialist agent (from agent-routing.md)
   - Run tests → verify no regression
3. Commit: `fix: address CodeRabbit review [iteration N]`
4. Push
5. Wait for re-review (poll 30s x 10)
6. Repeat until APPROVED or 5 iterations

If CodeRabbit state = APPROVED:
- Mark PR as ready
- Log to timeline

If no CodeRabbit after 5 min:
- Fall back to local verification checklist
- Log: "CodeRabbit unavailable"

**STEP R8: Clear resolved violations from state**

```python
# Remove violations that have been fixed
for v in violations:
    if v resolved: remove from list
state["violations"] = remaining_violations
state["status"] = "CLEAN" if no violations else "VIOLATIONS_REMAINING"
```

**STEP R9: Final verification**

```bash
bash scripts/forge-enforce.sh full-audit
```

If AUDIT PASSED → log "All violations resolved" → check FORGE.md for queued items → if none, report done.
If AUDIT FAILED → loop back to R1 (max 3 iterations) → if still failing, report remaining issues to user.

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
