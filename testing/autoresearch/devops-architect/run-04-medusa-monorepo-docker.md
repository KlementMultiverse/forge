# Run 04: medusa — Monorepo Docker Strategy, Turborepo in Docker

## Source Files
- `/home/intruder/projects/medusa/turbo.json`
- `/home/intruder/projects/medusa/package.json`
- `/home/intruder/projects/medusa/packages/` (directory structure)

## Findings

### Monorepo Structure
Medusa uses Yarn workspaces with Turborepo for build orchestration:
- 10+ top-level package directories: `admin`, `cli`, `core`, `design-system`, `framework`, `medusa`, `modules`, `plugins`, etc.
- `turbo.json` defines pipeline: `build` depends on `^build` (topological dependency).
- Build outputs exclude `node_modules` and `src` — only distributable artifacts.

### Docker Strategy: No Dockerfile Found
- **No Dockerfile in the repository root** — Medusa does not ship a Dockerfile.
- This is intentional: Medusa is a framework, not a deployable application. Users create their own Dockerfile.
- The `medusa` CLI (`packages/cli/`) generates projects with their own Dockerfile.

### Turborepo Build Pipeline
```json
{
  "build": { "dependsOn": ["^build"], "outputs": ["!node_modules/**", "!src/**", "*/**"] },
  "test": { "outputs": [] },
  "test:integration": { "outputs": [] },
  "test:integration:chunk": { "outputs": [] }
}
```
- `^build` means: build dependencies before building the dependent package.
- Tests produce no output artifacts (correct — they're side-effect only).
- Integration tests support chunking (parallelization via CI matrix).

### CI Pipeline Pattern (from `.github/workflows/action.yml`)
- Build artifacts uploaded once, then downloaded by test jobs — avoids rebuilding.
- Test matrix with 4 shards for parallel unit testing.
- Uses custom GitHub Actions for caching (`cache-deps`) and server setup.
- `cancel-in-progress: true` for PR workflows — saves CI minutes.
- Turbo remote caching via `TURBO_TOKEN` and `TURBO_TEAM`.

### Relevance to DevOps Architect Agent

Monorepo patterns the agent prompt should understand:
1. **Topological builds**: Dependencies must build before dependents.
2. **Artifact passing in CI**: Build once, share artifacts across jobs.
3. **Test sharding**: Split test suites across parallel CI runners.
4. **Remote caching**: Turbo/Nx remote caching for developer and CI speed.
5. **No-Dockerfile framework**: Some projects deliberately don't include Dockerfiles.

## Gaps Identified for Agent Prompt
1. **Monorepo awareness**: Agent has no guidance for monorepo build strategies (Turborepo, Nx, Lerna). Should know when to recommend workspace-aware Docker builds.
2. **CI artifact passing**: Agent doesn't mention build-once-deploy-many or artifact upload/download patterns.
3. **Test sharding/parallelization**: Agent doesn't mention test parallelization strategies.
4. **Remote build caching**: Agent doesn't mention Turbo/Nx remote caching or Docker layer caching services.
5. **Framework vs application**: Agent should recognize when a project is a framework (no Dockerfile needed) vs an application (Dockerfile required).
