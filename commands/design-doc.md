---
context: fork
---
# /design-doc — Architecture Design Document

Generate a design document following the Week 3 template exactly. 10 sections. Every decision uses "Will implement X because" format with trade-offs and alternatives.

## Input
$ARGUMENTS — path to feature proposal (e.g., docs/proposals/01-clinic-portal.md)

## Phase 0: Context Loading (MANDATORY)

<system-reminder>
Do NOT skip this phase. Read everything before designing anything.
Fetch library docs via context7 MCP BEFORE making any technical decisions.
</system-reminder>

1. Read CLAUDE.md → extract: tech stack, architecture rules, API contracts, anti-patterns
2. Read the feature proposal at $ARGUMENTS → extract: requirements, user stories, acceptance criteria
3. Read SPEC.md if it exists → extract: project structure, model definitions, API endpoints
4. Fetch library documentation via context7 MCP for all libraries listed in the project's CLAUDE.md Tech Stack section:
   - `resolve-library-id` for each library in the Tech Stack table
   - `query-docs` for each: setup patterns, configuration, middleware requirements
5. Read existing code (if any) to understand current state

## Phase 1: Architecture Design

Spawn `@system-architect` with:
  TASK: Design the overall system architecture from the proposal requirements
  CONTEXT: CLAUDE.md + proposal + SPEC.md + context7 docs
  EXPECTED OUTPUT: Component diagram, data flow, integration points

Spawn `@backend-architect` with:
  TASK: Design the database schema, API layer, and service layer
  CONTEXT: CLAUDE.md + proposal + SPEC.md + context7 django-tenants docs
  EXPECTED OUTPUT: Model designs, API route structure, service patterns

Spawn `@security-engineer` with:
  TASK: Review the architecture for security: tenant isolation, auth, S3 access, audit logging
  CONTEXT: CLAUDE.md + proposal + SPEC.md
  EXPECTED OUTPUT: Security requirements, threat model, mitigation strategies

## Phase 2: Fill Design Document Template

<system-reminder>
Every design decision MUST follow this exact format:
  "Will implement [X] because:"
  - Rationale bullets (WHY this choice)
  - Trade-off: [what you give up]
  - Alternative considered: [what you didn't pick and why]
If a decision is missing any of these 4 parts, it is INCOMPLETE.
</system-reminder>

Using the output from Phase 1, fill this template EXACTLY:

```markdown
# [Feature Name] — Design Document

**Date:** [YYYY-MM-DD]
**Proposal:** [link to proposal]
**Status:** Draft

---

## 1. Current Context

### Existing System
[What exists now. Key components and relationships.]

### Gap Being Addressed
[What is broken or missing. Why this design is needed.]

### Scope
[Who uses this. How many users. Local/cloud. Single/multi-tenant.]

---

## 2. Requirements

### Functional Requirements
[From the proposal's user stories and acceptance criteria. Numbered list.]

### Non-Functional Requirements
- **Performance:** [response time targets, throughput]
- **Scalability:** [concurrent tenants, data volume]
- **Observability:** [logging points, metrics]
- **Security:** [auth, tenant isolation, encryption, audit]
- **Reliability:** [error handling, graceful degradation]

---

## 3. Design Decisions

### Decision 1: [Major Choice]
Will implement [approach] because:
- [Rationale 1]
- [Rationale 2]
- Trade-off: [what you give up]
- Alternative considered: [what you didn't pick and why]

### Decision 2: [Another Choice]
Will implement [approach] because:
- [Rationale 1]
- Trade-off: [what you give up]
- Alternative considered: [what you didn't pick and why]

[EXAMPLE from Weather MCP Server — follow this format exactly:

### Transport: STDIO
Will implement STDIO transport because:
- Personal local tool — runs on developer's machine, no multi-user requirement
- Client spawns server automatically — no port management needed
- Trade-off: one connection at a time, not cloud-deployable without rewriting transport
- Alternative considered: HTTP — independent server on port, concurrent connections,
  cloud-deployable. Adds unnecessary complexity for a local single-user tool.]

[Minimum 8 design decisions for a full project. Cover: framework, database, auth, storage, LLM integration, frontend approach, state management, user model, audit logging, testing strategy.]

---

## 4. Technical Design

### Core Components
[Code interfaces with type hints. Key classes and their responsibilities.]

### Data Models
[Model definitions. Field types. Relationships. Constraints.]

### Integration Points
[How components connect. API contracts between layers. External service interfaces.]

### File Changes
[EXPLICIT list of files to create or modify. ONLY these files will be touched.]
- `path/to/file.py` — [what this file does]

---

## 5. Implementation Plan

| Step | What | Why This Order | Files |
|------|------|---------------|-------|
| 1 | [First thing to build] | [Why this comes first] | [files] |
| 2 | [Second thing] | [Dependency on step 1] | [files] |

[Steps MUST be ordered by dependency. Each step produces something testable.]

---

## 6. Testing Strategy

| # | Scenario | Input | Expected | Pass Condition |
|---|----------|-------|----------|----------------|
| 1 | [Happy path] | [input] | [output] | [what to check] |
| 2 | [Error case] | [input] | [error] | [server still running] |

[Minimum 15 test scenarios. Include: happy path (CRUD for each resource), auth failures (wrong password, no session), tenant isolation (cross-tenant access blocked), role checks (staff vs admin), state machine violations (invalid + terminal transitions), business rule enforcement (blocked deletes), presigned URL generation, graceful degradation (Lambda/S3 failures), validation errors (empty inputs, invalid IDs), edge cases (empty data sets).]

Critical: after each error test, run a success test to confirm no crash.

---

## 7. Observability

10 required logging points (Steve's SDLC):
1. Function entry/exit
2. Errors (with context)
3. External API calls (S3, Lambda)
4. State mutations (task transitions, document uploads)
5. Security events (login, failed auth, tenant access denied)
6. Business milestones (tenant created, workflow completed)
7. Performance anomalies (slow queries, Lambda timeouts)
8. Configuration changes
9. Validation failures (invalid transitions, bad input)
10. Resource limit violations

Logs to stderr if MCP involved. Never log: passwords, tokens, API keys, PII.

---

## 8. Future Considerations

### Potential Enhancements
[What could be added later but is NOT in scope now]

### Known Limitations
[Current constraints. Technical debt accepted for this phase.]

---

## 9. Dependencies

### Development Dependencies
[uv packages, Docker images, AWS services]

### External Services
[AWS S3, Lambda, PostgreSQL, Redis — with version requirements]

---

## 10. Security Considerations

- **Authentication:** [Session auth via Redis. Login/logout flow.]
- **Authorization:** [Admin vs Staff roles. TenantAccessMiddleware.]
- **Tenant Isolation:** [PostgreSQL schema-per-tenant. S3 key namespacing. Cache key isolation.]
- **Data Protection:** [Presigned URL expiry. Server-side encryption. No direct S3 access.]
- **Audit Trail:** [AuditLog model. Every mutation logged with user + timestamp.]
- **Secrets Management:** [All credentials in .env. Never committed. .gitignore enforced.]
```

## Phase 3: Review with Spec Panel

Run `/sc:spec-panel` on the completed design doc to get multi-expert review.
Address any feedback from the panel before saving.

## Phase 4: Save & Handoff

1. Save to `docs/design-doc.md`
2. Return handoff:

```
## Handoff: design-doc → plan-tasks
### Task Completed: Design document written (10 sections)
### Files Changed: docs/design-doc.md
### Test Results: Spec panel review completed. [count] design decisions validated.
### Context for Next Agent: Design is ready for task breakdown via /plan-tasks
### Blockers: [any unresolved NEEDS CLARIFICATION from proposal, or "None"]
```
