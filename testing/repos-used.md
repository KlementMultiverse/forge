# Test Repos Used Across All Autoresearch Rounds

## Round V1 (10 runs per agent, 16 agents)
| Repo | Technology | Source | Status |
|---|---|---|---|
| clinic-portal | Django multi-tenant | Local project | KEEP |
| saleor | Django + GraphQL | github.com/saleor/saleor | DELETED |
| fastapi-template | FastAPI | github.com/tiangolo/full-stack-fastapi-template | DELETED |
| medusa | TypeScript monorepo | github.com/medusajs/medusa | DELETED |

## Round V2 (5 edge-case runs per agent, 16 agents)
| Repo | Technology | Source | Status |
|---|---|---|---|
| axum | Rust web framework | github.com/tokio-rs/axum | KEPT |
| chi | Go router | github.com/go-chi/chi | KEPT |
| drf | Django REST Framework | github.com/encode/django-rest-framework | KEPT |
| pydantic | Python validation | github.com/pydantic/pydantic | KEPT |
| taxonomy | Next.js + TypeScript | github.com/shadcn-ui/taxonomy | KEPT |

## Round V3 (6 runs per agent, 8 agents)
| Repo | Technology | Source | Status |
|---|---|---|---|
| flask | Python micro-framework | github.com/pallets/flask | KEPT |
| hono | TypeScript edge framework | github.com/honojs/hono | KEPT |
| sveltekit | Svelte SSR | github.com/sveltejs/kit | KEPT |
| fiber | Go Express-like | github.com/gofiber/fiber | KEPT |
| actix-web | Rust actor-model | github.com/actix/actix-web | KEPT |
| fastapi | Python async ASGI | github.com/fastapi/fastapi | KEPT |

## Additional Sources
| Source | Type | Status |
|---|---|---|
| claudecode-leak | Claude Code v2.1.88 TS source | LOCAL (~/projects/claudecode-leak/) |
| markdown.engineering | 50 Claude Code lessons | FETCHED → docs/claude-code-lessons/ |

## Total: 16 repos used across 3 rounds
- Languages covered: Python, TypeScript, Rust, Go, Svelte, Next.js
- Frameworks: Django, Flask, FastAPI, DRF, Axum, Actix-web, Chi, Fiber, Hono, SvelteKit, Next.js, Pydantic
- Paradigms: MVC, micro-framework, edge runtime, actor model, SSR, CSR, monorepo, multi-tenant
