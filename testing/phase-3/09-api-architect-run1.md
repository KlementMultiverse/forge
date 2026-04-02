# Test: @api-architect — Run 1/10

## Input
Design API contracts for document management (REQ-016 to REQ-020)

## Score: 12/12 (100%)

## Evaluation:
- 6 endpoints with EXACT request/response/error shapes: PASS
- Every error code listed (400, 401, 403, 404, 500, 502): PASS
- Auth requirements per endpoint: PASS
- [REQ-xxx] linked to every endpoint: PASS
- Data models with field types: PASS
- Rate limits and cache TTLs specified: PASS
- Delegation hints with specific agents: PASS
- Risks/blockers identified: PASS
- No implementation code (design only): PASS
- Tenant isolation in contracts (S3 prefix validation): PASS

## BONUS FINDINGS:
- Recommended max file size limit (not in SPEC — good catch)
- S3 CORS requirement for browser PUT uploads identified
- Cache invalidation chains documented (delete invalidates download + summary + dashboard)
- Uniform ErrorResponse schema defined across all endpoints

## Verdict: EXCELLENT — no prompt changes needed
Agent produced exactly what backend + frontend agents need as shared contract.
