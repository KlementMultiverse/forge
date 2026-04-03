# Run 05: Saleor - Celery Task Queue Patterns

## Target
- Repo: saleor (~400K lines, Python/Django + Celery)
- Focus: Background job optimization, task queue patterns

## Files Read
- `saleor/payment/tasks.py` - Payment background tasks
- `saleor/warehouse/tasks.py` - Warehouse/stock tasks
- `saleor/product/tasks.py` - Product update tasks

## Findings

### 1. Unbounded Query in Stock Reconciliation Task
```python
@app.task
def update_stocks_quantity_allocated_task():
    for mismatched_stock in Stock.objects.annotate(
        allocations_allocated=Coalesce(Sum("allocations__quantity_allocated"), 0)
    ).exclude(quantity_allocated=F("allocations_allocated")):
```
This loads ALL mismatched stocks into memory at once. For large catalogs (100K+ SKUs), this aggregation + iteration could be very slow and memory-intensive. The task does batch the update via `stock_bulk_update`, but the initial query is unbounded.

### 2. Batching Pattern for Variants (Good)
Product tasks use proper batching:
```python
VARIANTS_UPDATE_BATCH = 500
def _variants_in_batches(variants_qs):
    while True:
        variants = list(variants_qs.order_by("pk").filter(pk__gt=start_pk)[:VARIANTS_UPDATE_BATCH])
```
This keyset pagination avoids OFFSET performance degradation. Well-implemented.

### 3. Complex Subquery in Payment Task
`transactions_to_release_funds()` builds a complex query with:
- Multiple `OuterRef` subqueries
- `ExpressionWrapper` with `DateTimeField`
- 5+ filter conditions with `Q` objects
- Uses database replica for the read

This is a heavy query that runs periodically. No obvious caching or index hints.

### 4. No Task Retry Configuration
Tasks use `@app.task` without retry configuration:
```python
@app.task
@allow_writer()
def delete_empty_allocations_task():
```
No `bind=True`, `max_retries`, `retry_backoff`, or `rate_limit`. If these tasks fail, they silently fail without retry.

### 5. No Task Time Limits
No `soft_time_limit` or `time_limit` on any tasks. A runaway task could block a worker indefinitely.

### 6. Database Write Decorator Pattern
`@allow_writer()` decorator controls read/write routing. This is a good pattern for separating read replica traffic from write operations in tasks.

## Does the Current Prompt Guide Finding This?
**NO** for most:
- **NO** background job/task queue optimization patterns
- **NO** unbounded query detection in background tasks
- **NO** Celery-specific configuration checklist (retries, time limits, rate limits)
- **NO** batching pattern recognition and recommendations
- **NO** task monitoring/observability patterns
- **Partial** mention of "query optimization" covers the subquery analysis

## Gaps to Fix
1. Add background job/task queue performance patterns
2. Add unbounded query detection for batch operations
3. Add task configuration checklist (retries, time limits, rate limits, idempotency)
4. Add batching best practices (keyset pagination, chunk size tuning)
