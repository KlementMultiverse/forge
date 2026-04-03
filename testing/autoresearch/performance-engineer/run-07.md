# Run 07: Medusa - Node.js Event Loop Blocking, Memory Leaks

## Target
- Repo: medusa (TypeScript/Node monorepo)
- Focus: Event loop blocking, synchronous operations, memory patterns

## Files Read
- `packages/medusa/src/commands/develop.ts` - Dev server
- `packages/medusa/src/loaders/index.ts` - App loader
- `packages/medusa/src/commands/utils/dev-server/reloaders/modules.ts` - Module reloader
- `packages/medusa/src/api/store/products/helpers.ts` - Product helpers

## Findings

### 1. execSync in Production-Adjacent Code
```typescript
// packages/medusa/src/commands/develop.ts
execSync(`taskkill /PID ${this.childProcess.pid} /F /T`)
```
`execSync` blocks the Node.js event loop completely. While this is in a CLI command (not API handler), it's in the develop server process. If this runs during hot reload, it blocks all pending requests.

### 2. require.cache Enumeration in Hot Reload
```typescript
// packages/medusa/src/commands/utils/dev-server/reloaders/modules.ts
Object.keys(require.cache).forEach((cachedPath) => { ... })
```
Iterating the entire `require.cache` on every module reload. For large applications with 1000+ cached modules, this is O(n) on every file change during development.

### 3. Nested forEach with Product Variants (O(n*m))
```typescript
products.forEach((product) => {
    product.variants?.forEach((variant) => { ... })
})
```
In `api/store/products/helpers.ts`, products and their variants are iterated with nested loops for tax calculation. With 100 products * 10 variants = 1000 iterations per request. Not catastrophic but scales poorly.

### 4. Promise.all for Parallel Reloaders (Good)
```typescript
await Promise.all(reloaders.map(async (reloader) => reloader()))
```
Properly parallelizes independent reload operations.

### 5. No Explicit Memory Cleanup for Long-Running Processes
The medusa server loader creates multiple containers, database connections, and event bus subscriptions. No explicit cleanup/dispose patterns visible for graceful shutdown, which could lead to memory leaks on restarts in development.

### 6. Synchronous Container Resolution at Startup
```typescript
const query = req.scope.resolve(ContainerRegistrationKeys.QUERY)
```
Container resolution per-request is synchronous. If resolution involves lazy initialization, it blocks the event loop briefly on first access.

## Does the Current Prompt Guide Finding This?
**NO** for Node.js-specific patterns:
- **NO** event loop blocking detection (execSync, heavy sync operations)
- **NO** memory leak patterns for Node.js (uncleaned listeners, closures, caches)
- **NO** Node.js-specific profiling tools (clinic.js, 0x, --inspect)
- **NO** hot reload performance patterns
- **NO** container/DI resolution overhead analysis

## Gaps to Fix
1. Add Node.js event loop blocking detection (execSync, CPU-heavy sync code)
2. Add memory leak detection patterns (listeners, closures, growing caches)
3. Add Node.js-specific profiling tool recommendations
4. Add container/DI resolution overhead analysis
