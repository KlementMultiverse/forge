# /generate-spec — Auto-Generate SPEC.md

Synthesize discovery, requirements, and feasibility into a complete SPEC.md.

<system-reminder>
CRITICAL RULES:
- Every requirement MUST have [REQ-xxx] tag — no untagged requirements
- Minimum 15 [REQ-xxx] tags — if fewer, add non-functional requirements
- Read templates/SPEC.template.md via Read tool for structure
- Models MUST have exact field types (CharField(max_length=200), not "string")
</system-reminder>

## Input
Three documents:
- docs/discovery-report.md
- docs/requirements.md
- docs/feasibility.md

## Execution

PM Orchestrator synthesizes all three documents into SPEC.md using the template at templates/SPEC.template.md.

1. Read all three input documents
2. Read templates/SPEC.template.md for structure
3. Map every requirement [REQ-xxx] into the appropriate SPEC section
4. Include all models, API endpoints, frontend pages from requirements
5. Include tech stack from feasibility
6. Include security rules from security assessment
7. Include business rules from requirements

## Output

Save to project root as `SPEC.md`:
- Every section from the template filled in
- Every requirement tagged [REQ-xxx]
- API contracts with exact request/response shapes
- Models with field types and constraints

## Persist REQ Tags

After generating SPEC.md, ensure all [REQ-xxx] tags are persisted:

1. Check if SPEC.md already has a `## Requirements Traceability` section
2. If not → append one at the end of SPEC.md
3. Build a traceability table from all [REQ-xxx] tags found in SPEC.md:

```markdown
## Requirements Traceability

| REQ | Description | Section | Test | Code |
|-----|-------------|---------|------|------|
| [REQ-001] | [short description] | [which SPEC section] | [ ] | [ ] |
| [REQ-002] | [short description] | [which SPEC section] | [ ] | [ ] |
```

4. This table is the single source of truth for tracking implementation progress
5. `/plan-tasks` and Forge Cell Step 5 (sync check) update the Test and Code columns

## Judge
@requirements-analyst verifies:
- All [REQ-xxx] from requirements.md are present in SPEC.md
- No requirement was dropped or changed
- API contracts are complete (request + response + errors)
- Models match requirements
- Requirements Traceability section exists with all [REQ-xxx] listed
