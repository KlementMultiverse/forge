# Code Archaeologist — Autoresearch Results (10 Runs)

## Research Context

Web search findings (codebase archaeology 2025):
- **Churn + complexity hotspots**: Files changed frequently AND complex = highest risk (CodeScene method)
- **Git history mining**: code-maat, GitEvo — churn analysis, age analysis, author analysis
- **AI-powered archaeology**: LLMs for commit message analysis, pattern inference from history
- **SonarQube SQALE method**: Quantify tech debt as time-to-fix
- **Behavioral analysis**: Correlate commit frequency with complexity scores
- **Feature flag archaeology**: Dead feature flags = abandoned features = hidden tech debt

---

## Run 1: Saleor — Oldest Code, Plugin System Evolution

**Repo stats**: 4,223 Python files, 823,848 lines, 1 commit in local clone (shallow)

**Findings**:
- Plugin system: `BasePlugin` class (saleor/plugins/base_plugin.py) with chain-of-responsibility pattern
- `PluginsManager` (saleor/plugins/manager.py) orchestrates 80+ imports — god object risk
- Plugin types: avatax, sendgrid, openid_connect, webhook, user_email, admin_email
- Plugin architecture uses `previous_value` chain — hard to trace data flow

**Prompt gap**: The prompt says to map "data flow paths" but gives NO guidance on how to trace
chain-of-responsibility or middleware patterns. No mention of analyzing the plugin/extension
pattern specifically, which is one of the most common and hardest-to-analyze patterns.

---

## Run 2: Medusa — Monorepo Dependency Graph

**Repo stats**: 10 top-level packages, 30+ modules under packages/modules/

**Findings**:
- `medusa` package depends on 52 internal `@medusajs/*` packages — central hub
- Individual modules have 0 direct internal deps (use framework abstractions)
- `core-flows` imports from `@medusajs/framework/*` — proper abstraction
- Dependency inversion via `@medusajs/framework/types` and `@medusajs/framework/utils`

**Prompt gap**: No guidance on monorepo-specific analysis. No instruction to:
1. Map package dependency graph (hub-and-spoke vs mesh)
2. Identify god packages (52 deps = potential monolith-in-monorepo)
3. Analyze interface boundaries (do modules communicate via types or concrete imports?)
4. Check for version alignment across packages

---

## Run 3: Clinic-portal — Dead Code, Unused Imports, Orphaned Files

**Repo stats**: 46 Python files across 7 apps

**Findings**:
- `apps/documents/services.py` has `BEDROCK_REGION` and `BEDROCK_MODEL` defined but never used
  (lines 15-17 — leftover from Bedrock migration to direct Claude API)
- `_invoke_llm` in services.py duplicates logic in `_summarize_with_claude` in api.py
- `apps/dashboard/api.py` and `apps/dashboard/tests.py` exist but dashboard has no models
- `apps/search/chat.py` — separate from `services.py`, unclear why split

**Prompt gap**: No concrete strategies for detecting dead code. The prompt says
"Dead code indicators (unused imports, unreachable functions)" but gives NO techniques:
1. No mention of checking if defined constants/variables are actually imported elsewhere
2. No mention of cross-referencing function definitions with usages
3. No mention of orphaned files (files that nothing imports from)
4. No mention of checking for duplicate implementations (same logic in 2 places)

---

## Run 4: FastAPI-template — Abstraction Layers, Leaky Abstractions

**Repo stats**: 2,479 lines across ~45 files, clean layered architecture

**Findings**:
- Clean layers: main.py -> api/routes -> crud.py -> models.py -> core/db.py
- `deps.py` provides dependency injection (SessionDep, CurrentUser, TokenDep)
- `config.py` uses pydantic-settings with validators — good pattern
- Timing attack prevention in `authenticate()` — security-aware
- Potential leak: `core/config.py` has `SECRET_KEY = secrets.token_urlsafe(32)` as default
  — regenerates on every restart if not set via env var

**Prompt gap**: No guidance on analyzing abstraction quality:
1. No mention of checking layer violation (does route code directly import models?)
2. No mention of dependency injection pattern analysis
3. No mention of checking for leaky abstractions (implementation details crossing boundaries)
4. No mention of config security analysis (default secrets, "changethis" patterns)

---

## Run 5: Saleor — TODO/FIXME/HACK Classification

**Findings**: 69 occurrences across 50 files
- **FIXMEs in production code**: payment/models.py (missing validator), payment/utils.py (unclear save),
  discount/utils/voucher.py (code that should be shared)
- **TODOs with ticket refs**: SHOPX-914 (5 occurrences, all about translated voucher names — stale?)
- **TODOs about performance**: "load with dataloader" appears 4 times in discount/utils and order/fetch
- **Architectural TODOs**: "stop using this class in new code" (attribute/models/base.py)

**Prompt gap**: The prompt counts TODO/FIXME/HACK but doesn't instruct to:
1. Classify by category (performance, security, architecture, feature)
2. Check for stale ticket references (same ticket referenced 5+ times = likely abandoned)
3. Distinguish test TODOs from production code TODOs
4. Assess urgency based on location (TODO in auth code > TODO in test helper)
5. Look for TODO clusters (multiple in same file = systemic issue)

---

## Run 6: Medusa — Cross-Package Coupling

**Findings**:
- `@medusajs/framework` is the abstraction layer — all modules import from it
- `core-flows` depends on `@medusajs/framework/workflows-sdk`, `utils`, `types`
- Modules don't depend on each other directly — good isolation
- BUT: `packages/medusa` (main app) imports 52 internal packages = integration point

**Prompt gap**: No guidance on coupling metrics:
1. No mention of afferent/efferent coupling measurement
2. No mention of "instability" metric (Ce / (Ca + Ce))
3. No mention of identifying architectural layers vs integration layers
4. No mention of checking if abstractions (framework) are stable (low change frequency)

---

## Run 7: Clinic-portal — Data Flow, Missing Validations

**Findings**:
- API -> services -> models flow is clean
- MISSING: `DocumentIn.s3_key` is user-provided but only checked with `startswith()` — no path
  traversal prevention (../../ other_tenant/ etc.)
- MISSING: `DocumentIn.size_bytes` is user-reported but never verified against actual S3 object
- `_summarize_with_claude` in api.py reads from S3 but no file size limit check
- Double `strip_tags()` call: once in `_summarize_with_claude` (api.py:142) and again in
  `summarize_document` (api.py:409)

**Prompt gap**: No structured approach to data flow tracing:
1. No mention of input -> validation -> storage -> output trace pattern
2. No mention of checking trust boundaries (user input vs internal data)
3. No mention of verifying that user-provided metadata matches actual data
4. No mention of looking for redundant sanitization (sign of unclear data ownership)
5. No mention of checking for TOCTOU (time-of-check-time-of-use) issues

---

## Run 8: Saleor — Duplicated Business Logic

**Findings**:
- `calculate_checkout_total` appears in 3 files (checkout/calculations, plugins/manager, avatax/plugin)
- `calculate_display_gross_prices` duplicated in order/types and checkout/types
- `batch_load` pattern in 193+ files (dataloader boilerplate)
- `clean_input` in 72 files (mostly graphene mutations — expected but massive boilerplate)
- Similar price/total functions in order and checkout modules suggest shared logic that was copied

**Prompt gap**: No methodology for detecting business logic duplication:
1. No mention of semantic duplication (same logic, different variable names)
2. No mention of domain-split duplication (checkout vs order vs plugin all calculate prices)
3. No mention of boilerplate ratio analysis
4. No mention of shared-module candidates (logic that should be extracted)

---

## Run 9: FastAPI-template — Config Pattern Analysis

**Findings**:
- Single `Settings` class via pydantic-settings — excellent pattern
- Environment-aware warnings vs errors (`"changethis"` check)
- `ENVIRONMENT` literal type constraint (`local | staging | production`)
- Computed fields for CORS and DB URI — DRY
- Email config with conditional enable — good feature flagging
- Missing: no rate limiting config, no logging level config, no debug flag

**Prompt gap**: No structured config analysis checklist:
1. No mention of checking for config drift (different defaults per environment)
2. No mention of secret management patterns (how are secrets loaded?)
3. No mention of config validation (do invalid configs fail fast?)
4. No mention of checking for missing configs (what common configs are absent?)
5. No mention of config documentation (are env vars documented somewhere?)

---

## Run 10: Medusa — Abandoned Features

**Findings**:
- Feature flag system exists in `packages/core/framework/src/feature-flags/`
- 48 `@deprecated` occurrences across 25 files
- `method` deprecated in favor of `methods` in middleware types
- `listFields` deprecated in favor of `queryConfig`
- `order-promotion` link module has deprecated fields
- `workflow-engine-redis` has deprecated config patterns (7 occurrences)

**Prompt gap**: No guidance on detecting abandoned features:
1. No mention of feature flag archaeology (flags defined but never checked, or always true)
2. No mention of deprecated API detection and age analysis
3. No mention of commented-out code blocks as abandoned feature signals
4. No mention of unused route/endpoint detection
5. No mention of orphaned migration files (tables created but model removed)
6. No mention of checking if deprecated items have replacement usage

---

## Summary of ALL Gaps Found

### Major gaps (affect core analysis quality):
1. **No data flow tracing methodology** — just "data flow paths" with no how
2. **No dead code detection techniques** — just "indicators" with no strategies
3. **No duplication detection methodology** — no semantic or domain-split analysis
4. **No monorepo-specific analysis** — completely missing
5. **No config analysis checklist** — critical for security assessment
6. **No TODO/FIXME classification system** — counting without categorizing is useless

### Medium gaps (reduce insight depth):
7. **No coupling metrics** (afferent/efferent, instability)
8. **No feature flag archaeology** instructions
9. **No trust boundary analysis** for security
10. **No abstraction quality assessment** methodology
11. **No churn/hotspot analysis** using git history
12. **No deprecated code lifecycle tracking**

### Minor gaps (nice to have):
13. No boilerplate ratio measurement
14. No cross-file semantic similarity detection guidance
15. No migration/schema drift analysis
