# Test: @devops-architect — Run 1/10

## Input
Create Docker Compose config for clinic-portal (PostgreSQL + Redis + Django)

## Score: 16/17 applicable (94%) — after fixes

### Core (items 1-15)
1. Single responsibility: PASS — "Automate infrastructure and deployment"
2. Forge Cell referenced: PASS — INFRASTRUCTURE-specific (7-step with docker compose config validation)
3. context7 MCP: PASS — step 2
4. Web search: PASS — step 2
5. Self-executing: PASS — `docker compose config`, Dockerfile validation, YAML syntax check
6. Handoff protocol: PASS — 6-field
7. [REQ-xxx]: PASS — step 7 sync check
8. Per-agent judge: PASS
9. Specific rules: PASS — infrastructure-specific with security checks
10. Failure escalation: PASS
11. /learn: PASS
12. Anti-patterns: PASS — 6 items, all infrastructure-specific (no `latest` tags, no root, no exposed DB ports)
13-15: N/A

### New (items 16-20)
16. Confidence routing: PASS — added
17. Self-correction loop: PASS — added
18. Negative instructions near end: PASS — infrastructure anti-patterns at end
19. Tool failure handling: PASS — added
20. Chaos resilience: FAIL

## STRENGTH
Role-appropriate Forge Cell — NOT generic TDD but infrastructure-specific:
validate compose file, validate Dockerfile, syntax check CI config, security check.
One of the best-adapted Forge Cell implementations.

## Verdict: EXCELLENT — domain-appropriate Forge Cell
