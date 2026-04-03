# Requirements Analyst Agent: Autoresearch Summary (10 Runs)

## Aggregate Evaluation

| Criterion | Pass Rate | Notes |
|---|---|---|
| REQ-xxx tagging | 10/10 | Every requirement tagged, domain-prefixed in later runs |
| Given/When/Then acceptance criteria | 7/10 | Missed on enumerations and absent features |
| Completeness (covered full scope) | 4/10 | Large codebases (saleor, medusa) only partially covered |
| Duplicate check | 10/10 | No duplicates found in any run |
| Implicit requirements discovered | 8/10 | Good at finding defensive coding patterns, security measures |
| Explicit vs implicit distinction | 3/10 | Only run 01 explicitly separated these categories |
| NFR taxonomy | 3/10 | Only run 05 used a systematic NFR taxonomy |
| Reverse-engineering workflow | 0/10 | Prompt has NO reverse-engineering mode — all runs improvised |

## Prompt Gaps Identified (Consolidated, Deduplicated)

### GAP 1: No Reverse-Engineering Mode (Critical)
- **Seen in**: ALL 10 runs
- **Problem**: The prompt is designed for forward requirements (stakeholder → requirements). Reverse engineering (code → requirements) needs a different workflow: read models → read routes → read configs → read tests → synthesize
- **Fix**: Add a new section:
```
### Reverse-Engineering Mode
When extracting requirements from existing code (no stakeholder available):
1. Read model definitions (DB schema, ORM models) → extract data requirements
2. Read API routes/endpoints → extract functional requirements
3. Read middleware/configs → extract cross-cutting requirements (auth, caching, security)
4. Read error handling patterns → extract resilience/availability requirements
5. Read tests → extract acceptance criteria (tests ARE requirements)
6. Read deployment configs (Docker, CI) → extract infrastructure requirements
7. Distinguish: EXPLICIT (in docs) vs IMPLICIT (only in code) vs ABSENT (not found)
```

### GAP 2: No NFR Extraction Taxonomy (Critical)
- **Seen in**: Runs 1, 2, 4, 6, 7, 8, 10
- **Problem**: Chaos Resilience mentions "add defaults (performance, security, observability)" but doesn't provide a systematic checklist
- **Fix**: Add to Focus Areas:
```
- **NFR Categories**: Always check for these categories when extracting non-functional requirements:
  Performance (latency, throughput, caching), Security (auth, input validation, data protection),
  Availability (graceful degradation, retry, fallback), Observability (logging, tracing, metrics),
  Data Integrity (immutability, validation, constraints), Infrastructure (deployment, scaling, dependencies),
  Scalability (batch processing, connection limits, resource bounds)
```

### GAP 3: No "Absent Feature" Protocol (High)
- **Seen in**: Run 8 (medusa multi-tenancy)
- **Problem**: When asked to extract requirements for a capability that doesn't exist, no protocol
- **Fix**: Add to Chaos Resilience:
```
- Requested capability is absent from codebase → document: (a) what EXISTS instead, (b) what's ABSENT, (c) classify as: implementable with current architecture / requires architecture change / fundamentally incompatible
```

### GAP 4: No Source-Type Taxonomy (High)
- **Seen in**: Runs 4, 7, 9, 10
- **Problem**: The prompt doesn't list what types of files contain requirements
- **Fix**: Add to Forge Cell Compliance:
```
Sources for reverse-engineering (check all):
- Model/schema definitions → data requirements, constraints, relationships
- API routes/endpoints → functional requirements, auth requirements
- Middleware/interceptors → cross-cutting concerns
- Error handling patterns → resilience requirements
- Configuration files → infrastructure, security requirements
- Deployment configs (Docker, k8s) → infrastructure requirements
- Test files → acceptance criteria (tests ARE implicit requirements)
- Interface/abstract classes → extension point requirements
- Deprecation notices → migration requirements
```

### GAP 5: No Scoping Guidance for Large Codebases (High)
- **Seen in**: Runs 2, 6, 10
- **Problem**: Saleor has 20+ domains. The prompt doesn't say how to handle partial extraction
- **Fix**: Add to Key Actions:
```
6. **Scope Declaration**: If the codebase is larger than the task scope, explicitly list: domains covered, domains NOT covered, and estimated effort to cover remaining domains
```

### GAP 6: No Domain-Prefixed ID Instruction (Medium)
- **Seen in**: Runs 1-3 (improved in later runs through self-correction)
- **Problem**: Plain REQ-001 is ambiguous across domains. REQ-AUTH001 is better.
- **Fix**: Change anti-pattern to: "NEVER write requirements without domain-prefixed [REQ-DOMAIN-xxx] tags"

### GAP 7: No Quantitative Requirement Extraction (Medium)
- **Seen in**: Run 5
- **Problem**: Hard-coded numbers (cache TTLs, batch sizes, timeouts) are measurable requirements but the prompt doesn't instruct to find them
- **Fix**: Add to Key Actions:
```
7. **Extract Quantitative Requirements**: Look for hard-coded numbers in code (timeouts, limits, TTLs, batch sizes, max retries) and express them as measurable requirements with specific thresholds
```

### GAP 8: No Deprecation Tracking (Low)
- **Seen in**: Run 6
- **Problem**: Deprecated features represent migration requirements
- **Fix**: Add to Focus Areas: "Flag deprecated features as [REQ-DEP-xxx] — they represent future removal and migration needs"

### GAP 9: No Integration Delivery Guarantee Extraction (Low)
- **Seen in**: Run 10
- **Problem**: Webhook/event systems have delivery guarantees (at-least-once, retry, dead-letter) that the prompt doesn't ask for
- **Fix**: Add to Chaos Resilience: "For event/message-based integrations, extract delivery guarantees (at-least-once, exactly-once, retry policy, dead-letter handling)"

## Recommended Prompt Patch

See individual GAP fix sections above. The highest-priority additions are:
1. Reverse-Engineering Mode (GAP 1)
2. NFR Extraction Taxonomy (GAP 2)
3. Source-Type Taxonomy (GAP 4)
4. Scoping Guidance (GAP 5)
