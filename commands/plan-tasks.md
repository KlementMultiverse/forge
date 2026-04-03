# /plan-tasks — Break Design Doc Into Implementation Tasks

Convert a design document into phased, dependency-ordered implementation tasks with GitHub Issues.

## Input
$ARGUMENTS — path to the design document (default: docs/design-doc.md)

## Execution

1. Read the design document (all sections)
2. Read SPEC.md for [REQ-xxx] traceability
3. Break into phases with dependency ordering:
   - Phase 1: Infrastructure (Docker, config, settings)
   - Phase 2: Models (shared first, then tenant)
   - Phase 3: APIs (auth first, then domain endpoints)
   - Phase 4: Frontend (templates, JS, CSS)
   - Phase 5: Integration (Lambda, S3, external services)
   - Phase 6: Testing + validation

4. For each task, define:
   - Title (prefixed with phase: `[Phase N] Task Title`)
   - Description with acceptance criteria (Given/When/Then)
   - Files to create/modify
   - Dependencies (which tasks must complete first)
   - [REQ-xxx] links
   - Labels: `phase-N`, `domain-X`
   - Parallel marker `[P]` if safe to run with previous task

5. **Create GitHub Issues** (with graceful fallback):

   ```bash
   # Check if gh CLI is available and authenticated
   if gh auth status 2>/dev/null; then
     # Check if GitHub remote exists
     if git remote get-url origin 2>/dev/null; then
       # Create issues via gh CLI
       for each task:
         gh issue create \
           --title "[Phase N] Task Title" \
           --body "Description + acceptance criteria" \
           --label "phase-N,domain-X"
     fi
   fi
   ```

   **Fallback — if `gh` is unavailable or no remote exists:**
   Save issues as markdown files to `docs/issues/` with this format:

   ```markdown
   # [Phase N] Task Title
   **From:** Implementation Plan
   **Files:** path/to/file.py
   **Depends on:** #[issue-number]
   **Labels:** phase-N, domain-X
   **Status:** open

   ## Description
   [task description]

   ## Acceptance Criteria
   Given... When... Then...
   ```

   File naming: `docs/issues/phase-N-NN-task-slug.md` (e.g., `docs/issues/phase-1-01-docker-setup.md`)

6. Generate implementation plan summary: `docs/implementation-plan.md`

## Output

- `docs/implementation-plan.md` — ordered task table with dependencies
- GitHub Issues (or `docs/issues/*.md` if no remote)
- Each task links to [REQ-xxx] from SPEC.md

## Validation

PM verifies:
- Dependency order correct? (infra -> models -> APIs -> frontend)
- Each task links to [REQ-xxx]?
- Parallel markers [P] correct? (no write conflicts)
- All [REQ-xxx] from SPEC.md are covered by at least one task
- Acceptance criteria are testable (Given/When/Then format)
