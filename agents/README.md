# Agent Catalog — 54 Agents in 8 Groups

## GROUP 1: ORCHESTRATION (command & control)

| Agent | Role | When Used |
|-------|------|-----------|
| `pm-orchestrator` | Master coordinator — delegates to all others | Every /forge run |
| `gate-keeper` | Quality gate enforcer — blocks without checks | Phase boundaries |
| `handoff-coordinator` | Structured JSON handoffs between agents | Between every step |
| `sdlc-enforcer` | Validates SDLC compliance — blocks violations | Phase transitions |
| `agent-factory` | Creates new domain-specific agents on demand | When no agent fits |
| `agent-orchestrator` | Multi-agent topology + state management | Architecture planning |

## GROUP 2: PLANNING & RESEARCH (no code, only analysis)

| Agent | Role | When Used |
|-------|------|-----------|
| `deep-research-agent` | Web research with adaptive strategies | Phase 0: /discover |
| `requirements-analyst` | Extract/write/reverse-engineer REQs | Phase 0-1 |
| `business-panel-experts` | Multi-expert strategy panel | Phase 0: /challenge |
| `context-loader-agent` | Fetches library docs via context7 | Before every impl step |
| `socratic-mentor` | Discovery learning through questions | Exploration |

## GROUP 3: ARCHITECTURE (design, no implementation)

| Agent | Role | When Used |
|-------|------|-----------|
| `system-architect` | System-level design + scalability | Phase 0: /feasibility |
| `backend-architect` | Database, API, service design | Phase 2: /design-doc |
| `api-architect` | Technology-agnostic API contracts | Phase 2: Step 13 |
| `frontend-architect` | UI/UX + modern frameworks | Frontend tasks |
| `tools-architect` | Tool schemas for AI agents | MCP/tool design |

## GROUP 4: IMPLEMENTATION (writes code)

| Agent | Role | When Used |
|-------|------|-----------|
| `python-expert` | Production Python — SOLID, typed | General Python |
| `django-tenants-agent` | Multi-tenant models, middleware | apps/tenants/, apps/audit/ |
| `django-ninja-agent` | API routes + Pydantic schemas | apps/users/, all API |
| `s3-lambda-agent` | S3 presigned URLs + Lambda | apps/documents/ |
| `llm-integration-agent` | LLM gateway, prompts, tokens | apps/conversations/ |
| `devops-architect` | Docker, CI/CD, infrastructure | Dockerfile, compose |
| `refactoring-expert` | Code cleanup + debt reduction | Phase 5: /sc:cleanup |
| `triangle-fixer` | Fixes broken SPEC↔TEST↔CODE | Triangle violations |

## GROUP 5: QUALITY & TESTING (verifies, never writes app code)

| Agent | Role | When Used |
|-------|------|-----------|
| `quality-engineer` | Writes tests FROM SPEC (never reads code) | Phase 3: Step N3 |
| `reviewer` | Rates output 1-5, blocks if <4 | Phase 3: Step N8 |
| `self-review` | Post-implementation validation | After each output |
| `pattern-auditor-agent` | 170+ pattern checks | Phase 4: /audit-patterns |
| `playwright-critic` | Autonomous e2e, creates issues | Phase 4: Step 45 |
| `security-engineer` | Threats, auth, isolation, secrets | Phase 3: N7, Phase 4: 44 |
| `root-cause-analyst` | Evidence-based failure diagnosis | When tests fail |
| `performance-engineer` | Measurement-driven optimization | Performance tasks |
| `eval-engineer` | AI eval — offline/online, LLM-judge | AI validation |

## GROUP 6: LEARNING & IMPROVEMENT (post-build)

| Agent | Role | When Used |
|-------|------|-----------|
| `retrospective-miner` | Extracts lessons into playbook | Phase 5: Step 49 |
| `playbook-curator` | Self-improving playbook (scored) | Phase 5: Step 52 |
| `learning-guide` | Progressive concept teaching | Onboarding |
| `code-archaeologist` | Deep codebase assessment | Brownfield analysis |
| `repo-index` | Repository indexing + briefing | Session start |

## GROUP 7: DOCUMENTATION & DEPLOYMENT

| Agent | Role | When Used |
|-------|------|-----------|
| `technical-writer` | Clear docs for specific audience | Phase 5: /sc:document |
| `deploy-guide` | DEPLOY.md from Docker state | Phase 5: Step 51 |

## GROUP 8: SPECIALIST (domain-specific, activate on demand)

| Agent | Role |
|-------|------|
| `aws-setup-agent` | S3, Lambda, IAM |
| `gcp-setup-agent` | Cloud Storage, Functions |
| `azure-setup-agent` | Blob, Functions, AD |
| `azure-openai-agent` | Azure OpenAI + LiteLLM |
| `vertex-ai-agent` | Vertex AI + Vector Search |
| `langchain-agent` | LCEL chains, retrievers |
| `langgraph-agent` | Stateful agent workflows |
| `langsmith-agent` | LLM tracing + evaluation |
| `rag-architect` | RAG pipelines |
| `chatbot-builder` | Conversational AI |
| `voice-agent-builder` | Real-time voice |
| `mcp-architect` | MCP server builder |
| `ai-safety-agent` | Guardrails + PII filtering |

## Quick Selection

```
models?      → @django-tenants-agent
API?         → @django-ninja-agent
tests?       → @quality-engineer
review?      → @reviewer
security?    → @security-engineer
S3/Lambda?   → @s3-lambda-agent
triangle?    → @triangle-fixer
Docker?      → @devops-architect
research?    → @deep-research-agent
handoff?     → @handoff-coordinator
```
