# Run 07: Django Ninja vs FastAPI -- when to choose which

## Research Topic
"Django Ninja vs FastAPI -- when to choose which"

## Research Performed
- WebSearch: "Django Ninja vs FastAPI comparison when to choose 2025 2026"

## Prompt Evaluation

### What the prompt guided well
1. **Alternative comparison** -- Clear head-to-head with differentiated use cases
2. **Current best practices** -- Captured that Django Ninja brings FastAPI-like syntax into Django ecosystem
3. **Gotchas** -- Found Django's middleware overhead as measurable performance cost
4. **Causal Chains** -- Observation (both use Pydantic) -> Cause (different runtime environments) -> Effect (different deployment patterns)

### What the prompt missed or was weak on
1. **No ecosystem dependency analysis** -- Django Ninja inherits all of Django; FastAPI inherits Starlette/Uvicorn. Prompt doesn't push for dependency tree comparison
2. **No real benchmark data instruction** -- Found "2000+ req/s for FastAPI" but prompt doesn't instruct to seek or validate benchmark numbers
3. **No migration story** -- If you start with one, how hard is it to switch? Important for architecture decisions
4. **No team composition analysis** -- "Do you already know Django?" is the #1 deciding factor but prompt doesn't push for team-capability assessment
5. **No plugin/extension ecosystem comparison** -- Django has admin, ORM, auth baked in; FastAPI requires choosing each separately

### Research Quality Score: 7/10
- Sources found: 6 relevant
- Alternatives compared: 2 main + DRF and Flask as context
- Actionable recommendation: Yes -- "Django Ninja if you're in Django ecosystem, FastAPI if building API-first microservice"
- Weakness: Too surface-level -- didn't dig into specific feature parity (WebSocket support, background tasks, dependency injection)

## Handoff Output (as agent would produce)

```
## Research Completed
### Summary: Django Ninja brings FastAPI-like syntax (Pydantic, type hints, auto-docs) to Django. FastAPI is purpose-built for async API-first development. Key decision factor: existing Django ecosystem usage vs greenfield API project.
### Approach Recommended: Django Ninja when you need Django's ORM, admin, auth, middleware ecosystem. FastAPI when building async microservices or AI-powered APIs with high concurrency.
### Alternatives Considered:
- Django Ninja: FastAPI syntax inside Django. Full middleware stack. ORM, admin, auth included. Middleware overhead per request.
- FastAPI: Purpose-built async. 2000+ req/s. WebSocket native. Requires assembling auth, ORM, admin separately.
- DRF: Mature but heavy serializer pattern. Being displaced by Django Ninja for new projects.
- Flask: Simpler but less opinionated. Neither Django's ecosystem nor FastAPI's performance.
### Sources:
- https://www.blueshoe.io/blog/django-ninja-vs-fastapi/
- https://codeartisanlab.com/drf-vs-fastapi-vs-django-ninja-vs-flask-best-python-web-frameworks-compared-in-2025/
- https://augustinejoseph.medium.com/fastapi-vs-django-vs-django-ninja-vs-fastify-vs-express-a-real-world-performance-benchmark-on-0b0fd1db9eb0
### Delegation Hints: Next: @django-ninja-agent should proceed with Django Ninja for clinic-portal (per CLAUDE.md tech stack mandate).
### Risks/Unknowns: Django Ninja async support is less mature than FastAPI. Django middleware overhead may matter at high scale.
### Insights for Playbook:
INSIGHT: Django Ninja eliminates the DRF-vs-FastAPI debate for Django shops -- you get FastAPI's DX without leaving Django.
INSIGHT: Django's default middleware stack adds measurable per-request overhead even for trivial endpoints.
INSIGHT: FastAPI's dependency injection system has no equivalent in Django Ninja -- impacts testing patterns.
```

## Prompt Gaps Identified
| Gap | Severity | Fix |
|-----|----------|-----|
| No dependency tree analysis | Low | Add: "Compare dependency footprint and what each brings transitively" |
| No benchmark validation instruction | Medium | Add: "Seek independent benchmarks, not vendor-published numbers. Note test conditions." |
| No migration story | Medium | Add: "Assess switching cost between alternatives" |
| No team composition analysis | High | Add: "Evaluate alternatives against the team's existing skills and hiring market" |
| No feature parity matrix | Medium | Add: "Create feature parity matrix for direct competitors" |
