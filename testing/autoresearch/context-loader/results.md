# Context Loader Agent - Autoresearch Results (10 Runs)

**Date:** 2026-04-02
**Agent:** /home/intruder/projects/forge/agents/universal/context-loader-agent.md

---

## Run 1: Load django-tenants docs via context7

**Input:** Fetch docs for django-tenants (TenantBase, middleware, migrations).

**Analysis of Prompt Behavior:**
- Library Map correctly maps "tenant, schema, multi-tenant" -> django-tenants
- Query topic "TenantBase model setup middleware" is well-scoped
- Intent statement requirement is clear: "I will fetch docs for django-tenants because..."
- CLAUDE.md Rule #3 and #4 correctly linked

**Potential Issues:**
- `resolve-library-id("django-tenants")` may not find it — library might be registered as "bernardopires/django-tenants" or "django-tenants/django-tenants"
- Prompt says "try alternate names" but doesn't list what alternates to try
- If context7 has no django-tenants at all — prompt says fall back to web search, but doesn't specify WHICH URL to WebFetch

**Gap Found:**
- Missing: explicit fallback URLs for each library in the Library Map
- Should include official docs URL: `https://django-tenants.readthedocs.io/en/latest/`
- No guidance on which query-docs topic parameters yield best results

---

## Run 2: Load django-ninja docs via context7

**Input:** Fetch docs for django-ninja (NinjaAPI, Schema, routers, auth).

**Analysis:**
- Library Map correctly maps "api, endpoint, Schema, NinjaAPI" -> django-ninja
- Agent should resolve as "vitalik/django-ninja" (GitHub owner/repo format)
- CLAUDE.md Rule #1 correctly linked

**Potential Issues:**
- django-ninja has version-specific differences: v0.x vs v1.x API changes
- SessionAuth CSRF handling (Lesson Learned #16) is version-dependent — agent should warn about this
- Query topic "NinjaAPI Schema router authentication" is too broad — may return too much irrelevant content

**Gap Found:**
- Missing: guidance on query-docs topic SPECIFICITY — broad topics return noise
- Should recommend multiple focused queries over one broad query
- Missing: version pinning check against pyproject.toml before querying docs
- No guidance on extracting version from pyproject.toml/package.json before fetching docs

---

## Run 3: Load boto3 S3 docs via context7

**Input:** Fetch S3 presigned URL documentation.

**Analysis:**
- Library Map correctly maps "S3, presigned, upload" -> boto3
- Query topic "S3 generate_presigned_post presigned_url" is well-targeted

**Potential Issues:**
- boto3 docs in context7 may be enormous — need topic-focused query
- `generate_presigned_post` vs `generate_presigned_url` — these are DIFFERENT APIs with different use cases
- The clinic-portal uses presigned POST for upload and presigned URL for download — both should be fetched

**Gap Found:**
- Missing: differentiation between upload (presigned POST) and download (presigned GET URL)
- Library Map has one entry for S3 but should split: "upload" -> presigned_post, "download" -> presigned_url
- No guidance on boto3 service-specific client creation patterns

---

## Run 4: Load FastAPI docs via context7

**Input:** Fetch FastAPI documentation.

**Analysis:**
- FastAPI is NOT in the Library Map at all — map is clinic-portal-specific
- Agent would need to infer "FastAPI" from task keywords and do a freeform resolve-library-id
- No CLAUDE.md rules to reference for non-clinic-portal projects

**Gap Found:**
- Library Map is hardcoded to clinic-portal's stack — completely useless for other projects
- Agent description says "Pre-fetches library documentation via context7 MCP before any coding task" but the Library Map only covers 6 libraries
- Missing: dynamic library detection from project files (requirements.txt, pyproject.toml, package.json)
- Should have a "universal" Library Map covering common frameworks + a project-specific extension mechanism

---

## Run 5: Load SQLAlchemy docs via context7

**Input:** Fetch SQLAlchemy ORM documentation.

**Analysis:**
- SQLAlchemy not in Library Map
- Agent would need to go to resolve-library-id directly
- No CLAUDE.md rules apply

**Gap Found:**
- Same issue as Run 4 — Library Map is too narrow
- Agent needs a fallback for "library not in map": read pyproject.toml -> identify all dependencies -> resolve any that match the task

---

## Run 6: Load LangGraph docs via context7

**Input:** Fetch LangGraph documentation.

**Analysis:**
- LangGraph not in Library Map
- context7 may or may not have LangGraph — it's newer
- Fallback chain should be: context7 -> web search -> official docs (https://langchain-ai.github.io/langgraph/)

**Gap Found:**
- No guidance for bleeding-edge libraries that may not be in context7 yet
- Missing: "check library age/popularity" heuristic — very new libraries need web search fallback
- Agent should proactively check if resolve-library-id returns results for newer libraries
- The MCP server `mcp__docs-langchain__search_docs_by_lang_chain` exists but agent prompt doesn't mention using ALTERNATIVE MCP servers as fallbacks

---

## Run 7: Load Pydantic v2 docs via context7

**Input:** Fetch Pydantic v2 migration and usage docs.

**Analysis:**
- Pydantic not explicitly in Library Map (though django-ninja uses it internally)
- Pydantic v1 -> v2 migration is a CRITICAL version awareness scenario
- Agent should check project's Pydantic version before fetching docs

**Gap Found:**
- Missing: version-specific query strategy — "Pydantic v2" vs "Pydantic" returns different docs
- No guidance on including version number in query-docs topic
- Should recommend: resolve-library-id("pydantic") -> check version -> query-docs with version-specific topic

---

## Run 8: Load django-tenant-users (might NOT be in context7)

**Input:** Fetch docs for a potentially unavailable library.

**Analysis:**
- django-tenant-users IS in the Library Map
- But this is a small, niche library — context7 may not have it
- Prompt says "try alternate names" then fall back to web search

**Potential Failure Path:**
1. resolve-library-id("django-tenant-users") -> no results
2. resolve-library-id("Corvia/django-tenant-users") -> no results
3. Web search "django-tenant-users documentation" -> limited results
4. WebFetch("https://github.com/Corvia/django-tenant-users") -> README only

**Gap Found:**
- Missing: explicit fallback URL for each library in the Library Map
- Missing: GitHub README as a valid documentation source for small libraries
- No guidance on when to recommend READING THE SOURCE CODE as documentation
- For small libraries, source code IS the docs — agent should recognize this and recommend reading `models.py`, `mixins.py` etc.

---

## Run 9: Load multiple libraries at once (django-tenants + django-ninja + boto3)

**Input:** Batch-load docs for three libraries simultaneously.

**Analysis:**
- Prompt says process each library sequentially (steps 4a-4d for EACH)
- No guidance on parallel loading — could call resolve-library-id for all 3 simultaneously
- Output Protocol has one Doc Excerpts section — may become very long with 3 libraries

**Gap Found:**
- Missing: parallel loading strategy — resolve all library IDs first, THEN query all docs
- No guidance on OUTPUT SIZE management — 3 libraries could produce 10K+ tokens of doc excerpts
- Missing: prioritization when loading multiple libraries ("load the one most critical to the task first")
- Should recommend: summary mode for secondary libraries, full docs for primary library
- No token budget awareness — context window may not fit all docs

---

## Run 10: Load TypeScript library docs (@modelcontextprotocol/sdk)

**Input:** Fetch TypeScript MCP SDK documentation.

**Analysis:**
- Library Map is Python-only — no TypeScript libraries
- resolve-library-id would need the exact npm package name
- CLAUDE.md rules don't apply (TypeScript project)

**Gap Found:**
- Library Map is Python-exclusive — no support for TypeScript, Go, Rust, etc.
- Missing: language detection from project files to select appropriate Library Map
- Missing: npm/yarn package name resolution (scoped packages like @org/name)
- Agent is described as "universal" but is actually Python-specific

---

## Summary of ALL Gaps Found

| # | Gap | Severity | Fix |
|---|-----|----------|-----|
| 1 | Library Map only covers 6 clinic-portal libs | CRITICAL | Add universal library detection |
| 2 | No fallback URLs for official docs | HIGH | Add URLs to Library Map |
| 3 | No version check against pyproject.toml | HIGH | Add version detection step |
| 4 | Python-only — no TypeScript/Go/Rust support | HIGH | Add multi-language support |
| 5 | No parallel loading strategy for multiple libs | MEDIUM | Add batch loading guidance |
| 6 | No query topic specificity guidance | MEDIUM | Add topic refinement tips |
| 7 | No token budget / output size management | MEDIUM | Add size limits |
| 8 | No source code as docs fallback for small libs | HIGH | Add source reading fallback |
| 9 | No alternative MCP server usage | MEDIUM | Document MCP alternatives |
| 10 | No dynamic library detection from project files | HIGH | Add file-based detection |
