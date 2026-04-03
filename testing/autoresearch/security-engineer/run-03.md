# Run 03: medusa — Node.js prototype pollution, eval() usage, dependency confusion risks

## Target
- Repo: `/home/intruder/projects/forge-test-repos/medusa`
- Scope: Prototype pollution, eval(), supply chain

## Files Examined
- `package.json` — root workspace package.json
- Various `packages/modules/order/src/services/order-module-service.ts` — prototype manipulation
- `packages/medusa/src/loaders/api.ts` — qs.parse usage

## Security Findings

### 1. Prototype manipulation in order module (MEDIUM)
- **File**: `packages/modules/order/src/services/order-module-service.ts:146-184`
- **Issue**: Direct `.prototype` assignment on MikroORM entities:
  ```
  MikroORMEntity.prototype["onInit_OrderChangeAction"] = function () { ... }
  ```
- This is legitimate ORM initialization, NOT pollution, but the pattern of direct prototype assignment is flagged because it bypasses TypeScript type checking.

### 2. qs.parse with arrayLimit: Infinity (HIGH)
- **File**: `packages/medusa/src/loaders/api.ts:23`
- `req.query = qs.parse(queryParamsStr, { arrayLimit: Infinity })`
- **Issue**: `arrayLimit: Infinity` means query strings can create arrays of arbitrary size, enabling memory exhaustion attacks. An attacker can send `?a[999999]=x` to allocate a sparse array.

### 3. No eval() usage found (GOOD)
- Grep for `eval(` found no results in source code (only in test fixtures/mocks).

### 4. Dependency confusion risks (MEDIUM)
- **File**: `package.json`
- Uses `yarn` workspaces with internal packages under `@medusajs/` scope.
- `faker: "^5.5.3"` is listed alongside `@faker-js/faker: "^9.2.0"` — the old `faker` package was famously hijacked (colors/faker incident). Still in devDependencies.
- No `.npmrc` or `.yarnrc` restricting registry scopes.

### 5. No `__proto__` pollution vectors found (GOOD)
- No direct `__proto__` manipulation in source code.

## Agent Prompt Evaluation

| Finding | Would prompt guide to this? | Notes |
|---|---|---|
| Prototype manipulation | NO | Prompt has no Node.js/JS-specific security patterns |
| qs.parse arrayLimit | NO | No guidance on query parsing DoS |
| No eval() | PARTIAL | Prompt could find via grep but doesn't specifically mention eval() |
| Dependency confusion | NO | No supply chain security guidance at all |
| __proto__ pollution | NO | Not mentioned in prompt |

## GAPs Identified
1. **GAP: No Node.js/JavaScript-specific security checklist** — needs: prototype pollution, eval/Function constructor, qs parsing limits, template injection
2. **GAP: No supply chain security guidance** — needs: check for hijacked/deprecated packages, registry scope restrictions, lockfile integrity, dependency confusion risks
3. **GAP: No DoS-via-input-parsing guidance** — needs: check array limits, object depth limits, string length limits in parsers
