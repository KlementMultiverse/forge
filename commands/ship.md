# /ship — Release Engineering

Full release pipeline: sync main, verify tests, audit coverage, push, create PR, merge, deploy, monitor. One command from "code complete" to "verified in production."

## Input
$ARGUMENTS — optional: branch name (default: current branch)

## Execution

### Pre-Flight
```bash
# 1. Sync with main
git fetch origin main
git rebase origin/main

# 2. Run full test suite
uv run python manage.py test

# 3. Run lint
black --check . && ruff check .

# 4. Run audit
# /audit-patterns full → must be >90%

# 5. Run traceability
# scripts/traceability.sh → 100% coverage, 0 orphans

# 6. Run security scan
# /security-scan → no CRITICAL/HIGH findings
```

### Ship
```bash
# 7. Push branch
git push -u origin $(git branch --show-current)

# 8. Create PR
gh pr create --title "[Release] $(git branch --show-current)" \
  --body "## Release Checklist
  - [x] Tests pass
  - [x] Lint clean
  - [x] Audit >90%
  - [x] Traceability 100%
  - [x] Security scan clean
  - [ ] CodeRabbit approved
  - [ ] Merged
  - [ ] Production verified"

# 9. Wait for CodeRabbit
# /gate → 0 suggestions

# 10. Merge
gh pr merge --squash

# 11. Deploy (if deployment config exists)
# Stack-specific: docker push, railway deploy, etc.

# 12. Monitor
# /canary → watch production for 30 minutes
```

## Output

```markdown
## Release: [branch] → main

### Pre-Flight
- Tests: [pass/fail]
- Lint: [clean/issues]
- Audit: [%]
- Traceability: [%]
- Security: [risk level]

### Ship
- PR: #[number]
- CodeRabbit: [approved/pending]
- Merged: [yes/no]
- Deployed: [yes/no/skipped]

### Post-Deploy
- Canary: [healthy/degraded/down]
- Duration: [minutes monitored]
```

## When To Run
- Phase 5: after /gate stage-5 passes (final release)
- Phase 6: for hotfix releases
