---
description: Agent selection matrix for implementation tasks. Loaded when working on code.
paths: ["apps/**", "src/**", "*.py", "*.ts", "*.js"]
---

# Agent Selection

| Domain | Agent | context7 Libraries |
|---|---|---|
{{AGENT_MATRIX_ROWS}}

The table above is filled by /setup based on your tech stack. Example rows:

<!-- Django + multi-tenant example:
| domain-tenants | @django-tenants-agent | django-tenants, django-tenant-users |
| domain-auth | @django-ninja-agent | django-ninja, django-tenant-users |
| domain-workflows | @django-ninja-agent | django-ninja |
| domain-documents | @s3-lambda-agent + @django-ninja-agent | boto3, django-ninja |
| domain-aws | @aws-setup-agent | aws-cli |
| domain-frontend | /sc:implement (frontend persona) | — |
-->

<!-- FastAPI example:
| domain-api | @fastapi-agent | fastapi, pydantic |
| domain-db | @fastapi-agent | sqlalchemy, alembic |
| domain-auth | @fastapi-agent | fastapi-users, python-jose |
| domain-frontend | /sc:implement (frontend persona) | — |
-->

## Routing Rules

1. If no agent exists for a domain → use @agent-factory to create one
2. @context-loader-agent fetches library docs BEFORE every implementation agent
3. Frontend tasks always go to /sc:implement (frontend persona)
4. If task spans multiple domains → primary domain agent leads, secondary assists
