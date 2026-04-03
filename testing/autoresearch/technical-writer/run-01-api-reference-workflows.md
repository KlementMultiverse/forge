# Run 01: clinic-portal -- Write API reference for /api/workflows/ endpoints

## Task
Write API reference documentation for the /api/workflows/ and /api/tasks/ endpoints based on actual code.

## Code Read
- `/home/intruder/projects/clinic-portal/apps/workflows/api.py` (510 lines)
- `/home/intruder/projects/clinic-portal/apps/workflows/models.py` (125 lines)

## Documentation Produced

### What the prompt guided well
1. **RESEARCH step** -- "Read the actual code being documented -> extract function signatures, class hierarchies, API routes" -- directly led to reading api.py and models.py
2. **STRUCTURE step** -- "API ref -> endpoint tables" format instruction was clear and actionable
3. **CROSS-CHECK step** -- "Every documented feature must have a matching [REQ-xxx]" -- docstrings reference REQ-009
4. **Audience targeting** -- "developer new to this project" default was appropriate for API docs

### What the prompt missed or was weak on
1. **No OpenAPI schema extraction instruction** -- Django Ninja auto-generates OpenAPI; prompt should instruct agent to extract/reference the auto-generated schema
2. **No request/response example instruction** -- Prompt says "working examples" generically but doesn't specify: "Include complete curl/httpie example for each endpoint with request body and response body"
3. **No authentication flow documentation** -- API docs need auth context (how to get session cookie, CSRF token handling), but prompt doesn't push for auth prerequisites section
4. **No error code catalog instruction** -- Each endpoint has multiple error codes; prompt doesn't push for consolidated error reference
5. **No rate limiting/caching documentation** -- Found that list_workflows caches for 30 seconds, but prompt doesn't instruct documenting caching behavior
6. **No state machine documentation** -- Task.VALID_TRANSITIONS is critical for API consumers but prompt doesn't push for state diagram documentation
7. **No pagination documentation** -- list endpoints return all results; prompt doesn't push for documenting pagination (or lack thereof)

### Sample Output Quality Assessment

The agent would produce a standard endpoint table:

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | /api/workflows/ | Session | List workflows with task counts |
| POST | /api/workflows/ | Session + Admin | Create workflow |
| GET | /api/workflows/{id} | Session | Get workflow detail with tasks |
| PUT | /api/workflows/{id} | Session + Admin | Update workflow |
| DELETE | /api/workflows/{id} | Session + Admin | Delete workflow |
| POST | /api/workflows/{id}/generate-tasks | Session + Admin | AI-generate tasks |
| GET | /api/tasks/ | Session | List tasks (filterable) |
| POST | /api/tasks/ | Session + Admin | Create task |
| GET | /api/tasks/{id} | Session | Get task detail |
| PUT | /api/tasks/{id} | Session + Admin | Update task |
| POST | /api/tasks/{id}/transition | Session + Admin | Change task status |
| POST | /api/tasks/{id}/assign | Session + Admin | Assign task to user |

BUT: this is a table, not a complete API reference. Missing:
- Request body schemas
- Response body schemas
- Error response examples
- Curl examples
- State transition diagram
- Authentication prerequisites

### Documentation Quality Score: 6/10
- Prompt guided code reading: Good
- Prompt guided output format: Weak -- "endpoint tables" is too vague
- Prompt guided completeness: Poor -- missing auth, examples, state machine, caching

## Prompt Gaps Identified
| Gap | Severity | Fix |
|-----|----------|-----|
| No OpenAPI schema extraction | High | Add: "For API docs, extract or reference the auto-generated OpenAPI schema if available" |
| No request/response example template | High | Add: "Include complete request/response examples (curl + JSON body) for every endpoint" |
| No auth prerequisites section | High | Add: "Start API docs with an Authentication section explaining how to obtain credentials" |
| No error catalog instruction | Medium | Add: "Produce consolidated error code reference across all endpoints" |
| No caching/performance behavior | Medium | Add: "Document caching behavior, rate limits, and performance characteristics" |
| No state machine/workflow documentation | Medium | Add: "For stateful resources, document state transitions with allowed transitions" |
| No pagination documentation | Low | Add: "Document pagination behavior (or explicit lack thereof)" |
