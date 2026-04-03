# Run 10: Explain Turborepo Build Caching (medusa)

## Source Repo: medusa
## Key Files: turbo.json, package.json (root)

## Teaching Output

### The Problem: Monorepo Builds Are Slow

Medusa has 50+ packages. A naive `yarn build` would compile all of them every time, even if you only changed one file in the `cart` module. With TypeScript compilation, that's potentially 20+ minutes of wasted time.

### What Turborepo Does

Turborepo is a build system that understands package dependencies and caches build outputs. It answers one question: "has anything changed since the last build of this package?" If not, skip it.

### How It Works: Hash-Based Caching

When you run `turbo run build`:

1. **Build the dependency graph**: Turborepo reads every `package.json` and constructs a DAG (directed acyclic graph) of which packages depend on which
2. **Hash inputs**: For each package, hash: source files + dependencies' hashes + environment variables + turbo.json config
3. **Check cache**: If this hash matches a previous build, restore the cached outputs instead of rebuilding
4. **Build only what changed**: Only packages with new hashes need to rebuild
5. **Propagate**: If `framework` changed, anything that depends on `framework` also gets a new hash and rebuilds

### Medusa's turbo.json Explained

```json
{
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["!node_modules/**", "!src/**", "*/**"]
    },
    "test": {
      "outputs": []
    }
  }
}
```

**`"dependsOn": ["^build"]`**: The `^` means "upstream." Before building `cart`, Turborepo must build everything `cart` imports from (like `framework`, `utils`). Without `^`, it would only wait for other tasks IN the same package.

**`"outputs": ["!node_modules/**", "!src/**", "*/**"]`**: What gets cached. "Everything except node_modules and src" — meaning the compiled JavaScript output (`dist/`, `build/`). When the cache hits, these outputs are restored from cache instead of recompiling.

**`"test": { "outputs": [] }`**: Tests produce no cacheable output. But Turborepo still caches the RESULT — if inputs haven't changed, it skips re-running tests and shows the previous pass/fail.

### Medusa's Build Scripts

```json
"build": "turbo run build --concurrency=100% --no-daemon"
```

- `--concurrency=100%`: Use all CPU cores. Independent packages build in parallel.
- `--no-daemon`: Don't keep a background process running (CI-friendly).

```json
"test": "turbo run test --no-daemon --no-cache --force"
```

Tests run with `--no-cache --force` — always run fresh. This makes sense: you want tests to catch regressions, not return cached "pass" results from yesterday.

### A Concrete Example

Imagine you change one file in `packages/modules/cart/src/models/cart.ts`:

| Package | Depends on cart? | Cache status | Action |
|---|---|---|---|
| `cart` | (self) | MISS (source changed) | Rebuild |
| `order` | Yes (imports cart types) | MISS (dependency changed) | Rebuild |
| `payment` | No | HIT | Skip (restore from cache) |
| `pricing` | No | HIT | Skip |
| `framework` | No (cart depends on it, not vice versa) | HIT | Skip |
| `admin` | Yes (uses cart API) | MISS | Rebuild |

Result: 3 packages rebuild instead of 50+. Build time drops from 20 minutes to 2 minutes.

### Local vs Remote Cache

Turborepo supports remote caching — upload build artifacts to a shared cache (Vercel or self-hosted). When CI builds package X, a developer who pulls the same commit gets the cached build instantly without compiling.

Medusa's config doesn't show remote cache setup, but the local cache alone saves significant time during development.

### Analogy: The Smart Kitchen

Imagine cooking for 50 people. Without caching: you prepare every dish from scratch every night. With Turborepo: you check which dishes need fresh ingredients (changed source) and which are identical to last night's version (pull from the fridge). You only cook what's new.

## Evaluation

### Did the prompt guide good pedagogy?
- **Anchor to existing knowledge**: PARTIAL - Used general "slow builds" pain point, no specific framework anchor
- **Progressive disclosure**: YES - Problem → mechanism → config → concrete example → advanced (remote cache) → analogy
- **Practical examples**: YES - Real medusa config, concrete rebuild scenario
- **Multiple explanation approaches**: YES - Config walkthrough, table, analogy
- **Verify understanding**: NO - No exercises

### Prompt Gaps Identified
1. **No instruction to include "try it yourself" commands** — the learner should be able to run `turbo run build --dry` to see the plan without executing. The prompt should require: "include a command the learner can run to observe the pattern firsthand"
2. **No instruction to ground in the specific monorepo being discussed** — I had to construct the "concrete example" myself. The prompt should instruct: "if working with a real codebase, trace through a specific change to show the pattern in action"
3. **Recurring: no mandatory exercises**
4. **No instruction to link to official docs** — web search found Turborepo docs but the prompt doesn't require providing a "further reading" section
