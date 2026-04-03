# Run 03: Explain TypeScript Monorepo Patterns to Single-Repo Developer

## Source Repo: medusa
## Key Files: package.json (root), turbo.json, packages/modules/*/package.json

## Teaching Output

### What You Already Know (Single-Repo Anchor)

In a single-repo project, you have one `package.json`, one `node_modules`, one build command. Everything lives together. When your project grows to 50+ modules, you hit problems:
- Changing one utility rebuilds the entire app
- Teams step on each other's code
- CI takes 30 minutes because it runs everything

A monorepo keeps everything in one git repo but treats each folder as an independent package.

### How Medusa Organizes Its Monorepo

```
medusa/
  package.json          # Root: workspaces config + shared dev deps
  turbo.json            # Build orchestration
  packages/
    medusa/             # Main API server (its own package.json)
    modules/
      cart/             # Cart module (its own package.json)
      order/            # Order module (its own package.json)
      payment/          # Payment module (its own package.json)
    core/               # Shared utilities
    framework/          # Framework abstractions
    admin/              # Dashboard UI
```

### Layer 1: Workspaces (package.json)

The root `package.json` declares which folders are packages:

```json
{
  "workspaces": {
    "packages": [
      "packages/medusa",
      "packages/modules/*",
      "packages/core/*",
      "packages/framework/*"
    ]
  }
}
```

This tells Yarn: "each of these folders has its own `package.json` — manage their dependencies together but treat them as separate packages." When `cart` imports from `@medusajs/framework/utils`, Yarn symlinks it from the local `packages/framework` folder instead of downloading from npm.

**Single-repo equivalent**: Imagine if every folder in your `src/` had its own `package.json` and could be published to npm independently.

### Layer 2: Turborepo (turbo.json)

Turborepo is the build orchestrator. Here's medusa's config:

```json
{
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["!node_modules/**", "!src/**", "*/**"]
    },
    "test": { "outputs": [] }
  }
}
```

`"dependsOn": ["^build"]` means: "before building package X, build all packages that X depends on." The `^` means "upstream dependencies." So if `cart` depends on `framework`, Turborepo builds `framework` first.

**Single-repo equivalent**: Like having a Makefile where each target depends on other targets, but Turborepo figures out the dependency graph automatically from `package.json`.

### Layer 3: Build Caching

This is Turborepo's killer feature. When you run `turbo run build`:

1. Turborepo hashes each package's source files + dependencies
2. If nothing changed in `cart/` since last build, it skips the build entirely
3. Only changed packages (and their dependents) rebuild

From medusa's scripts:
```json
"build": "turbo run build --concurrency=100% --no-daemon"
```

`--concurrency=100%` means "build as many packages in parallel as the CPU allows." Independent packages (cart and payment don't depend on each other) build simultaneously.

### Mental Model: Monorepo = City, Packages = Buildings

| Single Repo | Monorepo |
|---|---|
| One building, many rooms | Many buildings, shared infrastructure |
| Renovate one room = repaint whole building | Renovate one building = only that building |
| One front door (entry point) | Each building has its own entrance |
| One architect (build config) | City planner (Turborepo) coordinates |

## Evaluation

### Did the prompt guide good pedagogy?
- **Anchor to existing knowledge**: YES - Single-repo baseline throughout
- **Progressive disclosure**: YES - Layers 1-2-3 build sequentially, each adding complexity
- **Practical examples**: YES - Real medusa config files
- **Multiple explanation approaches**: YES - Code, table, analogy (city/buildings)
- **Verify understanding**: NO - No exercises

### Prompt Gaps Identified
1. **No instruction to use layered/numbered progression** — I naturally did "Layer 1, 2, 3" but the prompt doesn't instruct this pattern. It should say: "when explaining multi-part systems, number the layers and build sequentially"
2. **No instruction to provide a 'try it yourself' section** — the prompt mentions exercises in Focus Areas but doesn't mandate them in every output
3. **Analogy quality**: The city/buildings analogy works but the prompt doesn't instruct "provide at least one real-world analogy for abstract concepts"
