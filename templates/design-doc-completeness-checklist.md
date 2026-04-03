# Design Doc Completeness Checklist

Run this AFTER /design-doc produces output, BEFORE /gate allows progression to Stage 3.
Every item is REQUIRED. If any item fails, the design doc is INCOMPLETE — fix before proceeding.

## Section 1: Current Context
- [ ] Existing system described (or "greenfield" stated explicitly)
- [ ] Gap being addressed is specific (not generic "improve things")
- [ ] Scope includes: user types, scale target, deployment model

## Section 2: Requirements
- [ ] Every functional requirement has [REQ-xxx] tag
- [ ] Non-functional requirements include: performance targets (with numbers), scalability, observability, security, reliability
- [ ] Performance targets are MEASURABLE (e.g., "< 200ms" not "fast")

## Section 3: Design Decisions
- [ ] Minimum 8 decisions for a full project
- [ ] EVERY decision uses "Will implement X because:" format
- [ ] EVERY decision has trade-off statement
- [ ] EVERY decision has "Alternative considered:" with why rejected
- [ ] No contradictions with CLAUDE.md rules (check each decision against Architecture Rules)

## Section 4: Technical Design
### Models
- [ ] Every model has: field names, field types, constraints, relationships
- [ ] on_delete behavior specified for every ForeignKey
- [ ] Indexes specified (db_index=True, Meta.indexes, GIN indexes)
- [ ] SHARED vs TENANT split clearly marked (if multi-tenant)

### API Contracts
- [ ] Every endpoint has: method, path, request JSON, response JSON, status codes, error codes
- [ ] Pydantic/Schema classes defined (not just JSON examples)
- [ ] Error response format standardized (ONE format for all errors)
- [ ] Pagination strategy specified (library, page_size default, max)
- [ ] Auth requirement specified per endpoint (auth=None, auth=session, auth=admin)

### Configuration
- [ ] settings.py skeleton includes: DATABASES, MIDDLEWARE, CACHES, INSTALLED_APPS
- [ ] Dockerfile contents specified (base image, build steps, CMD)
- [ ] docker-compose.yml services listed with ports and volumes
- [ ] .env.example with ALL required environment variables

### Flows
- [ ] Every async flow has BOTH sides specified (trigger AND callback/poll)
- [ ] Every multi-step flow has exact sequence (step 1 -> endpoint -> step 2 -> endpoint)
- [ ] No "either A or B" ambiguity — ONE approach chosen and documented
- [ ] Schema switch points documented (if multi-tenant)

## Section 5: Implementation Plan
- [ ] Steps ordered by dependency (infrastructure -> models -> APIs -> frontend)
- [ ] Each step names exact files to create/modify
- [ ] Each step links to [REQ-xxx] tags
- [ ] Commit granularity specified (one commit per step? per phase?)
- [ ] [P] markers for parallelizable tasks

## Section 6: Testing Strategy
- [ ] Minimum 15 test scenarios
- [ ] Covers: happy path, auth failures, validation errors, state machine violations, cross-tenant isolation
- [ ] Each scenario has: input, expected output, pass condition
- [ ] Each scenario links to [REQ-xxx]
- [ ] Test base class specified (TestCase vs TenantTestCase)

## Section 7: Observability
- [ ] 10 logging points specified with category, what to log, level
- [ ] "Never log" list present (passwords, tokens, keys)
- [ ] Log format specified (structured JSON? plain text?)

## Section 8-10: Future, Dependencies, Security
- [ ] Known limitations documented honestly
- [ ] All external services listed with version requirements
- [ ] Security section covers: auth, authz, CSRF, input validation, secrets, headers
- [ ] Tenant isolation section covers: DB, storage, cache, auth (if multi-tenant)

## Final Check
- [ ] A developer can implement ANY step without asking questions
- [ ] No two developers would implement the same step differently
- [ ] Every [REQ-xxx] from Section 2 appears in at least one test scenario in Section 6
