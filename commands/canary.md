# /canary — Post-Deploy Monitoring

Watch for errors, performance regressions, and page failures after deployment. The loop between "shipped" and "verified in production."

## Input
$ARGUMENTS — production URL (e.g., "https://app.example.com") and duration (default: 30 min)

## Execution

### Monitoring Loop
```
Every 5 minutes for [duration]:
  1. Health check: GET /api/health → 200?
  2. Key pages: load each page → 200? < 3s?
  3. Console errors: any JavaScript errors? (via Playwright)
  4. API latency: response times within baseline? (from /benchmark)
  5. Error rates: any 500s in the last 5 minutes?
```

### What To Watch
| Check | Threshold | Action |
|-------|-----------|--------|
| Health endpoint | 200 OK | If fail → ALERT: service down |
| Page load time | < 3 seconds | If slow → WARN: performance regression |
| JS console errors | 0 errors | If errors → create issue |
| API response time | < baseline × 1.5 | If slow → WARN: API regression |
| Error rate (5xx) | < 1% | If high → ALERT: stability issue |

### On Alert
```
ALERT detected:
  1. Capture: timestamp, URL, error details, screenshot
  2. Create GitHub Issue with label "canary,production,urgent"
  3. If critical (service down) → notify user immediately
  4. If degradation → log for next session review
```

## Output

```markdown
## Canary Report: [URL] — [duration]

### Status: [HEALTHY / DEGRADED / DOWN]

### Checks Passed: [N]/[total]

### Issues Found
- [timestamp] [severity] [description] → Issue #[N]

### Performance Trend
| Minute | Health | Latency | Errors |
|--------|--------|---------|--------|
```

## When To Run
- After Phase 5 merge (production deployment)
- Phase 6: ongoing monitoring
- On demand: after any production change
