# /plan-review — Product & Architecture Review

Combined product scope review + architecture validation. Challenges WHAT we're building (product) and HOW we're building it (architecture). Runs before implementation starts.

## Input
$ARGUMENTS — path to spec or design doc

## Execution

### Product Review (is this the RIGHT thing to build?)

Spawn @business-panel-experts:
1. **Scope Assessment:** Is this an MVP, a full product, or over-scoped?
   - Find "the 10-star product hiding inside the request"
   - Identify features that can be deferred to v2
   - Rate: Expansion / Selective Expansion / Hold Scope / Reduction

2. **Market Fit:** Does anyone actually need this?
   - Cross-reference with /challenge results
   - Check: are the [REQ-xxx] solving REAL problems or assumed ones?

3. **Priority Stack:** What's the critical path?
   - Which features deliver value on day 1?
   - Which can wait?
   - Order: must-have → should-have → nice-to-have

### Architecture Review (is this the RIGHT way to build it?)

Spawn @system-architect + @security-engineer:
1. **Decision Validation:** Every "Will implement X because" in design doc
   - Are the rationales solid?
   - Are the trade-offs acceptable?
   - Are the alternatives fairly evaluated?

2. **Risk Assessment:** What could go wrong?
   - Single points of failure?
   - Security vulnerabilities in the architecture?
   - Scalability bottlenecks?
   - Data isolation risks (multi-tenancy)?

3. **Diagram Generation:** Make the architecture visible
   - Component diagram (what talks to what)
   - Data flow diagram (how data moves)
   - Sequence diagrams for critical paths (auth, payments, etc.)

### Verdict
```
Product: [BUILD AS-IS / REDUCE SCOPE / EXPAND / RETHINK]
Architecture: [SOLID / NEEDS CHANGES / RISKY]

Changes Required:
- [Change 1 with rationale]
- [Change 2 with rationale]
```

## When To Run
- Phase 2: after /design-doc, before /plan-tasks
- Phase 0: after /challenge if scope is uncertain
- On demand: when product direction is questioned
