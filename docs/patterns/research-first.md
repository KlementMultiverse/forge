# Research-First Pattern

Every agent MUST research before implementing. No agent should code based on training data alone.

## The Problem

In clinic-portal, the AI search/chat feature had to be built from scratch because:
- No agent researched current best practices for clinical search APIs
- No agent checked what open-source RAG patterns existed
- No agent looked for existing implementations to learn from
- The LLM relied on training data that was outdated

## The Solution: Mandatory Research Step

Before writing ANY code, every agent executes:

```
1. CONTEXT7 — fetch official library docs
   @context-loader-agent → resolve-library-id → query-docs
   "What's the latest API for [library]?"

2. WEB SEARCH — find current best practices
   @deep-research-agent → search for "[feature] best practices 2025"
   "What's the recommended approach for [feature] in [stack]?"

3. ALTERNATIVES — compare options
   Search for open-source implementations, compare 3+ approaches
   "What libraries/patterns exist for [feature]? Pros/cons?"

4. TRENDS — check what's current
   Search for "[feature] latest trends [year]"
   "Has anything changed recently? New libraries? Deprecations?"

5. SYNTHESIZE — choose the best approach
   Document: chosen approach, why, alternatives rejected, sources
```

## Where This Fires In The Forge Cell

```
Step 0: /sc:spawn (decompose)
Step 1: @context-loader-agent (library docs)           ← RESEARCH
Step 2: Agent RESEARCH (spec, tests, code, rules)       ← RESEARCH
        + WEB SEARCH for best practices                 ← RESEARCH (NEW)
        + ALTERNATIVES comparison                       ← RESEARCH (NEW)
Step 3: TDD implementation (using researched approach)
...
```

## What Gets Researched

| Feature Type | Research Required |
|-------------|-------------------|
| API endpoint | Best REST patterns, similar APIs, error handling conventions |
| Database model | Schema patterns, indexing strategies, query optimization |
| Authentication | Current auth best practices, library comparison (JWT vs session vs OAuth) |
| File storage | Presigned URL patterns, CDN options, security considerations |
| AI/LLM integration | Current models, RAG patterns, prompt engineering, rate limiting |
| Search | Full-text search options, existing APIs (Elasticsearch, Meilisearch, DB-native) |
| Frontend | Component patterns, accessibility, responsive approaches |
| Caching | Strategy comparison (Redis, Memcached, DB-level), invalidation patterns |
| Testing | Framework comparison, coverage strategies, E2E approach |
| Deployment | Container patterns, CI/CD options, hosting comparison |

## Tools For Research

Every agent should have access to:
- `context7 MCP` — library docs (resolve-library-id + query-docs)
- `WebSearch` — current best practices, trends, alternatives
- `WebFetch` — official documentation pages
- `@deep-research-agent` — when deep analysis is needed

## Output: Research Brief

Before implementing, the agent produces a brief:

```markdown
## Research Brief: [feature]

### Approach Chosen
[What we're implementing and why]

### Alternatives Considered
1. [Alternative A]: [pros/cons/why rejected]
2. [Alternative B]: [pros/cons/why rejected]

### Sources
- [context7 docs: version, key patterns]
- [web: article/repo/docs URL]
- [trend: what's current in 2025+]

### Implementation Plan
[Specific steps using the researched approach]
```

## Rules
- NEVER implement based on training data alone — always verify with context7
- NEVER skip web search for best practices — training data may be outdated
- ALWAYS compare at least 2 alternatives before choosing
- ALWAYS document sources in the research brief
- Research brief feeds into the design doc (Section 3: Design Decisions)
