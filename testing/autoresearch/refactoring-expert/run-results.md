# Autoresearch: refactoring-expert — 10-Run Results

## Web Research Summary

### Code Smell Detection Patterns 2025
- **AST + ML hybrid**: Structural metrics + AST analysis + Q-learning for autonomous detection
- **LLM-based detection**: SmellDetector covers 20+ smell types (class-level + method-level)
- **Smell interactions**: Pairs of smells interact frequently — resolving interacting smells matters more than isolated ones
- **Key smells 2025 focus**: Long Method, God Class, Feature Envy, Shotgun Surgery, Primitive Obsession, Data Clumps

### Refactoring Anti-Patterns for AI Agents
- **Refactoring avoidance**: AI agents avoid structural refactoring 80-90% of the time — just add code where asked
- **Complexity reshuffling**: Without objective metrics, agents do minor polish instead of real improvements
- **Large function fragility**: Legacy functions too large for reliable AI refactoring — high error rates
- **Missing: monorepo-specific patterns** — duplication across packages, shared utility extraction
- **Missing: language-specific idioms** — Python vs TypeScript vs Go patterns differ significantly

---

## Run 1: clinic-portal — apps/documents/api.py (471 lines)

### Smells Found
1. **God Function** (lines 24-153): `_summarize_with_claude()` is 130 lines — handles S3 fetch, content-type mapping, base64 encoding, API call construction, response parsing, markdown stripping — at least 5 distinct responsibilities
2. **Inline imports** (lines 31-33, 143-144): `import base64`, `import re`, `from django.utils.html import strip_tags` inside function body — makes dependencies opaque
3. **Mixed abstraction levels**: API route handlers (`create_document`) contain direct ORM calls, cache management, audit logging, and action tracking — all in one function
4. **Repeated pattern**: Every endpoint does `try: X.objects.get(pk=id) except X.DoesNotExist: return 404` — duplicated 4 times
5. **Hardcoded API URL**: `"https://api.anthropic.com/v1/messages"` in function body — should be config

### Prompt Coverage
- God Function: PARTIALLY covered ("File exceeds 300 lines -> split by responsibility") but no guidance on function-level splitting
- Inline imports: NOT covered
- Mixed abstraction: PARTIALLY covered (mentions SOLID but no concrete "business logic in views" detection)
- Repeated ORM pattern: Covered under "duplication elimination"
- Hardcoded config: NOT covered

### Gaps Identified
- **GAP-1**: No function-level complexity threshold (only file-level 300 lines)
- **GAP-2**: No detection of inline/deferred imports as a smell
- **GAP-3**: No "business logic in API handlers" smell detection

---

## Run 2: saleor — God Classes

### Smells Found
1. **God Class**: `WebhookPlugin` (plugin.py, 3661 lines, 206 methods) — handles ALL webhook event types as individual methods. Classic "one class does everything" pattern
2. **God Class**: `PluginsManager` (manager.py, 2869 lines, 210 methods) — orchestrates all plugin execution with massive method surface area
3. **Delegating boilerplate**: WebhookPlugin has ~150 methods that follow identical pattern: `def X_event(self, ...) -> None: trigger_webhooks_async(...)` — each is 5-15 lines of near-identical code
4. **Long import lists**: plugin.py has 127 lines of imports before any code — sign of excessive coupling

### Prompt Coverage
- God Class: Mentioned in Chaos Resilience but only as "File exceeds 300 lines -> split into modules"
- Boilerplate duplication: Covered under "eliminate duplication"
- Import coupling: NOT covered

### Gaps Identified
- **GAP-4**: No metric for God Class detection (e.g., >20 methods, >1000 lines)
- **GAP-5**: No guidance on "delegate-and-dispatch" pattern as refactoring target
- **GAP-6**: No import complexity analysis (import count as coupling smell)

---

## Run 3: fastapi-template — DI Patterns & Service Layer

### Smells Found
1. **Missing service layer**: Route handlers in `items.py` contain raw SQLModel queries (lines 22-42), ORM operations directly in views — no service abstraction
2. **Inconsistent CRUD usage**: `users.py` uses `crud.create_user()` but `items.py` does `session.add(item)` directly (line 69) — CRUD module exists but is underused
3. **Repeated authorization checks**: Permission check `if not current_user.is_superuser and (item.owner_id != current_user.id)` duplicated 3 times in items.py (lines 55, 88-89, 108-109)
4. **DI done well**: `SessionDep` and `CurrentUser` annotated dependencies are clean — this is a positive pattern to recognize

### Prompt Coverage
- Missing service layer: NOT covered (no mention of "business logic in route handlers")
- Inconsistent patterns: PARTIALLY covered (mentions quality metrics but not cross-file consistency analysis)
- Repeated auth checks: Covered under duplication

### Gaps Identified
- **GAP-7**: No "architecture smell" detection — service layer absence, fat controllers/views
- **GAP-8**: No cross-file consistency analysis guidance

---

## Run 4: medusa — TypeScript Monorepo Duplication

### Smells Found
1. **Structural duplication**: `events.ts` pattern duplicated across `fulfillment/src/utils/events.ts` and `product/src/utils/events.ts` — same `moduleEventBuilderFactory` boilerplate, different constants
2. **Well-abstracted shared utils**: `@medusajs/framework/utils` provides `moduleEventBuilderFactory`, `CommonEvents` — the framework layer is good, but each module still has repetitive builder calls
3. **Order service god file**: `order-module-service.ts` at 4426 lines — massive service class

### Prompt Coverage
- Monorepo structural duplication: NOT covered
- Good abstraction recognition: NOT covered (prompt never mentions recognizing and preserving good patterns)
- TypeScript-specific patterns: NOT covered at all

### Gaps Identified
- **GAP-9**: No monorepo-specific duplication detection guidance
- **GAP-10**: No multi-language awareness (prompt is language-agnostic but real smells are language-specific)
- **GAP-11**: No guidance on recognizing GOOD patterns to preserve (not just smells)

---

## Run 5: clinic-portal — apps/search/services.py (439 lines)

### Smells Found
1. **Duplicated LLM call pattern**: `rewrite_query()` (lines 36-135) and `summarize_search_results()` (lines 323-421) both contain identical urllib.request + API call + response parsing — should be a shared `_call_claude()` helper
2. **Mixed sync/async**: Module has async functions (`_fetch_clinical_trials`, `_fetch_pubmed_papers`) with sync wrapper (`run_search`) — the event loop detection (lines 308-320) is fragile
3. **Hardcoded API URLs**: `CLINICAL_TRIALS_URL`, `PUBMED_SEARCH_URL`, `PUBMED_SUMMARY_URL` at module level — fine, but the Anthropic API URL is hardcoded inside function bodies
4. **Cache key construction duplication**: `f"search:{type}:{hashlib.md5(query.encode()).hexdigest()[:12]}"` pattern repeated 3 times

### Prompt Coverage
- LLM call duplication: Covered under "eliminate duplication"
- Mixed sync/async: NOT covered
- Cache key duplication: Covered under duplication
- Hardcoded config: NOT covered

### Gaps Identified
- **GAP-12**: No detection of async/sync mixing as a smell
- **GAP-13**: No recognition of "extract shared infrastructure" (like API client wrappers)

---

## Run 6: saleor — Circular Imports & Import Graph

### Smells Found
1. **TYPE_CHECKING guards everywhere**: 147 files use `if TYPE_CHECKING:` — this is a coping mechanism for circular imports, not a fix
2. **Deep relative imports**: plugin.py uses `from ...webhook.transport.asynchronous.transport import ...` — 3+ levels deep
3. **No true cross-module cycles found**: Saleor actually handles this well with TYPE_CHECKING + deferred imports — but the coping mechanism itself is a smell indicator
4. **Import list explosion**: plugin.py has 127 import lines — indicates the class depends on too many things

### Prompt Coverage
- Circular dependencies: Covered ("map the dependency graph, propose extraction order")
- TYPE_CHECKING as code smell: NOT covered
- Deep relative imports: NOT covered
- Import list size: NOT covered

### Gaps Identified
- **GAP-14**: No guidance on `TYPE_CHECKING` proliferation as a coupling indicator
- **GAP-15**: No import depth or import count thresholds

---

## Run 7: fastapi-template — Error Handling Consistency

### Smells Found
1. **Inconsistent HTTP status codes**: Login uses 400 for "incorrect password" (line 34), deps.py uses 403 for "could not validate credentials" (line 38) — similar auth failures, different codes
2. **No custom exception classes**: Every error is a raw `HTTPException(status_code=N, detail="string")` — 29 instances across 4 files, no exception hierarchy
3. **Magic status code strings**: Status codes are scattered literals (400, 403, 404, 409) — no centralized error catalog
4. **No error logging in routes**: Route handlers raise HTTPException but don't log the context — makes debugging hard

### Prompt Coverage
- Inconsistent patterns: PARTIALLY covered (mentions quality metrics)
- Missing exception hierarchy: NOT covered
- Error handling consistency: NOT covered explicitly

### Gaps Identified
- **GAP-16**: No "error handling consistency" check across a codebase
- **GAP-17**: No guidance on detecting missing exception hierarchies
- **GAP-18**: No "magic values" detection (scattered status codes, hardcoded strings)

---

## Run 8: medusa — Shared Utility Duplication in Monorepo

### Smells Found
1. **Event builder boilerplate**: Each module creates its own `eventBuilders` object using the same `moduleEventBuilderFactory` pattern — the factory exists in core, but the declaration pattern is duplicated
2. **Module service pattern duplication**: Each module has a `*-module-service.ts` that follows identical structure (constructor, CRUD methods, event emission) — could benefit from code generation or base class
3. **Well-centralized shared utils**: `@medusajs/framework/utils` is properly used as the shared utility package — this is the RIGHT pattern (monorepo has a core/utils package)

### Prompt Coverage
- Boilerplate across packages: NOT specifically covered for monorepos
- Code generation opportunities: NOT covered
- Recognizing good patterns: NOT covered

### Gaps Identified
- **GAP-19**: No "code generation opportunity" detection — when boilerplate is structurally identical but parameterized
- **GAP-9 confirmed**: Monorepo-specific guidance still missing

---

## Run 9: clinic-portal — apps/workflows/api.py (510 lines)

### Smells Found
1. **Business logic in views**: Every workflow/task endpoint contains direct ORM calls, cache invalidation, audit logging, and action tracking — 4 concerns in each handler
2. **Repeated CRUD pattern**: `create_workflow`, `update_workflow`, `delete_workflow`, `create_task`, `update_task` all follow: validate -> ORM op -> AuditLog.create -> cache.delete -> track_action -> return. This is a cross-cutting concern that should be middleware or decorator
3. **Cache invalidation shotgun surgery**: `cache.delete("dashboard:stats")` appears 7 times, `cache.delete("workflows:list")` appears 4 times — any new endpoint must remember to add these
4. **No transaction wrapping**: ORM operations + AuditLog creation are not in an atomic transaction — if AuditLog.create fails, the entity change persists without audit

### Prompt Coverage
- Business logic in views: NOT covered explicitly
- Repeated CRUD ceremony: Covered under duplication but not as "cross-cutting concern extraction"
- Shotgun surgery: NOT covered by name
- Missing transactions: NOT covered (this is actually a correctness bug, not just a smell)

### Gaps Identified
- **GAP-20**: No "shotgun surgery" detection — changes that require touching many files
- **GAP-21**: No "cross-cutting concern" detection (audit, cache, logging baked into every handler)
- **GAP-22**: No transaction safety check during refactoring analysis

---

## Run 10: saleor — Dead Code, Unused Imports

### Smells Found
1. **Minimal unused imports**: Only 4 potentially unused imports found in non-test code — saleor is well-maintained
2. **base_plugin.py (1905 lines)**: Contains 170+ abstract/hook method signatures — acts as an interface definition, but at 1905 lines it's unwieldy
3. **Defensive TYPE_CHECKING imports**: 147 files use this pattern — while it prevents circular imports at runtime, it indicates a design where modules know too much about each other

### Prompt Coverage
- Dead code detection: Covered ("If you find dead code -> /learn")
- Unused imports: PARTIALLY covered (mentioned in Learning section but not as explicit detection step)
- Interface bloat: NOT covered

### Gaps Identified
- **GAP-23**: No "interface bloat" detection (large abstract base classes)
- **GAP-24**: No explicit "run unused import detection" step in the analysis workflow

---

## Summary of ALL Gaps

| # | Gap | Severity | Fix |
|---|-----|----------|-----|
| GAP-1 | No function-level complexity threshold | HIGH | Add: functions >50 lines or cyclomatic complexity >10 |
| GAP-2 | No inline/deferred import detection | MEDIUM | Add to smell catalog |
| GAP-3 | No "business logic in API handlers" detection | HIGH | Add as architecture smell |
| GAP-4 | No God Class metric threshold | HIGH | Add: >20 public methods or >500 lines |
| GAP-5 | No delegate-and-dispatch pattern detection | LOW | Add to pattern catalog |
| GAP-6 | No import complexity analysis | MEDIUM | Add: >30 imports = coupling smell |
| GAP-7 | No architecture smell detection | HIGH | Add: fat controllers, missing service layer |
| GAP-8 | No cross-file consistency analysis | MEDIUM | Add as analysis step |
| GAP-9 | No monorepo-specific duplication | MEDIUM | Add monorepo section |
| GAP-10 | No multi-language smell awareness | LOW | Add language-specific hints |
| GAP-11 | No "preserve good patterns" guidance | MEDIUM | Add recognition step |
| GAP-12 | No async/sync mixing detection | LOW | Add to smell catalog |
| GAP-13 | No "extract shared infrastructure" guidance | MEDIUM | Add infrastructure duplication |
| GAP-14 | No TYPE_CHECKING proliferation detection | LOW | Add as coupling indicator |
| GAP-15 | No import depth/count thresholds | LOW | Add metrics |
| GAP-16 | No error handling consistency check | HIGH | Add as analysis step |
| GAP-17 | No missing exception hierarchy detection | MEDIUM | Add to smell catalog |
| GAP-18 | No magic values detection | MEDIUM | Add to smell catalog |
| GAP-19 | No code generation opportunity detection | LOW | Add to advanced patterns |
| GAP-20 | No shotgun surgery detection | HIGH | Add as named smell |
| GAP-21 | No cross-cutting concern detection | HIGH | Add: audit, cache, logging in handlers |
| GAP-22 | No transaction safety analysis | MEDIUM | Add correctness check |
| GAP-23 | No interface bloat detection | LOW | Add to God Class section |
| GAP-24 | No explicit unused import detection step | LOW | Add to workflow |
