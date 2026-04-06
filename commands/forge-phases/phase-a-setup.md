### CASE 1: NEW PROJECT (no CLAUDE.md or placeholder CLAUDE.md)

#### Phase A — Setup (Session 1: creates all files agents need)

<!-- Architecture: PM behaviors (self-correction, anti-patterns, confidence routing,
     chaos resilience) are auto-loaded from rules/pm-behaviors.md via Pipe 1.
     This file contains only the TASK STEPS (what to do), not PM behaviors (how to behave). -->

<system-reminder>
SESSION 1 RULES:
- PM behaviors auto-loaded from rules/pm-behaviors.md (self-correction, anti-patterns, handoff protocol)
- PM orchestrates but NEVER writes CLAUDE.md or SPEC.md directly (FORGE.md is simple enough for PM)
- Each file is built by a SPECIALIST AGENT following a TEMPLATE
- Every agent output is VERIFIED before proceeding (rate >= 4, retry if < 4, max 3)
- Session 1 ends with "Setup complete. Run forge again to build."
- NO CODE IS WRITTEN in Session 1 — only planning/spec/config files
</system-reminder>

**STEP S1: PREPARE** (PM prepares workspace — no agents)

NOTE: Project type detection (GREENFIELD/BROWNFIELD/EXISTING) was already done by the UserPromptSubmit hook before reaching this file. S1 does NOT re-detect — it only prepares the workspace.

```bash
# 1. Ensure git repo (user may have forgotten git init)
if [ ! -d ".git" ]; then
    git init -b main
    echo "[FORGE] Initialized git repository"
fi

# 2. Create directories needed by S3-S9
mkdir -p docs/forge-trace docs/proposals docs/retrospectives

# 3. Check for partial setup (Phase A was interrupted previously)
# If CLAUDE.md exists but SPEC.md or .forge/ is missing → resume from missing step
```

Based on partial setup check:
- Nothing exists → continue to STEP S2 (full setup)
- CLAUDE.md exists but no SPEC.md → resume at S4
- CLAUDE.md + SPEC.md but no scaffold → resume at S7
- Incomplete setup (CLAUDE.md but missing .forge/) → resume from missing step
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
  → If competitors found: PM presents: "I found [competitors]. Your gap is [X]. Sound right?"
  → If no competitors found (niche/private domain): skip competitor framing, proceed to Q4

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
  → For full-stack projects: ask backend AND frontend stacks separately
    Example: "Backend: Django + Django Ninja, Frontend: React + Tailwind"
    Both stacks get registered — run registry lookup for EACH stack independently
  → STACK REGISTRY: For EACH stack, check ~/.claude/stacks/ (ls ~/.claude/stacks/)
    If stack matches a registry folder (e.g., "django", "fastapi", "react"):
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

On "change" → ask "Which answer do you want to change? (1-6)"
  → re-ask that specific question
  → update the summary
  → re-confirm Q7

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

Verify: `wc -l CLAUDE.md` → at least 20 lines, under 100 lines (too short = missing rules)
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
  created: $(date +%Y-%m-%d)

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
    - conftest.py (test configuration)
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
    - tsconfig.json (TypeScript config)
    - .env.example
    - .gitignore

Verify: key files exist (pyproject.toml OR package.json, Dockerfile, docker-compose.yml)
Trace: save to docs/forge-trace/S7-scaffold/

**STEP S8: GENERATE project infrastructure** → PM (no agent needed)

PM creates all project infrastructure that /forge needs to operate:

```bash
# 1. Hooks (ALL 8 — auto-continue, state tracking, safety, linting)
mkdir -p .claude
cp ~/.claude/templates/hooks.json .claude/settings.json

# 2. Forge local directory (playbook, rules, agents, checkpoints)
mkdir -p .forge/playbook .forge/rules .forge/agents .forge/checkpoints

# 3. Playbook files
cat > .forge/playbook/strategies.md << 'EOF'
# Playbook — Strategies & Insights
# Format: [str-NNN] helpful=N harmful=N :: insight text
## STRATEGIES & INSIGHTS
## COMMON MISTAKES TO AVOID
## DOMAIN-SPECIFIC
EOF

cat > .forge/playbook/mistakes.md << 'EOF'
# Playbook — Mistakes
# Format: [mis-NNN] :: description + root cause + prevention
EOF

cat > .forge/playbook/archived.md << 'EOF'
# Playbook — Archived
# Pruned entries (harmful > helpful) are moved here.
EOF

# 4. Project-specific rules
cat > .forge/rules/project.md << 'EOF'
# Project-Specific Rules
# Rules that apply ONLY to this project. Global rules are in ~/.claude/rules/
EOF

# 5. Forge local gitignore
cat > .forge/.gitignore << 'EOF'
checkpoints/
EOF

# 6. Docs structure
mkdir -p docs/forge-trace docs/proposals docs/retrospectives docs/checkpoints docs/issues

# 7. Forge timeline
cat > docs/forge-timeline.md << EOF
# Forge Timeline -- $(basename "$PWD")
This file tracks every step of the development process.
Updated automatically by /forge and all Forge commands.

## Legend
- DONE -- step completed successfully
- NEEDS_REVIEW -- output needs human review
- BLOCKED -- step failed, needs attention
- IN_PROGRESS -- currently running

---
<!-- Timeline entries appear below, newest first -->
EOF

# 8. Copy utility scripts
mkdir -p scripts
cp ~/.claude/scripts/traceability.sh scripts/ 2>/dev/null || true
cp ~/.claude/scripts/sync-report.sh scripts/ 2>/dev/null || true
chmod +x scripts/*.sh 2>/dev/null || true

# 9. Install git hooks (enforces issue-first workflow + REQ impact analysis)
cp ~/.claude/templates/commit-msg .git/hooks/commit-msg 2>/dev/null || true
cp ~/.claude/templates/pre-commit .git/hooks/pre-commit 2>/dev/null || true
chmod +x .git/hooks/commit-msg .git/hooks/pre-commit 2>/dev/null || true
```

Verify: .claude/settings.json exists and is valid JSON
Verify: .forge/playbook/ exists with 3 files
Verify: docs/forge-timeline.md exists
Trace: save to docs/forge-trace/S8-infrastructure/

**STEP S9: REVIEW all generated files** → @reviewer agent

Execute: spawn Agent with subagent_type="self-review"
  prompt: |
    Review all generated files for this new project:
    1. CLAUDE.md — under 100 lines? Real rules? MUST/NEVER format? Code snippets?
    2. SPEC.md — at least 20 [REQ-xxx]? Models have field types? API endpoints listed?
    3. FORGE.md — has QUEUED entry?
    4. .claude/rules/ — SDLC flow complete? Agent routing filled?
    5. Scaffold — settings.py valid? Dependencies listed? Dockerfile works?
    6. .claude/settings.json — valid JSON? Has all 9 hook groups (SessionStart, Stop, UserPromptSubmit, PreToolUse x2, PostToolUse x4)?
    7. .forge/playbook/ — strategies.md, mistakes.md, archived.md exist?
    8. docs/forge-timeline.md — exists with project name?

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

**FAILURE RECOVERY:** If Phase A fails mid-way:
- Run `bash ~/.claude/scripts/forge-infra-check.sh --reset` to clear state and restart fresh
- Or fix the issue and run `/forge` again — S1 will detect partial setup and resume

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

If repo-index detects multiple frameworks (e.g., Django backend + React frontend):
  → PM asks: "I found both [X] and [Y]. Which should I focus on?"
  → User picks → agent-routing.md targets that framework

Then → STEP S5 (FORGE.md) → S6 → S7 (brownfield: skip scaffold but check for missing Dockerfile/docker-compose — add only missing infra files) → S8 → S9 → S10

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

