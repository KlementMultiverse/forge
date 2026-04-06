# /sc:save — Persist Session Artifacts

Save all session artifacts and state for continuity.

## What It Does

1. Update forge-state.json with final status
2. Save forge-timeline.md with session summary
3. Commit all remaining changes
4. Push to remote
5. Update FORGE.md (move item from Active to Done)

## Rules
- Every file must be committed (no uncommitted changes)
- Final commit message references all issues closed this session
- Push must succeed (no force push)
