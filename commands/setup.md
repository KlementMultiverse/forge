# /setup — Interactive Project Setup

Generate CLAUDE.md, SPEC.md, and project configuration through guided questions.

## When to Use
- First time setting up a new project with Forge
- Before running /forge on a fresh project
- When CLAUDE.md has placeholder values

## Execution

<system-reminder>
Ask questions ONE AT A TIME. Wait for the user's answer before asking the next.
Use the answers to generate REAL, specific files — not templates with placeholders.
The quality of everything that follows depends on this setup being thorough.
</system-reminder>

### Phase 1: Project Identity (3 questions)

Q1: "What are you building? (one sentence)"
    Captures: project name, core purpose

Q2: "Who uses it? (internal team / customers / developers / public)"
    Captures: user types, access patterns

Q3: "What's the core problem it solves? Why can't users just use existing tools?"
    Captures: value proposition, gap being addressed

### Phase 2: Technical Decisions (4 questions)

Q4: "What language and framework? (I can recommend based on your needs, or you can specify)"
    If user says "recommend" — analyze the project type:
      - Web app with DB: Django/FastAPI + PostgreSQL
      - API-only: FastAPI + PostgreSQL
      - Full-stack JS: Next.js + Prisma
      - CLI tool: Python/Go
      - Mobile backend: FastAPI/Django
    Present recommendation with ONE-LINE rationale. Ask to confirm.

Q5: "Database? (PostgreSQL / SQLite / MongoDB / none)"
    Default recommendation based on Q4 answer.

Q6: "Frontend? (Django templates + vanilla JS / React / Next.js / Vue / none — API only)"
    Default based on Q4.

Q7: "Any of these apply? (multi-select)"
    - [ ] Multi-tenant (each customer gets isolated data)
    - [ ] AI/LLM features (summarization, chatbot, search)
    - [ ] File uploads (S3, cloud storage)
    - [ ] Real-time features (WebSocket, SSE)
    - [ ] Background jobs (Celery, Lambda)
    - [ ] Authentication (session / JWT / OAuth)

### Phase 3: Constraints (2 questions)

Q8: "What should this project NEVER include? (things to explicitly exclude)"
    Examples: "no patient data", "no payment processing", "no React", "no CI/CD"

Q9: "Any specific rules or patterns you want enforced?"
    Examples: "always use uv not pip", "Django Ninja not DRF", "tests with pytest not unittest"

### Phase 4: Generate Files

Using ALL answers, generate these files. They must be REAL and SPECIFIC — not templates.

#### 4.1: Generate CLAUDE.md (under 100 lines)

Use the template from templates/CLAUDE.template.md. Fill ALL placeholders:
- {{PROJECT_NAME}} from Q1
- {{ONE_LINE_DESCRIPTION}} from Q1
- {{TECH_STACK_ROWS}} from Q4-Q6 (real rows, not placeholders)
- {{ARCHITECTURE_RULES}} from Q7+Q9 (numbered, MUST/NEVER format, with code snippets)
- {{ANTI_SCOPE}} from Q8 (bullet list)
- {{TEST_RUNNER_COMMAND}} based on Q4 (e.g., "uv run python manage.py test" or "npm test")
- {{LINT_COMMAND}} based on Q4 (e.g., "black . && ruff check . --fix")
- {{TEST_BASE_CLASS_RULE}} based on Q7 (e.g., tenant tests use TenantTestCase)

Architecture rules MUST be:
- Numbered (1, 2, 3, etc.)
- Binary (MUST or NEVER)
- Include code snippets where applicable
- Based on tech stack choices

Example for Django + Django Ninja + PostgreSQL + multi-tenant:
```
1. Django Ninja for ALL API routes — NEVER import `rest_framework`
2. Database engine MUST be `django_tenants.postgresql_backend`
3. `TenantMainMiddleware` MUST be position 0 in MIDDLEWARE
4. S3 keys MUST be namespaced: `{tenant_schema_name}/{uuid}/{filename}`
5. All credentials from `os.environ` — NEVER hardcoded
6. `uv` for all packages — NEVER `pip install`
7. Run tests after EVERY code change: `uv run python manage.py test`
```

#### 4.2: Generate .claude/rules/sdlc-flow.md

Fill templates/rules/sdlc-flow.md with the standard SDLC stages, customized for the tech stack.
Replace {{SDLC_FLOW_CONTENT}} — remove the placeholder line entirely.

#### 4.3: Generate .claude/rules/agent-routing.md

Fill agent matrix based on tech stack:
- Django: @django-ninja-agent, @django-tenants-agent
- FastAPI: @fastapi-agent (via @agent-factory if needed)
- Multi-tenant: @django-tenants-agent
- AI features: @llm-integration-agent, @rag-architect
- File uploads: @s3-lambda-agent or @gcp-setup-agent
- Frontend: /sc:implement
Replace {{AGENT_MATRIX_ROWS}} with real rows. Remove placeholder line and comments.

#### 4.4: Generate SPEC.md

Use templates/SPEC.template.md. Fill with:
- Project overview from Q1-Q3
- Tech stack from Q4-Q7
- Basic model outlines based on project type
- [REQ-001] through [REQ-xxx] from project description

#### 4.5: Generate .claude/settings.json with hooks

Based on tech stack, create appropriate hooks. Use templates/hooks.json as base.
Replace {{PROJECT_DIR}} with actual project directory.

For Python projects:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "cd /path/to/project && (ls *.py > /dev/null 2>&1 && python -m ruff check --fix . 2>/dev/null; true)",
        "description": "Auto-lint Python files after edit"
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash(rm -rf*|git push --force*|git reset --hard*)",
        "command": "echo 'BLOCKED: Destructive command requires explicit user approval' && exit 2",
        "description": "Block destructive commands"
      }
    ]
  }
}
```

For JS/TS projects, replace ruff with eslint/prettier.

#### 4.6: Create .gitignore from template

Standard .gitignore based on tech stack (Python, Node, etc.).

### Phase 5: Confirm

Show the user:
```
Generated:
  CLAUDE.md          — [N] lines, [N] architecture rules
  SPEC.md            — [N] requirements with [REQ-xxx] tags
  .claude/rules/     — SDLC flow + agent routing
  .claude/settings.json — hooks for lint + test + safety
  .gitignore         — standard exclusions

Ready to start building. Run: /forge "$ARGUMENTS"
```

Wait for user to confirm or request changes.
