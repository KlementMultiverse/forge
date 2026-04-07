**STEP S6: GENERATE .claude/rules/** → PM + @system-architect agent

HANDOFF METRIC (S6):
  MUST PROPAGATE:
    - STACK → agent-routing.md has correct agent mappings for this stack
    - FEATURES → agent-routing.md covers all feature domains (auth, API, infra, etc.)
    - Stack registry rules → copied to .claude/rules/{STACK_BACKEND}-rules.md (if exists)
  MUST NOT APPEAR:
    - Agent mappings for EXCLUDED features

```bash
mkdir -p .claude/rules/
```

**STACK REGISTRY CHECK** (do this FIRST):
```bash
STACK_DIR="$HOME/.claude/stacks/{STACK_BACKEND}"  # e.g., django, fastapi, nextjs
if [ -d "$STACK_DIR" ]; then
  # Copy stack rules into project
  cp "$STACK_DIR/rules.md" .claude/rules/{STACK_BACKEND}-rules.md
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

    Stack: {STACK_BACKEND}
    Features: {features}

    IMPORTANT: Check if ~/.claude/stacks/{STACK_BACKEND}/agents.md exists.
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

HANDOFF METRIC (S7):
  MUST PROPAGATE:
    - STACK → correct project structure for this stack
    - DEPLOYMENT → Dockerfile + docker-compose match deployment target
    - COMPLIANCE[] → .env.example includes compliance-related vars (e.g., ENCRYPTION_KEY for HIPAA)
  MUST NOT APPEAR:
    - Files for EXCLUDED features or stacks not chosen

Execute: spawn Agent with subagent_type="devops-architect"
  prompt: |
    Create project scaffold for {STACK_BACKEND}.
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

HANDOFF METRIC (S8):
  MUST PROPAGATE:
    - hooks.json → all 8 hook groups present
    - playbook structure → 3 files exist
    - forge-timeline.md → project name from discovery notes
    - git hooks → commit-msg + pre-commit installed
  MUST NOT APPEAR: N/A (infrastructure, not content)

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
cp ~/.claude/scripts/forge-handoff-check.sh scripts/ 2>/dev/null || true
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

<!-- HARD GATE: PM MUST NOT skip S9 or S10. Phase A is NOT complete without both. -->
<system-reminder>
S9 and S10 are MANDATORY. Do NOT say "Phase A complete" until BOTH have executed.
S9 must spawn @self-review agent. S10 must git commit. Skipping either is a VIOLATION.
</system-reminder>

