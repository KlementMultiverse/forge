# Run 03: fastapi-template -- Write deployment guide (Docker, production config)

## Task
Write deployment guide for a FastAPI template project (Docker, production configuration).

## Code Read
- No fastapi-template repo available locally
- Would need Dockerfile, docker-compose.yml, settings/config files

## Prompt Evaluation

### What the prompt guided well
1. **Forge Cell Compliance** -- "CONTEXT: Read CLAUDE.md + SPEC.md" correctly prioritizes understanding deployment constraints
2. **VERIFY step** -- "Run the code examples you write in docs" -- good instruction for deployment docs (test that docker commands work)
3. **Installation Documentation** output type -- "Setup procedures with verification steps and environment configuration" matches this task

### What the prompt missed or was weak on
1. **No environment-specific sections instruction** -- Deployment guides need: dev, staging, production sections. Prompt doesn't push for environment differentiation
2. **No security hardening checklist** -- Production deployment MUST cover: secrets management, TLS, firewall, least privilege. Prompt says nothing about security in deployment docs
3. **No resource sizing guidance** -- "How much RAM/CPU for 100 concurrent users?" is a common question. Prompt doesn't push for capacity planning
4. **No rollback procedure instruction** -- Deployment docs need rollback strategy. Prompt doesn't mention it
5. **No monitoring/logging setup instruction** -- Production deployment is incomplete without observability setup. Prompt doesn't push for it
6. **No CI/CD integration instruction** -- Deployment guide should show how to automate deployment. Prompt doesn't differentiate manual vs automated deployment
7. **No Dockerfile best practices** -- Multi-stage builds, non-root user, health checks -- prompt doesn't push for container security best practices

### Documentation Quality Score: 5/10
- Without codebase, agent would produce generic deployment guide
- Prompt's Chaos Resilience handles "empty codebase" but the output would be template-level, not project-specific
- Missing critical production concerns: security hardening, rollback, monitoring, capacity planning

## Prompt Gaps Identified
| Gap | Severity | Fix |
|-----|----------|-----|
| No environment differentiation | High | Add: "For deployment docs, separate dev/staging/production with environment-specific settings" |
| No security hardening checklist | High | Add: "Production docs MUST include security checklist: secrets, TLS, firewall, least privilege" |
| No resource sizing guidance | Medium | Add: "Include resource sizing recommendations for target user counts" |
| No rollback procedure | High | Add: "Every deployment guide MUST include rollback procedure" |
| No monitoring/logging setup | Medium | Add: "Include observability setup: logging, metrics, alerting" |
| No CI/CD integration | Low | Add: "Show both manual and automated (CI/CD) deployment paths" |
