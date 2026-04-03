# Root Cause Analyst — Autoresearch Changelog

**Date:** 2026-04-02
**Test runs:** 10
**Pass rate before:** 3/10 (30%)
**Estimated pass rate after:** 9/10 (90%)

## Changes Made to Agent Prompt

### NEW SECTION: Investigation Methods (mandatory structured techniques)

**5 Whys — Iterative Deepening**
- Added: explicit 5 Whys method with worked example
- Rationale: 7/10 runs stopped at the first "because" — prompt never mandated iterative deepening
- Fixes gaps: G1 (runs 1,3,5,9)

**Fishbone Categorization**
- Added: 6-category table (Code/Config/Data/Env/Deps/Timing) to check for EVERY investigation
- Rationale: all 10 runs would benefit from systematic category elimination
- Fixes gaps: G2 (all runs)

**All-Paths Analysis**
- Added: checklist for verifying guards work on ALL paths (model, QuerySet, raw SQL, admin, commands, signals, background)
- Rationale: run 9 (AuditLog immutability bypass) demonstrated that model-level guards are incomplete
- Fixes gaps: G13, G15 (run 9)

### NEW SECTION: Domain-Specific Investigation Patterns (9 patterns)

1. **HTTP Response Flow** — trace middleware chain for status code mismatches (G3, runs 1,2)
2. **Authentication/Authorization Chain** — trace auth end-to-end, detect silent failures (G4, G5, run 2)
3. **Database State vs Migration State** — compare actual DB to migration history (G6, run 3)
4. **Environment-Difference Analysis** — 7-item checklist for "works here fails there" (G7, run 4)
5. **Multi-Tenant Data Isolation** — verify isolation at all code paths (G8, G9, run 5)
6. **Async Task Lifecycle** — trace publish→broker→queue→consumer→execute (G10, run 6)
7. **Resource Lifecycle** — trace create→use→error→cleanup for sessions/connections (G11, run 7)
8. **Error Transformation Chain** — trace original error→formatter→handler→response (G12, G17, run 8)
9. **Serialization Chain** — trace data→serializer→transport→consumer (G14, run 10)
10. **Silent Failure Detection** — checklist for "no error but wrong behavior" (G5, runs 2,6)

### MODIFIED: Forge Cell Compliance
- Added steps 3-6: mandatory 5 Whys, Fishbone, domain pattern selection, All-Paths Analysis
- Changed from 7 steps to 11 steps

### MODIFIED: Handoff Protocol
- Added: `Fishbone Category` field
- Added: `5 Whys Chain` field
- Added: `Investigation Method Used` field

### MODIFIED: Self-Correction Loop
- Added step 4: verify 5 Whys and Fishbone were actually applied

### MODIFIED: Chaos Resilience
- Updated empty/generic error handling to reference Silent Failure Detection pattern
- Updated cannot-reproduce handling to reference Environment-Difference Analysis
- Added: "no error at all" case for silent failures

### MODIFIED: Anti-Patterns
- Added: NEVER stop at first "why"
- Added: NEVER check only one code path
- Added: NEVER assume guard works at all layers
- Added: NEVER investigate client-side only for 500 errors

## Gap Coverage After Changes

| Gap ID | Before | After | How Fixed |
|---|---|---|---|
| G1 (5 Whys) | MISSING | COVERED | 5 Whys section + worked example |
| G2 (Fishbone) | MISSING | COVERED | Fishbone table + mandatory check |
| G3 (HTTP flow) | MISSING | COVERED | HTTP Response Flow pattern |
| G4 (Auth chain) | MISSING | COVERED | Auth/Authz Chain pattern |
| G5 (Silent failure) | MISSING | COVERED | Silent Failure Detection pattern |
| G6 (DB vs migration) | MISSING | COVERED | DB State vs Migration pattern |
| G7 (Env differences) | MISSING | COVERED | Environment-Difference Analysis |
| G8 (Multi-tenant) | MISSING | COVERED | Multi-Tenant Data Isolation pattern |
| G9 (Execution context) | MISSING | COVERED | Multi-Tenant + Async Task patterns |
| G10 (Async tasks) | MISSING | COVERED | Async Task Lifecycle pattern |
| G11 (Resource lifecycle) | MISSING | COVERED | Resource Lifecycle pattern |
| G12 (Error transform) | MISSING | COVERED | Error Transformation Chain pattern |
| G13 (ORM layers) | MISSING | COVERED | All-Paths Analysis |
| G14 (Serialization) | MISSING | COVERED | Serialization Chain pattern |
| G15 (All paths) | MISSING | COVERED | All-Paths Analysis section |
| G16 (Dual authority) | MISSING | COVERED | DB State vs Migration pattern |
| G17 (Correlation ID) | MISSING | COVERED | Error Transformation Chain pattern |
