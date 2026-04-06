# /sc:reflect — Validate Completion

Verify that the build is truly complete and all requirements are satisfied.

## What It Does

1. Run forge-triangle.sh check (full triangle sync)
2. Run traceability.sh (REQ coverage)
3. Verify all issues are closed
4. Verify all tests pass
5. Verify Docker is healthy
6. Check: any TODO/FIXME remaining?
7. Check: any deferred items not tracked?

## Output
- Completion report: DONE or REMAINING items
- If REMAINING: list what's left and why
