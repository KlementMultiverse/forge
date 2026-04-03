# Run 09: clinic-portal -- Write troubleshooting guide (common errors + fixes)

## Task
Write a troubleshooting guide for clinic-portal based on actual code, configuration, and common django-tenants issues.

## Code Read
- `/home/intruder/projects/clinic-portal/config/settings.py` -- middleware order, database config
- `/home/intruder/projects/clinic-portal/docker-compose.yml` -- container setup
- `/home/intruder/projects/clinic-portal/apps/tenants/models.py` -- Tenant/Domain models
- `/home/intruder/projects/clinic-portal/apps/tenants/middleware.py` -- middleware customization
- `/home/intruder/projects/clinic-portal/CLAUDE.md` -- architecture rules (common violation points)

## Prompt Evaluation

### What the prompt guided well
1. **Troubleshooting Guides** output type -- "Problem resolution documentation with common issues and solution paths" -- correctly identified as an output type
2. **RESEARCH step** -- Reading actual code and config reveals real error-prone areas (middleware ordering, database engine, migration commands)
3. **CROSS-CHECK step** -- CLAUDE.md rules map directly to common errors (wrong middleware position, wrong DB engine, bare migrate)
4. **Chaos Resilience** -- "Conflicting docs exist -> flag inconsistencies" -- useful for troubleshooting docs

### What the prompt missed or was weak on
1. **No error message -> fix mapping instruction** -- Best troubleshooting docs start with the exact error message users see. Prompt doesn't push for "symptom -> cause -> fix" format
2. **No log reading instruction** -- Troubleshooting requires knowing WHERE to look (log files, container logs, Django debug output). Prompt doesn't push for observability context
3. **No "diagnostic commands" section** -- `docker logs web`, `uv run python manage.py check`, `\dt` in psql. Prompt doesn't push for diagnostic toolkit
4. **No severity/urgency classification** -- Some errors are "app won't start" (critical) vs "cache miss" (minor). Prompt doesn't push for priority classification
5. **No "escalation path" documentation** -- When self-service troubleshooting fails, who to contact? Prompt doesn't cover escalation
6. **No environment-specific troubleshooting** -- Docker vs bare metal, local vs production have different failure modes. Prompt doesn't differentiate

### Sample Troubleshooting Entries (what code reveals):

1. **"relation does not exist"** -- Ran `migrate` instead of `migrate_schemas --shared` or `migrate_schemas --tenant`
2. **"TenantMainMiddleware not found"** -- Middleware position is not 0 in MIDDLEWARE list
3. **"connection refused on port 5433"** -- Docker PostgreSQL maps to 5433, not 5432
4. **"S3 access denied"** -- s3_key doesn't start with tenant schema_name
5. **"CSRF verification failed"** -- Django Ninja session auth requires CSRF token in request header

### Documentation Quality Score: 6/10
- Code reading produces excellent troubleshooting content (real error scenarios)
- CLAUDE.md architecture rules are a goldmine for "what goes wrong" documentation
- Missing: error message format, diagnostic commands, severity classification

## Prompt Gaps Identified
| Gap | Severity | Fix |
|-----|----------|-----|
| No symptom -> cause -> fix format | High | Add: "Troubleshooting docs MUST use format: Error Message/Symptom -> Root Cause -> Fix -> Prevention" |
| No log/diagnostic instruction | High | Add: "Include diagnostic commands section: how to read logs, check system state, verify configuration" |
| No severity classification | Medium | Add: "Classify issues by severity: Critical (system down), Warning (degraded), Info (cosmetic)" |
| No escalation path | Low | Add: "Include escalation path: when to contact team lead, open issue, page on-call" |
| No environment-specific sections | Medium | Add: "Separate troubleshooting by environment: Docker, local dev, staging, production" |
