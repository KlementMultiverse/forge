# Performance Engineer Prompt - Gap Analysis & Improvements

## Summary
Ran 10 test scenarios across 4 repos. The current prompt covers high-level principles well but lacks **concrete detection patterns** and **technology-specific checklists**. The prompt tells the agent to "measure first" but doesn't tell it **what to look for**.

## Scorecard

| Run | Repo | Focus | Current Prompt Covers? | Gap Severity |
|-----|------|-------|----------------------|--------------|
| 01 | saleor | GraphQL N+1 / DataLoaders | PARTIAL | HIGH |
| 02 | fastapi-template | Async patterns / connection pool | PARTIAL | HIGH |
| 03 | medusa | Bundle size / lazy imports | NO | HIGH |
| 04 | clinic-portal | Middleware per-request cost | NO | CRITICAL |
| 05 | saleor | Celery task queue patterns | NO | HIGH |
| 06 | fastapi-template | Pydantic validation overhead | NO | MEDIUM |
| 07 | medusa | Event loop blocking / memory | NO | HIGH |
| 08 | clinic-portal | boto3 client reuse / S3 latency | NO | CRITICAL |
| 09 | saleor | Database index strategy | PARTIAL | MEDIUM |
| 10 | medusa | Monorepo build time | NO | MEDIUM |

**Score: 0/10 fully covered, 3/10 partially covered, 7/10 not covered.**

## Gap Categories

### 1. Missing: Concrete Detection Patterns Checklist
The prompt says "profile and analyze" but never says WHAT patterns to grep for:
- N+1 queries (nested loops over ORM results, resolver per-item DB calls)
- Missing indexes (ORDER BY / WHERE columns without indexes)
- Unbounded queries (.all() without limit)
- Synchronous blocking calls in async contexts
- Cloud client re-creation per request
- Per-request middleware database queries

### 2. Missing: Technology-Specific Analysis
No guidance for:
- **Python/Django**: select_related, prefetch_related, DataLoaders, middleware cost
- **Python/FastAPI**: async vs sync handlers, connection pool config, Pydantic overhead
- **Node.js/TypeScript**: event loop blocking, execSync, import chains, bundle size
- **Database**: index type selection, EXPLAIN ANALYZE interpretation, composite index ordering
- **Cloud/AWS**: boto3 client reuse, Lambda cold starts, connection pooling for SDKs

### 3. Missing: Background Job Patterns
No coverage of:
- Task queue optimization (Celery, Bull, Sidekiq)
- Batch size tuning
- Retry/timeout configuration
- Idempotency patterns

### 4. Missing: Build/CI Performance
No coverage of:
- Monorepo build cache optimization
- Dependency deduplication
- Bundle analysis
- CI-specific optimizations

### 5. Missing: External Service Latency
No coverage of:
- Cloud SDK client lifecycle management
- HTTP client connection pooling
- Response caching for expensive external calls
- Latency budgeting per request

## Changes Made to Prompt
1. Added **Performance Detection Patterns** checklist with concrete grep/search targets
2. Added **Technology-Specific Analysis** sections for Python, Node.js, and databases
3. Added **External Service Performance** section
4. Added **Background Job Performance** section
5. Added **Build & CI Performance** section
6. Restructured Focus Areas to be more actionable
