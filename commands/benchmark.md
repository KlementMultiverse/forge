# /benchmark — Performance Baseline

Measure and compare performance metrics before and after changes. Proves optimization with numbers, not assumptions.

## Input
$ARGUMENTS — scope (e.g., "api", "frontend", "database", "all")

## Execution

### API Performance
```bash
# Response time per endpoint
for endpoint in /api/workflows/ /api/tasks/ /api/documents/ /api/auth/me; do
  echo "Testing: $endpoint"
  curl -w "time_total: %{time_total}s\nsize: %{size_download} bytes\n" -s -o /dev/null "$BASE_URL$endpoint"
done
```

### Database Performance
```bash
# Query analysis
uv run python manage.py shell -c "
from django.db import connection
from django.test.utils import CaptureQueriesContext
with CaptureQueriesContext(connection) as ctx:
    # Run key queries
    list(Workflow.objects.all())
    list(Task.objects.select_related('workflow').all())
print(f'Queries: {len(ctx.captured_queries)}')
for q in ctx.captured_queries:
    print(f'  {q[\"time\"]}ms: {q[\"sql\"][:100]}')
"
```

### Frontend Performance (via /critic)
- Page load times per page
- Time to interactive
- Resource sizes (JS, CSS, images)

### Memory / Resource Usage
```bash
# Process memory
ps aux | grep python | grep -v grep
# Database connections
uv run python -c "from django.db import connection; print(connection.queries)"
```

## Output

```markdown
## Performance Baseline: [date]

### API Response Times
| Endpoint | Time (ms) | Size (bytes) | Status |
|----------|-----------|-------------|--------|

### Database Queries
| Operation | Query Count | Total Time (ms) | N+1? |
|-----------|-------------|-----------------|------|

### Frontend (if applicable)
| Page | Load Time (ms) | Resources | Size |
|------|---------------|-----------|------|

### Comparison (if previous baseline exists)
| Metric | Before | After | Change |
|--------|--------|-------|--------|
```

## When To Run
- Phase 4: establish baseline after implementation
- After performance optimizations: prove improvement with numbers
- Before /gate: include in PR for review
