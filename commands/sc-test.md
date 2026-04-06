# /sc:test — Full Test Suite + Coverage

Run the complete test suite with coverage reporting.

## What It Does

1. Run unit tests (all apps)
2. Run integration tests (if available)
3. Run e2e tests (if Playwright available)
4. Generate coverage report
5. Check coverage threshold (warn if < 80%)

## Commands (Django)
```bash
uv run python manage.py test
uv run python manage.py test --verbosity 2
```

## Output
- Test results: PASS/FAIL count
- Coverage percentage per app
- Uncovered lines report
