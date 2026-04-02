# /generate-spec — Auto-Generate SPEC.md

Synthesize discovery, requirements, and feasibility into a complete SPEC.md.

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

## Judge
@requirements-analyst verifies:
- All [REQ-xxx] from requirements.md are present in SPEC.md
- No requirement was dropped or changed
- API contracts are complete (request + response + errors)
- Models match requirements
