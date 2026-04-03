# [Task Title] — Design Document

*[Issue #N] | [Agent: @agent-name]*

---

## Current Context

### Existing System
[What exists now — read the actual code before writing this. Reference file:line.]

### Gap Being Addressed
[What's missing or broken. Link to [REQ-xxx].]

---

## Requirements

### Functional
1. [REQ-xxx] [Specific thing to implement]
2. [REQ-xxx] [Another specific thing]

### Constraints (from CLAUDE.md / rules)
- [Rule #N: specific constraint that applies]
- [Rule #N: another constraint]

---

## Design Decisions

### Decision 1: [Choice]
Will implement [X] because:
- [Rationale]
- Trade-off: [what you give up]
- Alternative considered: [what you didn't pick and why]

---

## Technical Design

### Files to Change
- `path/to/file.py` — [what changes]
- `path/to/new_file.py` — [new file, purpose]

### Code Changes

```python
# Exact code to add/modify — not pseudocode
class BookmarkIn(Schema):
    url: HttpUrl
    title: str = ""
    tags: list[str] = []
```

### API Contract (if endpoint)
```
POST /api/bookmarks/
  Request:  { "url": "https://...", "title": "optional" }
  Response: { "id": 1, "url": "...", "title": "...", "created_at": "..." }
  Errors:   422 (validation), 401 (not auth)
```

### Error Response (standard format)
```json
{ "error": "validation_error", "message": "URL is required", "field": "url" }
```

---

## Sync Check (spec ↔ test ↔ code)

| [REQ-xxx] | Test File:Method | Code File:Function | Status |
|---|---|---|---|
| [REQ-001] | tests.py:test_create | api.py:create_bookmark | PLANNED |

---

## Implementation Steps

| Step | What | Command to Verify |
|------|------|--------------------|
| 1 | Write test | `uv run python manage.py test apps.bookmarks -k test_create` → FAIL |
| 2 | Write code | `uv run python manage.py test apps.bookmarks -k test_create` → PASS |
| 3 | All tests | `uv run python manage.py test` → PASS |
| 4 | Lint | `black . && ruff check . --fix` → clean |
| 5 | Commit | `git commit -m "feat(bookmarks): add create endpoint [REQ-001]"` |

---

## Testing

| # | Scenario | Input | Expected | [REQ-xxx] |
|---|----------|-------|----------|-----------|
| 1 | Happy path | valid URL | 201, bookmark created | REQ-001 |
| 2 | Invalid URL | "not-a-url" | 422 error | REQ-001 |
| 3 | Unauthenticated | no session | 401 | REQ-001 |

---

## Risks
- [Risk and mitigation, if any]

---

## Done Criteria
- [ ] Tests pass
- [ ] Lint clean
- [ ] [REQ-xxx] has: test + code + spec reference
- [ ] No orphan code (everything traces to a requirement)
- [ ] AuditLog entry (if state mutation)
