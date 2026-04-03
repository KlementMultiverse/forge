# Run 10: Medusa - Monorepo Build Time, Dependency Deduplication

## Target
- Repo: medusa (TypeScript/Node monorepo, yarn workspaces + Turborepo)
- Focus: Build pipeline optimization, dependency management

## Files Read
- `package.json` - Root workspace config (95+ devDependencies)
- `turbo.json` - Turborepo pipeline configuration
- Various `packages/*/package.json` structures

## Findings

### 1. Turborepo Pipeline Missing Input Filters
```json
"build": {
  "dependsOn": ["^build"],
  "outputs": ["!node_modules/**", "!src/**", "*/**"]
}
```
**No `inputs` specified.** This means Turborepo hashes ALL files in each package to determine if cache is valid. Adding `inputs: ["src/**", "tsconfig.json", "package.json"]` would dramatically improve cache hit rates by ignoring test files, docs, etc.

### 2. Build Concurrency Not Configured Optimally
Root script: `"build": "turbo run build --concurrency=100% --no-daemon"`
Using `--no-daemon` means Turborepo starts fresh each time instead of keeping a warm daemon. For CI this is fine, but for local development the daemon would speed up subsequent builds.

### 3. Duplicate Testing Frameworks
Both Jest and Vitest are in devDependencies:
- `"jest": "^29.7.0"`
- `"vitest": "^3.0.5"`
Plus related deps: `@swc/jest`, `ts-jest`, `@vitest/coverage-v8`. This doubles node_modules size for testing infrastructure.

### 4. Multiple Bundler Tools
Four bundlers/transpilers in devDependencies:
- `rollup` + plugins
- `esbuild`
- `tsup` (wraps esbuild/rollup)
- `vite` (wraps esbuild/rollup)

Each adds its own dependency tree. Could consolidate to tsup + vite.

### 5. Old Faker Alongside New
```json
"faker": "^5.5.3",
"@faker-js/faker": "^9.2.0",
```
The old `faker` package was compromised and deprecated. Having both wastes space and is a security concern.

### 6. Yarn 3.2.1 (Not Latest)
```json
"packageManager": "yarn@3.2.1"
```
Yarn 4.x has significant performance improvements for workspace resolution and installation. Upgrading could reduce install times by 30-50%.

### 7. No Workspace Protocol for Internal Deps
Without `workspace:*` protocol visible in the root, internal packages may resolve from npm registry instead of local workspace, causing unnecessary downloads.

### 8. `globalDependencies` Only Tracks turbo.json
```json
"globalDependencies": ["turbo.json"]
```
Missing `.env`, `tsconfig.base.json`, and root `package.json` as global dependencies. Changes to these files won't invalidate Turborepo cache.

## Does the Current Prompt Guide Finding This?
**NO** for build/CI patterns:
- **NO** build pipeline optimization patterns
- **NO** dependency audit for bloat/duplication
- **NO** package manager version awareness
- **NO** monorepo cache strategy (Turborepo inputs/outputs/globalDeps)
- **NO** CI vs local development optimization differences

## Gaps to Fix
1. Add build pipeline optimization section
2. Add dependency audit checklist (duplicates, deprecated packages, unused deps)
3. Add monorepo-specific build cache optimization
4. Add CI/CD performance patterns
