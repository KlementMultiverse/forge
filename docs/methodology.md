# Forge Methodology — The Complete Development Cycle

## First Principles

Every software system has 4 components:
- **Interface** — what users see (pages, forms, buttons)
- **Logic** — what the system does (APIs, rules, permissions)
- **Data** — what the system stores (models, relationships)
- **Infrastructure** — where it runs (database, server, cache)
- **Cross-cutting** — touches everything (security, logging, testing, error handling)

Build order follows dependencies: Infrastructure → Data → Logic → Interface.

## The 15-Step Chain

```
 0. PROBLEM        → Why does this need to exist?
 1. DISCOVERY      → Who has this problem? How do they solve it today?
 2. REQUIREMENTS   → What must the solution do? [REQ-xxx] tagged
 3. FEASIBILITY    → Can we build it? With what stack? What risks?
 4. SPECIFICATION  → Formal SPEC.md (source of truth)
 5. PROPOSAL       → User stories, acceptance criteria, issues
 6. ARCHITECTURE   → 10-section design document
 7. PLANNING       → Phased issues with dependencies
 8. IMPLEMENTATION → TDD via domain agents + Forge Cell
 9. VALIDATION     → Pattern audit + test coverage + traceability
10. REVIEW         → Retrospective + playbook update
11. DEPLOYMENT     → Ship to production
12. FEEDBACK       → User input
13. ITERATE        → Loop to step 5 (new features) or 8 (fixes)
14. LEARN          → Every fix improves spec + tests + playbook
```

Steps 0-3: Discovery (human idea + AI research)
Steps 4-10: Automated SDLC (/forge runs this)
Steps 11-14: Deploy + iterate + learn

## The Forge Cell

Every agent runs through the same 7-step pipeline:

```
1. LOAD CONTEXT
   Read: spec [REQ-xxx], existing tests, current code, library docs, domain rules

2. RESEARCH (self-discovery)
   Ask: what exists? what's missing? what gaps? what improvements?
   Flag: anything new for spec/test/code update

3. IMPLEMENT (TDD)
   a) Write TEST first → references [REQ-xxx]
   b) Run test → MUST FAIL (proves test is real)
   c) Write CODE → references [REQ-xxx]
   d) Run test → MUST PASS
   e) Run ALL tests → no regressions

4. QUALITY
   Format + lint. Full test suite.
   If fail → /investigate (root cause BEFORE fix)
   Reflexion: max 3 attempts. Still fails → escalate.

5. SYNC (bidirectional)
   New code? → verify REQ exists in spec
   New behavior? → verify test exists
   Gap? → add to SPEC + add test + update code
   Traceability: 100% coverage, 0 orphans, 0 drift

6. JUDGE (per-agent domain reviewer)
   Rate output 1-5. Write mini-retrospective.
   Rating ≥4 → accept.
   Rating <4 → reiterate same agent with judge feedback (max 3).

7. COMMIT + LEARN
   Git commit. Close issue. /checkpoint.
   New insight? → /learn (save to playbook with helpful=0 harmful=0)
```

The cell is the constant. The agent's domain expertise is the only variable.

## Quality Gates

Nothing proceeds without verification:

| Gate | When | Blocks Until |
|------|------|-------------|
| /checkpoint | After every agent | Quality score acceptable |
| /gate | Every stage boundary | CodeRabbit has 0 suggestions |
| /audit-patterns | Stage 4 | >90% of 170+ checks pass |
| Traceability | Every sync check | 100% REQ coverage, 0 orphans |
| Per-agent judge | Every implementation | Rating ≥4 out of 5 |

## Bidirectional Sync

Every requirement, test, and code block is linked via [REQ-xxx] tags:

```
SPEC.md:     [REQ-001] Admin can create workflows
tests/:      def test_create_workflow():  # [REQ-001]
code/:       class Workflow:  # [REQ-001]
```

Change ANY → system finds ALL linked → flags for review → auto-verifies.

Fixes always grow the system:
- Fix written → new test added → spec updated → playbook updated
- System is BETTER after every bug fix

## Self-Improving Playbook

Rules are scored:
```
[str-001] helpful=5 harmful=0 :: validate tenant schema before query
[str-002] helpful=3 harmful=2 :: use global CSRF parameter  ← candidate for pruning
```

- /learn adds new rules (helpful=0 harmful=0)
- /retro updates counters based on outcomes
- /prune removes rules where harmful > helpful
- /evolve clusters strong strategies into reusable skills

## Design Document (10 Sections)

Used in Phase 2 (/design-doc). Every decision follows this format:

```
Will implement [approach] because:
- Reason 1
- Reason 2
- Trade-off: what you give up
- Alternative considered: what you didn't pick and why
```

Sections:
1. Current Context — what exists today
2. Requirements — linked to [REQ-xxx]
3. Design Decisions — "Will implement X because" format
4. Technical Design — models, components, API contracts
5. Implementation Plan — ordered by dependency
6. Testing Strategy — 15+ scenarios
7. Observability — 10 logging points
8. Future Considerations
9. Dependencies
10. Security

Section 4 (API Contracts) is critical — both backend and frontend agents read the same contract. No guessing.
