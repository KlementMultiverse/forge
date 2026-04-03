# Code Archaeologist — Autoresearch Changelog

## 2026-04-02: Karpathy-style improvement loop (10 test runs)

### Test repos used:
- saleor (Django + GraphQL, ~824K lines Python)
- medusa (TypeScript/Node monorepo, 10 packages)
- clinic-portal (Django multi-tenant, ~46 files)
- fastapi-template (Python/FastAPI, ~2.5K lines)

### Gaps found and fixed:

**Step 1 (Survey):**
- ADDED: Monorepo detection — package topology analysis, god package identification

**Step 2 (Map):**
- ADDED: Data flow tracing methodology (input → validation → logic → storage → output)
- ADDED: Trust boundary identification at each flow step
- ADDED: Coupling metrics (afferent/efferent, instability calculation)
- ADDED: Extension point analysis (plugins, middleware chains, hooks, events)

**Step 3 (Detect):**
- ADDED: Abstraction quality checks (layer violations, leaky abstractions, DI consistency)
- ADDED: Boilerplate ratio analysis with extraction candidate flagging

**Step 4 (Measure):**
- UPGRADED: TODO/FIXME/HACK from counting to classification (category, urgency, staleness, clustering)
- ADDED: Dead code detection with 5 concrete techniques (import tracing, orphan files, duplicates, commented blocks)
- ADDED: Git history analysis (churn hotspots, code age/fossils, author concentration/knowledge silos)

**Step 5 (Assess):**
- ADDED: Trust boundary analysis for security (path traversal, unverified metadata, TOCTOU)
- ADDED: Config security checks (default secrets, restart regeneration, missing prod validation)
- ADDED: Redundant sanitization detection
- ADDED: Abandoned feature detection (dead feature flags, deprecated-without-replacement, orphaned migrations, unused routes)

**NEW Step 6 (Analyze — Configuration):**
- ADDED: Config architecture analysis (single class vs scattered, validation on startup)
- ADDED: Environment handling, secret management, missing common configs, config documentation

**Step 7 (Recommend):**
- ADDED: Shared-module extraction candidates for duplicated logic

**Output Format:**
- ADDED: Dead code files, duplicate logic clusters, churn hotspots to metrics table
- ADDED: Tech Debt Markers (classified) table with category/count/urgency/examples
- ADDED: Data Flow & Trust Boundaries section
