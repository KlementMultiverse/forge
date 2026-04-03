# Run 07: fastapi-template — CI Pipeline, Pre-commit Config

## Source Files
- `/home/intruder/projects/fastapi-template/.github/workflows/tests.yml`
- `/home/intruder/projects/fastapi-template/.github/workflows/linting.yml`
- `/home/intruder/projects/fastapi-template/.github/workflows/type-checking.yml`

## Findings

### CI Workflows (3 Separate Workflows)

**Tests Workflow:**
- Trigger: `on: [push, pull_request]` — no path filtering, runs on every push/PR.
- Python 3.11 (not 3.12).
- Uses `pip install uv` then `uv pip install -e ".[dev]"` — hybrid approach, not pure uv.
- No service containers (no database, no Redis in CI tests).
- Single job, no parallelization.
- ISSUE: `SECRET_KEY: test-secret-key-for-testing-only` as env var — OK for tests but visible in logs.

**Linting Workflow:**
- Same structure as tests: Python 3.11, pip install uv, uv pip install dev deps.
- Runs `uv run ruff check src` — only linting, no formatting check.
- ISSUE: No path filtering.
- ISSUE: Does not run `black --check` — only Ruff.

**Type-checking Workflow (inferred from name):**
- Likely runs mypy or pyright.
- Separate workflow — good separation of concerns.

### Pre-commit Config
- No `.pre-commit-config.yaml` found in the repository.
- However, saleor has pre-commit cache in its devcontainer compose.
- ISSUE: No local pre-commit hooks means all checks happen only in CI (slower feedback loop).

### Comparison: fastapi-template CI vs saleor CI

| Feature | saleor | fastapi-template |
|---|---|---|
| Path filtering | YES | NO |
| Concurrency control | YES | NO |
| Permissions scoping | YES (least-privilege) | NO (default) |
| Service containers | YES (PG + Redis) | NO |
| Health checks | YES | N/A |
| Dependency caching | YES (uv cache) | NO |
| Action version pinning | YES (SHA) | NO (v4/v5 tags) |
| Test parallelization | YES (partial) | NO |
| Pre-commit hooks | YES (cached) | NO |

### What clinic-portal Could Learn

fastapi-template's CI is minimal — useful as a "minimum viable CI" template:
1. Separate workflows per concern (test, lint, type-check).
2. `uv run` for command execution in CI.

But it has many anti-patterns:
1. No path filtering wastes CI minutes.
2. No dependency caching — every run reinstalls everything.
3. No database in CI — tests that need DB won't run.
4. No concurrency control.

## Gaps Identified for Agent Prompt
1. **Pre-commit hooks**: Agent should check for `.pre-commit-config.yaml` and recommend it if missing. Local checks provide faster feedback than CI-only checks.
2. **Dependency caching in CI**: Agent should verify CI uses caching (actions/cache or tool-specific caching like `setup-uv` with `enable-cache`).
3. **Service containers for integration tests**: Agent should recommend service containers when the app depends on databases/caches.
4. **Workflow triggers optimization**: Agent should flag `on: [push, pull_request]` without path filtering as wasteful.
5. **Formatting check in CI**: Agent should verify both linting AND formatting checks are in CI (ruff check + ruff format --check, or black --check).
