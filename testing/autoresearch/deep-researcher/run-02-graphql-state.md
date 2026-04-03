# Run 02: State of GraphQL in 2025 -- when to use vs REST vs gRPC

## Research Topic
"State of GraphQL in 2025 -- when to use vs REST vs gRPC"

## Research Performed
- WebSearch: "GraphQL state 2025 2026 vs REST vs gRPC when to use comparison"
- WebFetch: JavaCodeGeeks 2026 API architecture decision article (successful)

## Prompt Evaluation

### What the prompt guided well
1. **Temporal Progression** pattern worked perfectly -- current adoption (50%+ enterprise GraphQL) -> recent changes (gRPC default for microservices) -> future implications (hybrid architectures win)
2. **Alternative comparison** -- naturally produced REST vs GraphQL vs gRPC with clear use-case mapping
3. **Current best practices** -- captured the hybrid pattern (REST/GraphQL public + gRPC internal + event streaming async)
4. **Trend check** -- noted tRPC as emerging alternative in TypeScript ecosystems

### What the prompt missed or was weak on
1. **No instruction to include performance benchmarks** -- found gRPC is 5-10x throughput vs REST, but only because the source included it, not because prompt asked
2. **No "total cost of ownership" lens** -- prompt doesn't push for TCO analysis (team learning curve, tooling costs, migration effort)
3. **No instruction to assess ecosystem maturity** -- how mature are the client libraries, how good is tooling?
4. **"When NOT to use" is not emphasized** -- prompt focuses on when to use but anti-patterns are equally valuable

### Research Quality Score: 9/10
- Sources found: 8 relevant
- Alternatives compared: 4 (REST, GraphQL, gRPC, tRPC)
- Actionable recommendation produced: Yes -- decision framework with clear criteria
- Key insight: "Team expertise trumps benchmarks -- a well-implemented REST API frequently outperforms a poorly designed GraphQL service"

## Handoff Output (as agent would produce)

```
## Research Completed
### Summary: GraphQL adoption hit 50%+ enterprise in 2026. The winning pattern is hybrid: REST/GraphQL for client-facing, gRPC for internal services, event streaming for async. No single protocol wins all use cases.
### Approach Recommended: For new projects, start with REST unless you have complex nested data requirements (then GraphQL) or internal microservices (then gRPC).
### Alternatives Considered:
- REST: Universal compatibility, HTTP caching, lowest learning curve. 5K-15K req/sec.
- GraphQL: Flexible queries, mobile optimization, 50%+ enterprise adoption. N+1 and caching challenges.
- gRPC: 50K-100K req/sec, binary serialization, bidirectional streaming. High learning curve, poor browser support.
- tRPC: Type-safe end-to-end in TypeScript. Limited to TS ecosystems.
### Sources:
- https://www.javacodegeeks.com/2026/02/graphql-vs-rest-vs-grpc-the-2026-api-architecture-decision.html
- https://dev.to/pockit_tools/rest-vs-graphql-vs-trpc-vs-grpc-in-2026-the-definitive-guide-to-choosing-your-api-layer-1j8m
- https://blobstreaming.org/notes/graphql-vs-rest-vs-grpc-2026/
### Delegation Hints: Next: @system-architect should select API protocol based on client requirements and team expertise assessment.
### Risks/Unknowns: Protocol migration typically requires 2-5x the initial build effort -- plan carefully.
### Insights for Playbook:
INSIGHT: Team expertise trumps benchmarks -- a well-implemented REST API frequently outperforms a poorly designed GraphQL service.
INSIGHT: Netflix pattern: gRPC internal + GraphQL mobile/web + REST third-party is the emerging enterprise standard.
INSIGHT: GraphQL caching complexity can increase infrastructure costs significantly for high-traffic applications.
```

## Prompt Gaps Identified
| Gap | Severity | Fix |
|-----|----------|-----|
| No performance benchmark guidance | Medium | Add: "Include quantitative performance data when available (latency, throughput, message size)" |
| No TCO analysis instruction | High | Add: "Assess total cost of ownership: learning curve, tooling, migration effort, operational complexity" |
| No ecosystem maturity check | Medium | Add: "Evaluate ecosystem maturity: client libraries, tooling, community support, hiring market" |
| No anti-pattern emphasis | Low | Add: "Include 'when NOT to use' for each alternative" |
