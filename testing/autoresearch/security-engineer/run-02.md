# Run 02: saleor — GraphQL introspection, query depth limits, alias batching protection

## Target
- Repo: `/home/intruder/projects/forge-test-repos/saleor`
- Scope: GraphQL security (introspection, cost, depth)

## Files Examined
- `saleor/graphql/views.py` — GraphQLView with query cost validation
- `saleor/graphql/core/validators/query_cost.py` — CostValidator implementation
- `saleor/settings.py:876-877` — `GRAPHQL_QUERY_MAX_COMPLEXITY = 50000`
- `saleor/urls.py:20` — `csrf_exempt(GraphQLView.as_view(...))`

## Security Findings

### 1. GraphQL introspection is enabled by default (MEDIUM)
- **File**: `saleor/graphql/core/tests/test_view.py:302-312`
- **Issue**: Introspection queries work and results are cached. No evidence of DisableIntrospection in production. Introspection reveals full schema to attackers.
- **Note**: Saleor caches introspection results, which at least prevents DoS from repeated introspection queries.

### 2. Query cost validation EXISTS (GOOD)
- **File**: `saleor/graphql/views.py:382`, `saleor/settings.py:876`
- `GRAPHQL_QUERY_MAX_COMPLEXITY = 50000` with full CostValidator
- Cost map exists in `saleor/graphql/query_cost_map.py`

### 3. No explicit query depth limiting (MEDIUM)
- No `depth_limit` or `max_depth` validation rule found in the GraphQL validation pipeline.
- Cost validation is complexity-based, not depth-based. Deeply nested queries with low-cost fields could still be problematic.

### 4. GraphQL endpoint is csrf_exempt (HIGH)
- **File**: `saleor/urls.py:20`
- `csrf_exempt(GraphQLView.as_view(...))` — entire GraphQL API has CSRF protection disabled.
- This is common for API-first apps using token auth, but if any session-based auth path exists, this is exploitable.

### 5. Query batching supported (MEDIUM)
- **File**: `saleor/graphql/views.py:88` — comment mentions "query batching"
- No evidence of batch size limits. An attacker could send hundreds of queries in a single request.

## Agent Prompt Evaluation

| Finding | Would prompt guide to this? | Notes |
|---|---|---|
| Introspection enabled | NO | Prompt has NO GraphQL-specific security checks |
| Query cost validation | NO | Not mentioned in prompt |
| No depth limiting | NO | Not mentioned |
| csrf_exempt on GraphQL | YES | Prompt says "check CSRF" and "grep csrf_exempt" |
| Query batching abuse | NO | Not mentioned |

## GAPs Identified
1. **GAP: No GraphQL security checklist** — prompt needs: introspection control, query depth limits, query cost/complexity limits, alias abuse, batch limits, field suggestions disabled
2. **GAP: No API-specific attack surface analysis** — GraphQL, REST, and gRPC have different security profiles; prompt treats all APIs the same
