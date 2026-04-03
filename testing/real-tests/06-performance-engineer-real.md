# REAL TEST: @performance-engineer on clinic-portal

## Input
"Full performance audit — N+1 queries, missing indexes, unbounded querysets, cache issues"

## Real Findings: 14 issues

| # | Severity | Finding | Location |
|---|---|---|---|
| 1 | HIGH | N+1: Admin task_summary fires 4 queries per workflow row | workflows/admin.py:32-48 |
| 2 | HIGH | N+1: Login fires 1 query per tenant for Domain lookup | users/api.py:153-156 |
| 3 | HIGH | 4 list endpoints return ALL records with no pagination | workflows, documents, tenants |
| 4 | HIGH | 5 timestamp fields missing db_index (created_at, updated_at) | documents, workflows, search models |
| 5 | HIGH | Sync LLM calls block WSGI workers for 30-90 seconds | documents/api.py, search/chat.py |
| 6 | MEDIUM-HIGH | Full S3 document read into memory with no size guard | documents/api.py:45 |
| 7 | MEDIUM | N+1: Admin message_count fires 1 query per row | search/admin.py:46-49 |
| 8 | MEDIUM | N+1 INSERTs: generate_tasks creates tasks one-at-a-time | workflows/api.py:302-321 |
| 9 | MEDIUM | S3/Lambda client instantiated per request (no reuse) | documents/services.py:36-43 |
| 10 | MEDIUM | Per-request tenant membership check on every API call | tenants/middleware.py:46 |
| 11 | LOW-MEDIUM | Missing select_related on get_workflow | workflows/api.py:184-196 |
| 12 | LOW-MEDIUM | Missing .only() on list_staff | users/api.py:253 |
| 13 | LOW-MEDIUM | Unnecessary SearchHistory query on every chat message | search/chat.py:227-249 |
| 14 | LOW | Cache key correctness (latent tenant collision risk) | dashboard/api.py:49 |

## Top 3 Priorities (highest impact)
1. Add pagination to all list endpoints
2. Add db_index=True to 5 timestamp fields (single migration)
3. Fix login N+1 with prefetch_related

## Score: EXCELLENT — 14 real findings with specific fixes, measured correctly
