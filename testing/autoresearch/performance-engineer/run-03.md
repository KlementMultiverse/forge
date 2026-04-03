# Run 03: Medusa - TypeScript Bundle Size, Lazy Imports, DB Query Patterns

## Target
- Repo: medusa (TypeScript/Node monorepo, yarn workspaces + Turborepo)
- Focus: bundle size, lazy imports, database query patterns

## Files Read
- `package.json` - Root monorepo config (yarn workspaces)
- `turbo.json` - Turborepo pipeline config
- `packages/medusa/src/api/admin/products/route.ts` - Product API routes
- `packages/modules/product/src/services/product-module-service.ts` - Product service
- `packages/medusa/src/loaders/index.ts` - App startup loader

## Findings

### 1. Turborepo Pipeline Lacks Caching Granularity
```json
"build": {
  "dependsOn": ["^build"],
  "outputs": ["!node_modules/**", "!src/**", "*/**"]
}
```
The output glob `*/**` is very broad. More specific output paths would improve cache hit rates. No `inputs` are specified, so any file change triggers rebuilds.

### 2. Heavy Import Chain at Startup
`packages/medusa/src/loaders/index.ts` imports 15+ framework modules eagerly:
```typescript
import { container, MedusaAppLoader, policiesLoader } from "@medusajs/framework"
import { configLoader } from "@medusajs/framework/config"
import { pgConnectionLoader } from "@medusajs/framework/database"
// ... 12 more imports
```
All loaded synchronously at startup. No dynamic `import()` for optional modules.

### 3. Large Dependency Tree
Root `package.json` has **95+ devDependencies** plus resolutions. Includes duplicated testing frameworks (jest + vitest both present), multiple bundlers (rollup + esbuild + tsup + vite), and unused-looking deps (`faker` alongside `@faker-js/faker`).

### 4. MikroORM Query Patterns
The product module service uses MikroORM repository pattern. Queries use `.find()` with proper relation loading via MikroORM's populate mechanism. No obvious N+1 at the service layer since relations are loaded through the repository.

### 5. Array `.find()` in Loops (O(n*m) Pattern)
Multiple instances of array `.find()` inside loops:
```typescript
const dbValues = dbOptions.find(({ id }) => id === opt.id)?.values || []
// inside a loop over options
```
This is O(n*m) instead of O(n) with a Map lookup. Not a DB issue but CPU overhead for large option sets.

### 6. No Bundle Analysis Tooling
Despite having `rollup-plugin-visualizer` in deps, there's no configured bundle analysis step in the build pipeline.

## Does the Current Prompt Guide Finding This?
**NO** for most findings:
- **NO** TypeScript/Node-specific patterns (startup time, import chains, bundle size)
- **NO** monorepo build optimization (Turborepo cache, inputs/outputs)
- **NO** algorithmic complexity detection (O(n*m) array operations)
- **NO** dependency audit for bloat/duplication
- **Partial** for database query patterns (mentioned generically)

## Gaps to Fix
1. Add Node.js/TypeScript-specific performance checklist (startup time, import chains, lazy loading)
2. Add monorepo build optimization patterns (cache strategies, dependency dedup)
3. Add algorithmic complexity analysis (nested loops, O(n^2) in collections)
4. Add dependency audit/bloat detection
