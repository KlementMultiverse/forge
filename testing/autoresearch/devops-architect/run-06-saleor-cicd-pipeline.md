# Run 06: saleor — CI/CD Config (GitHub Actions), Test Pipeline

## Source Files
- `/home/intruder/projects/saleor/.github/workflows/tests-and-linters.yml`
- `/home/intruder/projects/saleor/.github/workflows/publish-containers.yml`
- `/home/intruder/projects/saleor/.github/workflows/` (14+ workflow files)

## Findings

### Tests & Linters Workflow (Exemplary CI)

**Trigger Configuration:**
- Runs on PR (opened, synchronize, reopened) AND push to main.
- Path filtering: only triggers on `.py`, `Dockerfile`, `saleor/**`, workflow file, `pyproject.toml`, `uv.lock`.
- This avoids unnecessary CI runs for docs-only changes — saves CI minutes.

**Concurrency Control:**
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true
```
- Cancels stale workflows when new commits are pushed to a PR. Excellent for resource efficiency.

**Permissions:**
- `permissions: {}` at top level (deny all), then `contents: read` per job. Least-privilege principle.

**Service Containers:**
- PostgreSQL 15-alpine with health check (`pg_isready`).
- Valkey 8.1-alpine with health check (`valkey-cli ping`).
- Health checks include interval, timeout, and retries — ensures services are ready before tests.

**Dependency Management:**
- Uses `astral-sh/setup-uv` with enable-cache and pinned action SHA.
- `uv sync --locked` — ensures reproducible installs.

### Container Publishing Workflow

**Multi-Platform Build:**
- Builds for both amd64 and arm64 using separate runners.
- GHCR (GitHub Container Registry) as target registry.
- Uses `docker/metadata-action` for smart tagging (PEP 440 versioning, latest detection).

**Tagging Strategy:**
- Semantic versioning: `3.22.0`, `3.22`.
- Only stable semver releases get `latest` tag.
- Branch builds get prefix-tagged (e.g., `main-abc123`).
- Compares against GitHub Releases API to determine if current build should be `latest`.

**Security:**
- OIDC for AWS/ECR login (id-token: write permission).
- Packages write permission for GHCR.
- Secrets via GitHub Environments (not inline).

**Failure Notification:**
- Slack notification on build failure via separate job.

### Full CI/CD Workflow Inventory (14+ workflows)
1. `tests-and-linters.yml` — Unit tests + linting
2. `publish-containers.yml` — Multi-platform Docker builds
3. `publish-main.yml` — Main branch publish
4. `e2e.yml` — End-to-end tests
5. `migrations-perf-test.yml` — Migration performance testing
6. `test-migrations-compatibility.yml` — Migration compatibility check
7. `graphql-inspector.yml` — Schema change detection
8. `changelog-check.yml` — Changelog verification
9. `test-semgrep-rules.yml` — Security scanning
10. `dependabot.yml` — Dependency updates
11. `stale.yml` — Stale issue management
12. Various deployment and cleanup workflows

### Patterns clinic-portal Should Adopt

| Pattern | Saleor Has It | clinic-portal Needs It |
|---|---|---|
| Path filtering on triggers | YES | YES — avoid running tests on README changes |
| Concurrency with cancel-in-progress | YES | YES — save CI minutes |
| Least-privilege permissions | YES | YES — security best practice |
| Health checks on service containers | YES | YES — prevent flaky tests |
| Pinned action versions (SHA) | YES | YES — supply chain security |
| Multi-platform builds | YES | OPTIONAL — depends on deployment target |
| Semantic version tagging | YES | YES — for container releases |
| Schema change detection | YES (GraphQL) | NO — but could validate API schema |
| Migration performance tests | YES | NO — but good practice |
| Semgrep security scanning | YES | YES — catch security issues early |

## Gaps Identified for Agent Prompt
1. **Path filtering**: Agent should recommend trigger path filtering to avoid unnecessary CI runs.
2. **Concurrency control**: Agent should recommend `cancel-in-progress` for PR workflows.
3. **Least-privilege permissions**: Agent should recommend `permissions: {}` at workflow level with per-job overrides.
4. **Service container health checks**: Agent should verify health checks on CI service containers.
5. **Action version pinning**: Agent should recommend SHA pinning for GitHub Actions (supply chain security).
6. **Schema/API change detection**: Agent should recommend API schema validation in CI.
7. **Migration testing in CI**: Agent should recommend testing migrations in CI (especially for multi-tenant).
8. **Security scanning**: Agent should recommend SAST tools (Semgrep, Bandit) in CI pipeline.
