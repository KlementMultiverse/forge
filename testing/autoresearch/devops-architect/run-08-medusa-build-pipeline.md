# Run 08: medusa — package.json Scripts, Build Pipeline

## Source Files
- `/home/intruder/projects/medusa/package.json`
- `/home/intruder/projects/medusa/turbo.json`
- `/home/intruder/projects/medusa/.github/workflows/action.yml`
- `/home/intruder/projects/medusa/.github/actions/cache-deps/action.yml`
- `/home/intruder/projects/medusa/.github/actions/setup-server/action.yml`

## Findings

### Build Pipeline Architecture

**Turborepo Orchestration:**
- Topological build ordering via `"dependsOn": ["^build"]`.
- Build outputs exclude source and node_modules — only compiled artifacts.
- Turbo remote caching via `TURBO_TOKEN` + `TURBO_TEAM` — shared build cache across CI and developers.
- `globalDependencies: ["turbo.json"]` — cache invalidates when turbo config changes.

**CI Pipeline Pattern (action.yml):**

Phase 1: Setup
- Checkout with `fetch-depth: 0` (full history for change detection).
- `./scripts/assert-changed-files-actions.sh "packages"` — skip CI if no package changes.
- Custom `cache-deps` action for Yarn dependency caching.
- Build artifacts uploaded via `actions/upload-artifact`.

Phase 2: Unit Tests (Matrix Strategy)
- 4 shards (`matrix.shard_index: [1, 2, 3, 4]`).
- Each shard downloads build artifacts (not rebuilds).
- CPU core detection for optimal Jest parallelization.
- `fail-fast: true` — stop all shards if one fails.

Phase 3: Integration Tests (Separate)
- Server setup via custom action.
- Database-backed tests for CLI and server.
- Separate workflows for specific modules.

### Key Patterns

1. **Build once, test many**: Artifacts built in setup job, downloaded by test jobs. Avoids rebuilding per shard.
2. **Change detection**: Script checks if relevant files changed before running full pipeline.
3. **Custom composite actions**: Reusable actions for common steps (cache-deps, setup-server, test-server).
4. **Shard-based parallelization**: Tests split across 4 runners for ~4x speedup.
5. **Turbo remote caching**: Builds cached in the cloud — if a package hasn't changed, its build is skipped.

### Workflow Inventory (Key Workflows)
- `action.yml` — Main pipeline (build + test)
- `release.yml` — Release automation
- `test-cli-with-database.yml` — CLI integration tests
- `oas-test.yml` — OpenAPI spec validation
- `admin-i18n-validation.yml` — Admin translation checks
- `docs-test.yml` — Documentation tests
- `claude.yml` — Claude Code integration (interesting!)

### Patterns Relevant to DevOps Architect Agent

| Pattern | Medusa Uses It | Agent Should Know |
|---|---|---|
| Build-once-test-many | YES | YES — avoid redundant builds |
| Test sharding | YES | YES — for large test suites |
| Change detection / affected filtering | YES | YES — save CI minutes |
| Custom composite actions | YES | YES — DRY principle for CI |
| Remote build caching | YES | YES — Turbo, Nx, or Docker layer cache |
| Artifact upload/download between jobs | YES | YES — standard CI pattern |
| OpenAPI spec validation | YES | YES — API contract testing |
| fail-fast matrix | YES | YES — fast feedback on failures |

## Gaps Identified for Agent Prompt
1. **Build-once-test-many**: Agent should recommend this pattern for any multi-job CI pipeline.
2. **Change detection**: Agent should recommend affected/changed file detection to skip unnecessary CI work.
3. **Custom composite actions**: Agent should recommend extracting repeated CI steps into reusable actions.
4. **API contract testing**: Agent should recommend OpenAPI/schema validation in CI.
5. **Remote build caching**: Agent should be aware of Turbo, Nx, and Docker layer caching services (BuildKit, GitHub Actions cache).
6. **Test sharding strategies**: Agent should recommend test splitting for large test suites (Jest --shard, pytest-split, etc.).
