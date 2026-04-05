# /build-project — Full SDLC Orchestrator

Runs the ENTIRE project build flow autonomously. From SPEC to deployed app. Delegates everything to specialist agents via /run-with-checkpoint. Uses /gate at every stage boundary. Never writes code directly — only orchestrates.

## Input
$ARGUMENTS — path to SPEC file (e.g., ~/projects/clinic-portal/SPEC.md)

## Orchestration Rules

<system-reminder>
You are the ORCHESTRATOR. You NEVER write application code yourself.
You ONLY: read specs, delegate to agents, evaluate output, run gates, manage GitHub Issues.
Every agent execution goes through /run-with-checkpoint.
Every stage boundary goes through /gate.
If an agent's output fails checkpoint eval, fix the agent prompt and re-run.
If /gate blocks (CodeRabbit has suggestions), fix and re-submit.
You do NOT stop until the app is built, tested, and merged — or you hit a blocker that needs human input (credentials, account access, etc.).
</system-reminder>

## The Flow

### STAGE 1: SPECIFY
```
1. Read $ARGUMENTS (the SPEC file)
2. Read CLAUDE.md (if exists — if not, create it in Stage 2)
3. Run: /specify $ARGUMENTS
   → Produces: docs/proposals/NN-name.md + GitHub Issues
4. Run: /checkpoint specify | "feature proposal from SPEC"
5. Run: /gate stage-1-specify
   → Must pass: audit + CodeRabbit 0 suggestions
```

### STAGE 2: ARCHITECT
```
1. Run: /design-doc docs/proposals/01-*.md
   → Produces: docs/design-doc.md (10 sections, "Will implement X because")
   → Uses: context7 for library docs, @system-architect, @backend-architect, @security-engineer
2. Run: /checkpoint design-doc | "architecture design"
3. Write specs if not already present:
   → One spec per feature in specs/ (8-field format with <system-reminder>)
4. Run: /plan-tasks docs/design-doc.md
   → Creates: GitHub Issues with phase labels + [P] parallel markers
5. Run: /checkpoint plan-tasks | "implementation plan"
6. Run: /gate stage-2-architect
```

### STAGE 3: IMPLEMENT
```
For each phase (1 through N) from the implementation plan:
  For each GitHub Issue in this phase (gh issue list --label "phase-N-implement,ready"):

    a. Mark issue in-progress: gh issue edit {N} --add-label "in-progress" --remove-label "ready"

    b. Select the right agent based on issue labels:
       - domain-tenants  → @django-tenants-agent
       - domain-auth     → @django-ninja-agent
       - domain-workflows → @django-ninja-agent
       - domain-documents → @s3-lambda-agent + @django-ninja-agent
       - domain-aws      → @aws-setup-agent
       - domain-frontend → /sc:implement with frontend persona

    c. Pre-fetch docs: spawn @context-loader-agent for the task's libraries

    d. Execute: spawn the selected agent with:
       - The spec file for this feature (from specs/)
       - CLAUDE.md rules
       - context7 docs from context-loader
       - The handoff from previous agent (if sequential dependency)

    e. Post-implementation (CLAUDE.md post-impl rule):
       - black . && ruff check . --fix
       - uv run python manage.py makemigrations (if models changed)
       - uv run python manage.py migrate_schemas --shared (if shared models)
       - uv run python manage.py migrate_schemas --tenant (if tenant models)
       - uv run python manage.py test

    f. Run: /checkpoint {agent-name} | "{task description}"

    g. If tests fail → spawn @root-cause-analyst → reflexion loop (max 3):
       - Read failure output
       - Identify root cause
       - Surgical fix
       - Re-test
       - If 3 retries exhausted → report blocker, continue to next task

    h. If tests pass → commit:
       - git add [specific files]
       - git commit -m "feat: {issue title}"
       - gh issue close {N} --comment "Implemented. Tests pass."

  After each phase completes:
    Run: /gate stage-3-phase-{N}
```

### STAGE 4: VALIDATE
```
1. Run: /audit-patterns full
   → Must achieve >90% pass rate
2. Run: /sc:analyze (code quality + security)
3. Run: uv run python manage.py test (full suite)
4. Fix any failures from audit or tests
5. Run: /gate stage-4-validate
```

### STAGE 5: REVIEW
```
1. Run: /retro {project-name}
   → Produces: docs/retrospectives/NN-name.md (BEFORE PR)
   → Updates CLAUDE.md with lessons
2. Run: /checkpoint retro | "retrospective"
3. Run: /sc:git (smart commit for any remaining changes)
4. Run: /gate stage-5-review (final PR → CodeRabbit → merge)
```

### STAGE 6: ITERATE
```
1. Collect all checkpoint files → summarize learning trajectory
2. Identify patterns: which agents needed the most fixes? Which criteria failed most?
3. Run /autoresearch on the weakest agent/command (the one with most checkpoint failures)
4. Update CLAUDE.md with accumulated lessons
5. If new features needed → loop to Stage 1
```

## Agent Selection Matrix

<system-reminder>
NEVER write code yourself. Always delegate to the correct agent.
If unsure which agent, use @system-architect to analyze and recommend.
</system-reminder>

| Task Domain | Primary Agent | Secondary Agent | context7 Libraries |
|---|---|---|---|
| Tenant/Domain models | @django-tenants-agent | — | django-tenants, django-tenant-users |
| User model, auth endpoints | @django-ninja-agent | — | django-ninja, django-tenant-users |
| Workflow/Task models + CRUD | @django-ninja-agent | — | django-ninja |
| State machine (transitions) | @django-ninja-agent | @quality-engineer (for test cases) | django-ninja |
| AuditLog | @django-ninja-agent | — | django-ninja |
| S3 presigned URLs | @s3-lambda-agent | — | boto3 |
| Lambda invocation | @s3-lambda-agent | — | boto3 |
| AWS infra setup | @aws-setup-agent | @devops-architect | aws-cli |
| Dashboard stats | @django-ninja-agent | — | django-ninja |
| Frontend templates | /sc:implement | @frontend-architect | — |
| Seed data / scripts | @python-expert | — | django |
| Docker / deployment | @devops-architect | — | docker |
| Test failures | @root-cause-analyst | — | pytest |
| Code quality | @refactoring-expert | @quality-engineer | — |
| Security review | @security-engineer | — | — |

## Parallel Execution Rules

```
Maximum 2 agents in parallel.
Only parallelize tasks that have ZERO dependencies on each other.

CAN parallel:
  - Docker setup + AWS setup (independent infra)
  - Workflow model + Document model (independent tenant apps)
  - Frontend pages (independent templates)

MUST sequential:
  - Settings → Models → Migrations → Endpoints (dependency chain)
  - Tenant models → User models (User depends on Tenant)
  - Models → CRUD endpoints (endpoints depend on models)
  - Search endpoint → History endpoint (history depends on search data)
```

## Error Recovery

| Error | Action |
|---|---|
| Agent produces wrong framework (DRF instead of Ninja) | Fix agent prompt via checkpoint, re-run |
| Tests fail after implementation | Reflexion loop: @root-cause-analyst → fix → re-test (max 3) |
| Migrations fail | Check model dependencies, run migrate_schemas --shared first |
| Docker port conflict | Use alternate port (e.g., 5433 for PG) |
| GitHub Issue already closed | Skip, move to next |
| CodeRabbit blocks gate | Read suggestions, fix, push, re-review |
| context7 can't find library | Use alternate name, or proceed without docs (log warning) |
| AWS credentials missing | STOP. Ask user for credentials. |
| OpenAI key missing | STOP. Ask user for key. |

## Handoff

This command does NOT produce a handoff — it IS the orchestrator that manages all handoffs between stages and agents. It runs until the project is complete or a human-required blocker is hit.

## What Stays After Nuke (for video re-recording)

```
KEEP (the intelligence):
  ~/.claude/commands/*.md      — all commands (improved via checkpoints)
  ~/.claude/agents/*.md        — all agents (improved via autoresearch)
  CLAUDE.md                    — project rules (improved via retro lessons)
  SPEC.md                      — the specification
  specs/*.md                   — feature specs
  docs/proposals/              — feature proposals
  docs/design-doc.md           — architecture design
  docs/checkpoints/            — learning trajectory
  .gitignore, .env.example     — config templates

DELETE (regenerated by the flow):
  config/                      — Django project (regenerated by scaffold)
  apps/                        — All app code (regenerated by agents)
  manage.py, pyproject.toml    — Project files (regenerated by scaffold)
  docker-compose.yml           — Infra (regenerated)
  migrations/                  — DB migrations (regenerated)
  templates/, static/          — Frontend (regenerated)
  .venv/                       — Virtual env (regenerated by uv sync)
```

When you re-run `/build-project SPEC.md` on the video — the prompts already know what works. The code is fresh but the intelligence is retained.
