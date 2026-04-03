# Autoresearch V2 — @learning-guide Results

**Date**: 2026-04-02
**Repos tested**: axum (Rust), chi (Go), drf (Django REST Framework), pydantic (Python), taxonomy (Next.js)

## Edge Case 1: "Explain Rust ownership to a Python developer" (axum)
**Repo**: axum
**Prompt**: Explain Rust ownership to a Python developer using axum handler examples

### Gap Found: No Rust-specific teaching patterns
The agent has no Rust-specific teaching vocabulary. When explaining ownership, the agent should:
- Bridge from Python's reference counting GC to Rust's compile-time ownership
- Use axum extractors (`State<Arc<AppState>>`) as concrete "ownership in action" examples
- Show the "broken version" (clone-heavy handler) vs the optimized version (Arc + shared state)
- Explain `Clone`, `Send`, `Sync` traits as the "permission system" Python developers lack

### Gap Found: No "show the compiler error" pattern
Rust learning is uniquely driven by compiler error messages. The agent should teach by showing the error first, then explaining the fix. Python developers are not used to this workflow.

## Edge Case 2: "Explain Go interfaces to a Java developer" (chi)
**Repo**: chi
**Prompt**: Explain Go interfaces to a Java developer using chi middleware examples

### Gap Found: No Go-specific teaching patterns
The agent lacks Go structural typing vs Java nominal typing comparisons. Key gaps:
- No comparison table: Java `implements` keyword vs Go implicit interface satisfaction
- No chi middleware example showing `func(http.Handler) http.Handler` as the "interface" pattern
- No explanation of how Go's small interfaces (1-2 methods) differ from Java's large interfaces

### Gap Found: No "interface pollution" warning
When teaching Go interfaces, the agent should warn: "Don't create interfaces upfront like Java. In Go, the consumer defines the interface, not the producer."

## Edge Case 3: "Explain DRF serializers to someone who only knows Django Ninja" (drf)
**Repo**: drf
**Prompt**: Explain DRF serializers to someone who only knows Django Ninja Schema classes

### Gap Found: No reverse-direction framework teaching
The agent only knows "teach new framework from old." It has no pattern for teaching a legacy framework to someone who already knows the modern replacement. DRF serializers should be explained as "what Schema classes replaced" — validation, nested serialization, and the serializer-as-form pattern.

### Gap Found: No "why this exists" historical context
DRF serializers predate type hints. The agent should explain that DRF's `fields = ['id', 'name']` pattern exists because Python had no equivalent of Pydantic's `BaseModel` in 2012.

## Edge Case 4: "Explain Pydantic v2 discriminated unions" (pydantic)
**Repo**: pydantic
**Prompt**: Explain Pydantic v2 discriminated unions using the pydantic source code

### Gap Found: No advanced Pydantic pattern teaching
The agent has no content for discriminated unions, which require understanding:
- `Annotated[Union[Cat, Dog], Field(discriminator='pet_type')]` syntax
- How the discriminator field avoids expensive validation of all union members
- Performance difference: O(1) discriminated vs O(n) undiscriminated union validation
- The "broken version": `Union[Cat, Dog]` without discriminator leads to confusing validation errors

### Gap Found: No "read the source" teaching strategy
For library internals, the agent should guide learners through the actual source code (e.g., `pydantic/_internal/_discriminated_unions.py`) rather than just explaining the API.

## Edge Case 5: "Explain Next.js App Router to someone who knows Pages Router" (taxonomy)
**Repo**: taxonomy
**Prompt**: Explain App Router to someone using taxonomy (which has BOTH pages/ and app/ directories)

### Gap Found: No Next.js-specific teaching patterns
The agent lacks App Router vs Pages Router comparison content:
- No comparison table: `getServerSideProps` vs server components, `getStaticProps` vs `generateStaticParams`
- No explanation of the `layout.tsx` / `page.tsx` / `loading.tsx` / `error.tsx` file convention
- No warning about the taxonomy repo having BOTH routers (migration in progress) — a common real-world scenario

### Gap Found: No "migration-in-progress" teaching pattern
When a codebase has both old and new patterns (taxonomy has both `pages/` and `app/`), the agent should explicitly call this out and explain which files use which pattern.

## Summary of Gaps

| # | Gap | Severity | Fix Applied |
|---|-----|----------|-------------|
| 1 | No Rust-specific teaching patterns (ownership, borrowing, compiler errors) | HIGH | YES |
| 2 | No "show the compiler error first" teaching strategy for Rust | MEDIUM | YES |
| 3 | No Go-specific teaching patterns (structural typing, small interfaces, interface pollution) | HIGH | YES |
| 4 | No reverse-direction framework teaching (legacy from modern) | MEDIUM | YES |
| 5 | No historical context teaching ("why this pattern exists") | MEDIUM | YES |
| 6 | No advanced Pydantic pattern teaching (discriminated unions, validators) | HIGH | YES |
| 7 | No "read the source code" teaching strategy for library internals | MEDIUM | YES |
| 8 | No Next.js App Router vs Pages Router comparison content | HIGH | YES |
| 9 | No "migration-in-progress" teaching pattern for mixed codebases | MEDIUM | YES |

## Claude Code Pattern: "Show the Broken Version"
From Claude Code's BashTool, the `destructiveCommandWarning.ts` pattern shows how to present "what could go wrong" alongside the correct approach. Each destructive command has a human-readable warning. Apply this to teaching: always show the naive/broken version with a clear warning before the correct version.
