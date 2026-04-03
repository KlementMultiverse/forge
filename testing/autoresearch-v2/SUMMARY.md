# Autoresearch V2 — Summary

**Date**: 2026-04-02
**Repos tested**: axum (Rust), chi (Go), drf (Django REST Framework), pydantic (Python), taxonomy (Next.js), clinic-portal (Django multi-tenant)
**Agents tested**: 16 (8 batch 1 + 8 batch 2)
**Total edge-case test runs**: 80 (5 per agent)
**Total gaps found**: 118 (48 batch 1 + 70 batch 2)
**Total agent prompts fixed**: 16
**Claude Code patterns extracted**: 8 (from leaked source analysis)

## Research Sources Used
- OWASP Top 10 2025 (new A10: Mishandling of Exceptional Conditions)
- CVE-2025-29927: Next.js middleware authorization bypass (CVSS 9.1, March 2025)
- "Async Isn't Always Faster" (FastAPI gotchas, Medium)
- "Async Rust is about concurrency, not performance" (Kobzol, Jan 2025)
- "AI-Generated Code Creates New Wave of Technical Debt" (InfoQ, Nov 2025)
- "After 50 Production Incidents" failure pattern guide (Medium)
- "Cognitive Debt Is Not Technical Debt" (Dev.to)
- "Detection of Self-Admitted Aging Debt" (Empirical Software Engineering 2025)
- Next.js official security blog: "How to Think About Security in Next.js"
- DRF official docs: throttling, permissions, authentication
- Pydantic v2 migration guide and validator docs
- chi middleware documentation and Go concurrency best practices
- Claude Code leaked source: BashTool, FileEditTool, AgentTool, coordinator, autoDream

## Critical Findings

### CRITICAL (4)
| # | Agent | Finding | Repo |
|---|-------|---------|------|
| 1 | security-engineer | taxonomy middleware uses `authorized() { return true }` — bypassed by CVE-2025-29927 | taxonomy |
| 2 | security-engineer | DRF `ObtainAuthToken` ships with `throttle_classes = ()` — zero brute force protection | drf |
| 3 | code-archaeologist | taxonomy has BOTH `pages/` and `app/` directories with duplicated auth routes | taxonomy |
| 4 | context-loader-agent | No version-conflict detection — context7 can return v1 docs for v2 projects silently | all |

### HIGH (16)
| # | Agent | Finding | Repo |
|---|-------|---------|------|
| 1 | security-engineer | No Rust/Go/Next.js-specific security scan patterns in agent | all |
| 2 | performance-engineer | No Rust/Go/pydantic/Next.js performance patterns in agent | all |
| 3 | quality-engineer | taxonomy has ZERO test files | taxonomy |
| 4 | frontend-architect | No error.tsx, loading.tsx, or global-error.tsx in taxonomy | taxonomy |
| 5 | root-cause-analyst | Fishbone categories missing Memory, Concurrency, Route Matching | all |
| 6 | frontend-architect | No SEO checklist for content-heavy sites | taxonomy |
| 7 | code-archaeologist | No pydantic v1→v2 migration debt scanner | pydantic |
| 8 | backend-architect | No pydantic schema design checklist | pydantic |
| 9 | learning-guide | No Rust ownership/Go interface teaching patterns | axum, chi |
| 10 | requirements-analyst | No trait/extractor/viewset requirement extraction patterns | axum, drf |
| 11 | technical-writer | No Migration Guide document-type template | all |
| 12 | devops-architect | No Rust/Go/Next.js Dockerfile patterns | axum, chi, taxonomy |
| 13 | system-architect | No Tower/Go/RSC architecture analysis patterns | axum, chi, taxonomy |
| 14 | business-panel-experts | No open-source monetization or technology lifecycle framework | pydantic, drf |
| 15 | context-loader-agent | No Rust/Go/DRF library maps | axum, chi, drf |
| 16 | playwright-critic | No multi-tenant E2E testing or SEO metadata testing patterns | clinic-portal, taxonomy |

## Gaps per Agent

### Batch 1 (previous)
| Agent | Gaps Found | Gaps Fixed |
|-------|-----------|------------|
| @security-engineer | 6 | 6 |
| @performance-engineer | 6 | 6 |
| @refactoring-expert | 6 | 6 |
| @backend-architect | 6 | 6 |
| @code-archaeologist | 6 | 6 |
| @root-cause-analyst | 6 | 6 |
| @quality-engineer | 6 | 6 |
| @frontend-architect | 6 | 6 |

### Batch 2 (this run)
| Agent | Gaps Found | Gaps Fixed |
|-------|-----------|------------|
| @learning-guide | 9 | 9 |
| @requirements-analyst | 10 | 10 |
| @technical-writer | 7 | 7 |
| @devops-architect | 7 | 7 |
| @system-architect | 9 | 9 |
| @business-panel-experts | 9 | 9 |
| @context-loader-agent | 9 | 9 |
| @playwright-critic | 10 | 10 |
| **Batch 2 Total** | **70** | **70** |
| **Grand Total** | **118** | **118** |

## Common Gap Theme: Language/Framework Blindness

The #1 pattern across ALL agents: prompts were heavily biased toward Python/Django/FastAPI patterns and lacked equivalent detection for:
- **Rust**: unsafe blocks, panic paths, tokio runtime config, trait bloat, clone overhead, Tower middleware, cargo-chef Docker caching
- **Go**: goroutine leaks, context propagation, interface pollution, race conditions, structural typing, CGO_ENABLED=0 Docker
- **Next.js**: server/client boundaries, middleware bypass CVE, App Router file conventions, RSC performance, standalone Docker output
- **Pydantic**: v1→v2 migration debt, coercion changes, arbitrary_types validation gaps, discriminated unions, model-as-requirement
- **DRF**: ViewSet layer analysis, serializer N+1, throttle_classes absence, framework overhead assessment

All 16 agents now have expanded language-specific sections.

## Claude Code Leak Analysis — Key Patterns Extracted

### Pattern 1: Defense in Depth (BashTool/bashSecurity.ts)
Every security validation has multiple layers: allowlist check → denylist check → semantic validation → tree-sitter analysis. Never rely on a single check. Applied to: @requirements-analyst (multi-layer requirement validation).

### Pattern 2: Destructive Command Warning (BashTool/destructiveCommandWarning.ts)
Every potentially dangerous operation has a human-readable warning shown to the user. Not a blocker — just informational. Applied to: @learning-guide ("Show the Broken Version" teaching pattern).

### Pattern 3: Command Semantics (BashTool/commandSemantics.ts)
Different commands have different success definitions (grep exit=1 is "no matches", not error). Context-dependent interpretation. Applied to: @playwright-critic (test result semantic classification).

### Pattern 4: Quote Normalization / Desanitization (FileEditTool/utils.ts)
Graceful handling of representation mismatches (curly quotes → straight quotes, sanitized XML → original). Applied to: @technical-writer (cross-framework terminology normalization).

### Pattern 5: Coordinator/Worker Separation (coordinator/coordinatorMode.ts)
Strict separation: coordinator orchestrates but NEVER executes. Workers execute with explicit tool allowlists. Coordinator synthesizes results; workers report findings. Applied to: @system-architect (orchestration vs execution layer analysis).

### Pattern 6: Fork Subagent Context Inheritance (AgentTool/forkSubagent.ts)
Fork children inherit full conversation context for parallel work. Prompt cache sharing via byte-identical prefixes. Worktree isolation for file changes. Applied to: @business-panel-experts (context transfer cost as business moat).

### Pattern 7: Gate-Based Execution (services/autoDream/autoDream.ts)
Three-gate pattern for expensive operations: cheapest check first (time gate → session count → lock acquisition). Scan throttle prevents repeated expensive scans. Applied to: @devops-architect (CI pipeline stage ordering).

### Pattern 8: Memory Consolidation (services/autoDream/consolidationPrompt.ts)
Background "dream" process reviews recent sessions and consolidates memories. Four phases: Orient → Gather → Consolidate → Prune. Converts relative dates to absolute. Merges rather than duplicates. Applied as general insight for all agents.

## Files Modified

### Agent Prompts — Batch 1 (8 files, previous)
- `/home/intruder/projects/forge/agents/universal/security-engineer.md`
- `/home/intruder/projects/forge/agents/universal/performance-engineer.md`
- `/home/intruder/projects/forge/agents/universal/refactoring-expert.md`
- `/home/intruder/projects/forge/agents/universal/backend-architect.md`
- `/home/intruder/projects/forge/agents/universal/code-archaeologist.md`
- `/home/intruder/projects/forge/agents/universal/root-cause-analyst.md`
- `/home/intruder/projects/forge/agents/universal/quality-engineer.md`
- `/home/intruder/projects/forge/agents/universal/frontend-architect.md`

### Agent Prompts — Batch 2 (8 files, this run)
- `/home/intruder/projects/forge/agents/universal/learning-guide.md` — Added: Rust/Go/Pydantic/Next.js/DRF teaching patterns, compiler-error-first strategy, migration-in-progress pattern
- `/home/intruder/projects/forge/agents/universal/requirements-analyst.md` — Added: Rust trait/Go middleware/DRF viewset/Pydantic model/Next.js file-convention requirement extraction, absent requirement severity classification
- `/home/intruder/projects/forge/agents/universal/technical-writer.md` — Added: Migration Guide template, Rust/Go/DRF/Pydantic/Next.js documentation patterns, cross-framework terminology normalization
- `/home/intruder/projects/forge/agents/universal/devops-architect.md` — Added: Rust/Go/Next.js Dockerfile patterns, cargo-chef caching, library CI/CD (PyPI publishing), gate-based pipeline ordering
- `/home/intruder/projects/forge/agents/universal/system-architect.md` — Added: Tower middleware/Go router/DRF layer/Pydantic extension/RSC architecture patterns, coordinator-worker separation
- `/home/intruder/projects/forge/agents/universal/business-panel-experts.md` — Added: Open-source monetization framework, technology lifecycle analysis (Lindy effect), AI-native business analysis, zero-revenue high-influence pattern
- `/home/intruder/projects/forge/agents/universal/context-loader-agent.md` — Added: Rust/Go/DRF library maps, version-conflict detection, Go stdlib as library pattern
- `/home/intruder/projects/forge/agents/universal/playwright-critic.md` — Added: Dark mode/responsive/SEO/multi-tenant testing patterns, feature absence detection, CSS transition waiting, page.emulateMedia

### Research Results — Batch 2 (8 files, this run)
- `/home/intruder/projects/forge/testing/autoresearch-v2/learning-guide/results.md`
- `/home/intruder/projects/forge/testing/autoresearch-v2/requirements-analyst/results.md`
- `/home/intruder/projects/forge/testing/autoresearch-v2/technical-writer/results.md`
- `/home/intruder/projects/forge/testing/autoresearch-v2/devops-architect/results.md`
- `/home/intruder/projects/forge/testing/autoresearch-v2/system-architect/results.md`
- `/home/intruder/projects/forge/testing/autoresearch-v2/business-panel-experts/results.md`
- `/home/intruder/projects/forge/testing/autoresearch-v2/context-loader-agent/results.md`
- `/home/intruder/projects/forge/testing/autoresearch-v2/playwright-critic/results.md`
