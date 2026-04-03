# Run 07: medusa — Supply chain (package.json, lockfile integrity)

## Target
- Repo: `/home/intruder/projects/forge-test-repos/medusa`
- Scope: `package.json`, lockfile, dependency risks

## Files Examined
- `package.json` — root workspace with devDependencies and resolutions
- `yarn.lock` — lockfile present (verified exists)

## Security Findings

### 1. Deprecated/hijacked `faker` package in devDependencies (HIGH)
- **File**: `package.json:93`
- `"faker": "^5.5.3"` — This is the Marak Squires package that was famously sabotaged (v6.6.6 contained `console.log` spam and infinite loops). The package is deprecated and should be replaced entirely with `@faker-js/faker` (which is also present at `"^9.2.0"`).
- Even as devDependency, it's a supply chain risk: any CI/CD running `yarn install` downloads and could execute postinstall scripts.

### 2. No `.npmrc` or `.yarnrc.yml` with registry restrictions (MEDIUM)
- No evidence of scope-restricted registries. Internal `@medusajs/` packages could be vulnerable to dependency confusion if an attacker publishes same-named packages to npm public registry.
- **Note**: Medusa is published to npm themselves, so this is lower risk, but for forks/private deployments it matters.

### 3. `import-from` package in production dependencies (LOW)
- **File**: `package.json:168`
- `"import-from": "^3.0.0"` in both dependencies and devDependencies. This package dynamically imports modules from arbitrary paths, which could be a code execution vector if user input reaches it.

### 4. Lockfile exists (GOOD)
- `yarn.lock` is present and committed, ensuring reproducible builds.

### 5. Resolutions patch known issues (GOOD)
- `"semver": "^7.5.2"` — resolves known ReDoS vulnerability in older semver.
- `"axios": "^1.13.1"` — forces modern axios.
- `"validator": "^13.15.20"` — forces latest validator.

### 6. Old `pg-god` package (LOW)
- **File**: `package.json:104`
- `"pg-god": "^1.0.12"` — small, infrequently maintained package for test database creation. Low risk but adds attack surface.

## Agent Prompt Evaluation

| Finding | Would prompt guide to this? | Notes |
|---|---|---|
| Hijacked faker package | NO | Prompt has no supply chain guidance |
| No registry restrictions | NO | Not mentioned |
| import-from dynamic imports | NO | No guidance on dangerous npm packages |
| Lockfile integrity | NO | Not mentioned |
| Resolutions/patches | NO | No guidance on evaluating dep patches |

## GAPs Identified
1. **GAP: No supply chain security section** — needs: check for known hijacked packages (colors, faker, event-stream, ua-parser-js), verify lockfile committed, check for registry scope restrictions, audit `postinstall` scripts
2. **GAP: No guidance on evaluating `resolutions`/`overrides`** — these are security-relevant and should be reviewed
