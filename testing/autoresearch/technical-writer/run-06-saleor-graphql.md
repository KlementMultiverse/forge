# Run 06: saleor -- Write GraphQL API guide for frontend developers

## Task
Write a GraphQL API guide for frontend developers working with Saleor.

## Code Read
- No saleor repo available locally
- Would need GraphQL schema, resolver patterns, common queries/mutations

## Prompt Evaluation

### What the prompt guided well
1. **Audience Analysis** -- "User skill level assessment, goal identification" -- frontend dev audience is well-defined
2. **Practical Examples** -- "Working code samples" -- critical for GraphQL guides
3. **STRUCTURE step** -- "API ref -> endpoint tables" needs adaptation for GraphQL (queries/mutations, not REST endpoints)

### What the prompt missed or was weak on
1. **No GraphQL-specific documentation patterns** -- Prompt treats all APIs the same. GraphQL needs: query examples, fragment patterns, subscription docs, error handling patterns distinct from REST
2. **No schema exploration instruction** -- GraphQL has introspection; prompt should instruct agent to document how to explore the schema (GraphiQL, playground URLs)
3. **No query optimization guidance** -- Frontend devs need to know about query depth limits, complexity limits, pagination patterns (cursor vs offset). Prompt doesn't push for performance guidance
4. **No type documentation instruction** -- GraphQL types are the contract; prompt should push for type reference with field descriptions
5. **No mutation pattern documentation** -- Mutations in Saleor follow patterns (input types, error handling); prompt doesn't push for pattern documentation
6. **No frontend framework integration** -- How to use with React/Next.js (Apollo Client setup, codegen)? Prompt doesn't push for integration guides

### Documentation Quality Score: 4/10
- Without codebase, would produce generic GraphQL guide
- GraphQL documentation requires schema-specific examples that can't be invented
- Prompt's "API ref -> endpoint tables" format doesn't translate well to GraphQL

## Prompt Gaps Identified
| Gap | Severity | Fix |
|-----|----------|-----|
| No API paradigm-specific templates | High | Add: "Adapt documentation format to API paradigm: REST -> endpoint tables, GraphQL -> query/mutation examples with types, gRPC -> service/method definitions" |
| No schema exploration docs | Medium | Add: "For APIs with introspection/discovery, document how to explore the API interactively" |
| No query optimization guidance | Medium | Add: "Include performance guidance: query limits, pagination patterns, caching strategies" |
| No type/schema reference | Medium | Add: "For typed APIs, produce type reference with field descriptions and relationships" |
| No framework integration guide | Low | Add: "For APIs consumed by frontend, include client library setup and code generation" |
