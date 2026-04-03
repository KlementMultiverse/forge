# Stage 3: IMPLEMENT — Evaluation (Phase 1 only)

## Verdict: Design doc is 55-90% specified depending on task

### Phase 1 Readiness
| Task | Specification | Blocking Gaps |
|---|---|---|
| Docker + pyproject | 85% | No Dockerfile contents |
| Settings.py | 90% | Missing TEMPLATES, STATIC, LOGGING config |
| User model | 90% | UserProfile contract unknown (need context7) |
| Auth API | **55%** | Missing schemas, CSRF contradiction, register vs signup ambiguous |

### FORGE CELL Breakdown
| Step | Status | Issue |
|---|---|---|
| 1. CONTEXT | Partial | Library names given but no specific doc topics |
| 2. RESEARCH | Needed | UserProfile contract, SessionAuth API, django-tenants + Ninja interaction |
| 3. TDD | **BLOCKED** | Cannot write assertions without response schema shapes |
| 4. IMPLEMENT | Partial | Models OK, API endpoints missing contracts |
| 5. QUALITY | OK | black + ruff config exists |
| 6. SYNC | **BLOCKED** | No [REQ-xxx] traceability tags anywhere |
| 7. OUTPUT | Unclear | Handoff format not defined between agents |
| 8. REVIEW | Partial | "Done criteria" exists but no verification commands |
| 9. COMMIT | Unclear | Commit granularity not specified |

### TOP 5 ISSUES TO FIX

1. **CSRF contradiction** — CLAUDE.md says per-auth-class, design doc says NinjaAPI(csrf=True)
2. **Register vs signup flow** — Single endpoint or two-step? Completely ambiguous.
3. **No Pydantic Schema classes in design doc** — TDD is blocked without these
4. **No [REQ-xxx] traceability** — SYNC step is broken
5. **Error response format undefined** — Two developers will implement differently

### PROMPTS THAT NEED FIXING

1. **/design-doc** — Section 4 MUST include Pydantic Schema classes (not just JSON examples)
2. **/design-doc** — Section 4 MUST include Dockerfile contents
3. **/design-doc** — Section 4 MUST include settings.py skeleton (TEMPLATES, STATIC, LOGGING)
4. **/design-doc** — Section 4 MUST include error response standard (one shape for all errors)
5. **/design-doc** — Section 5 MUST include commit granularity per task
6. **/specify** — MUST generate [REQ-xxx] tags that flow through all stages
7. **@django-ninja-agent** — MUST verify SessionAuth CSRF handling per installed version
8. **PM orchestrator** — MUST catch CSRF contradictions between CLAUDE.md and design doc
