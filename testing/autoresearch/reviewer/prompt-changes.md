# @reviewer Prompt Changes — Autoresearch 2026-04-02

## Checklist: 15 -> 25 items

### Added Items (10 new)
| # | Check | Gap Found In Run |
|---|---|---|
| 12 | Session security — session values validated, no fixation | Run 9 (middleware) |
| 13 | Path traversal — startswith checks resistant to ../ | Run 9 (middleware) |
| 14 | Error response leakage — no str(e) in API responses | Run 1 (documents), Run 3 (fastapi) |
| 15 | Class complexity — under 500 lines, under 20 public methods | Run 2 (saleor god class) |
| 18 | Concurrency safety — atomic mutations, select_for_update | Run 5 (task model), Run 2 (manager) |
| 19 | Resource bounds — max file size, pagination limits | Run 1 (documents), Run 3 (fastapi) |
| 20 | N+1 query detection — no queries inside loops | Run 6 (resolvers) |
| 22 | HTTP semantics — correct status codes (201, 204) | Run 8 (medusa route) |
| 23 | Transactional integrity — multi-step mutations in transaction | Run 5 (task model) |
| 24 | Configuration externalization — no magic numbers/strings | Run 9 (middleware), Run 10 (webhook) |
| 25 | Idiomatic patterns — framework idioms used correctly | Run 10 (promise vs asyncio) |

### Added Verification Commands (4 new)
1. Check for exception details in API responses
2. Check for N+1 query patterns
3. Check for missing transaction.atomic
4. Check for unbounded inputs

### Rating Scale Updated
- Old: X/15
- New: X/25
- Accept threshold unchanged (>= 4)

## Before/After Detection Rate

Estimated detection rate on same 10 runs:
- Before: 23/66 = 35%
- After (projected): 48/66 = 73%

Remaining gaps (hard to checklist): business logic correctness, idiomatic TS/JS patterns, architecture smell detection.
