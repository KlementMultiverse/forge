# Django Agent Routing

| Domain | Files | Agent | context7 Libraries |
|---|---|---|---|
| Models & services | `apps/*/models.py`, `apps/*/services.py` | @backend-architect | django |
| API routes & schemas | `apps/*/api.py`, `apps/*/schemas.py` | @django-ninja-agent | django-ninja, pydantic |
| Multi-tenant models | `apps/tenants/**`, middleware | @django-tenants-agent | django-tenants, django-tenant-users |
| Templates | `templates/**/*.html` | /sc:implement | django |
| JavaScript | `static/js/**` | /sc:implement | -- |
| CSS | `static/css/**` | /sc:implement | -- |
| Settings & config | `config/settings.py`, `config/urls.py` | @backend-architect | django |
| Tests | `apps/*/tests.py`, `tests/**` | @quality-engineer | django |
| Docker & deploy | `Dockerfile`, `docker-compose.yml` | @devops-architect | -- |
| S3 & Lambda | `apps/*/storage.py`, Lambda handlers | @s3-lambda-agent | boto3 |
| AI/LLM integration | `apps/*/llm.py`, prompt management | @llm-integration-agent | -- |
