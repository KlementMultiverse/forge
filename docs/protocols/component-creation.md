# Component Creation Protocols

Step-by-step protocols for creating, modifying, and testing every forge component type. Following these ensures nothing is missed — no unwired scripts, no untested code, no broken traceability.

---

## Protocol: Creating a New Script

```
1. Create GitHub issue describing what the script does
2. Create branch: git checkout -b feat/script-name-{issue}
3. Write BATS test FIRST (RED — test fails)
   → tests/bash/unit/{script-name}.bats
4. Create script (GREEN — test passes)
   → scripts/{script-name}.sh
5. Run full test suite: tests/bats/bin/bats tests/bash/unit/
   → 0 failures, 0 regressions
6. Run forge-test-guard.sh
   → Must show script as tested
7. Run --impact on related files:
   → python3 scripts/forge-registry.py --impact scripts/{script-name}.sh
8. If script needs auto-invocation:
   → Wire into templates/hooks.json (PreToolUse, PostToolUse, etc.)
   → OR wire into gate command
   → Write integration test for the hook
9. chmod +x scripts/{script-name}.sh
10. Update forge-registry.py if needed (new scanner)
11. Run forge-lint.py --update-registry
12. Commit: feat(scripts): description #{issue}
13. Push → PR (one issue per PR)
14. Tag @coderabbitai → wait → address comments → loop
15. Only merge on explicit [approve]
```

### Checklist (copy into PR description)
- [ ] Test written FIRST (RED → GREEN)
- [ ] Full suite passes (0 regressions)
- [ ] forge-test-guard.sh shows script as tested
- [ ] --impact checked on affected files
- [ ] Wired into hook/gate if auto-invocation needed
- [ ] chmod +x set
- [ ] CodeRabbit explicit [approve]

---

## Protocol: Creating a New Command

```
1. Create GitHub issue
2. Create branch: git checkout -b feat/command-name-{issue}
3. Write validation test (commands-validation.bats or new .bats file)
   → Test: file exists, header format correct, frontmatter if needed
4. Create command: commands/{command-name}.md
   → Header: # /command-name — description
   → YAML frontmatter if using context:fork
   → <system-reminder> if enforcement-critical
5. If pipeline step: add to phase file
   → commands/forge-phases/phase-{N}.md
6. Run commands-validation.bats
   → All skill/agent references resolve
7. Run full test suite
8. Commit: feat(commands): description #{issue}
9. PR → CR → [approve] → merge
```

### Checklist
- [ ] Validation test passes
- [ ] Header format: # /name — description
- [ ] Referenced in phase file (if pipeline step)
- [ ] All skill/agent references resolve
- [ ] CodeRabbit explicit [approve]

---

## Protocol: Creating a New Agent

```
1. Create GitHub issue
2. Create branch
3. Write schema validation test
   → Test: frontmatter has name, description, tools
   → Test: heading format correct
4. Create agent: agents/universal/{agent-name}.md
   → YAML frontmatter: name, description, tools, category
   → Heading: # @agent-name
   → Clear system prompt with instructions
5. If domain-specific: add to .claude/rules/agent-routing.md
6. Run forge-lint.py (checks frontmatter + orphan status)
7. Run full test suite
8. Commit: feat(agents): description #{issue}
9. PR → CR → [approve] → merge
```

### Checklist
- [ ] YAML frontmatter: name, description, tools
- [ ] Schema validation test passes
- [ ] Added to agent-routing.md if domain-specific
- [ ] forge-lint.py passes
- [ ] CodeRabbit explicit [approve]

---

## Protocol: Modifying Existing Code

```
1. BEFORE editing: run --impact on the file
   → python3 scripts/forge-registry.py --impact <file>
   → Note: what other files are affected?
2. Check OWNERS file: who owns this code?
   → bash scripts/forge-ownership.sh who <file>
3. Check suspect REQs: any unverified?
   → bash scripts/forge-enforce.sh check-suspect
4. Make changes
5. Run forge-triangle.sh check (if file has REQ tags)
   → Triangle still synced?
6. Run full test suite
   → 0 regressions
7. Update forge-trace block in modified file
   → bash scripts/forge-trace-update.sh add <file> <REQ> <agent> <PR> <desc>
8. Commit with conventional format
9. PR → CR → [approve] → merge
```

### Checklist
- [ ] --impact checked BEFORE editing
- [ ] OWNERS verified
- [ ] No suspect REQs
- [ ] Triangle still synced after changes
- [ ] Full test suite passes
- [ ] Forge trace updated
- [ ] CodeRabbit explicit [approve]

---

## Protocol: Wiring Into Hooks

```
1. Create GitHub issue
2. Write integration test: tests/bash/integration/
   → Test: hook fires, correct output, doesn't block when shouldn't
3. Add hook entry to templates/hooks.json
   → Choose event: PreToolUse, PostToolUse, Stop, UserPromptSubmit
   → Choose matcher: Bash, Edit, Write, Agent, Skill, (all)
   → Advisory (print warning) or blocking (exit non-zero)?
4. Test hook fires correctly
5. Update README hooks section
6. Update install.sh if needed
7. Commit: feat(hooks): description #{issue}
8. PR → CR → [approve] → merge
```

### Checklist
- [ ] Integration test passes
- [ ] Hook added to templates/hooks.json
- [ ] Advisory vs blocking behavior documented
- [ ] README hooks table updated
- [ ] CodeRabbit explicit [approve]

---

## Protocol: Creating a New Test

```
1. Identify what needs testing (script, command, agent, flow)
2. Create test file in correct location:
   → Bash scripts: tests/bash/unit/{name}.bats
   → Python scripts: tests/python/unit/test_{name}.py
   → Integration: tests/bash/integration/{flow}.bats
3. Write tests covering:
   → Happy path (expected behavior)
   → Failure path (error handling)
   → Edge cases (empty input, missing files, etc.)
4. Run test → should FAIL if code doesn't exist yet (TDD)
5. Run full suite after code is written → 0 regressions
6. forge-test-guard.sh must show the script as tested
7. Commit test with the code change
```

---

## Anti-Patterns (What NOT to Do)

1. **Never create a script without a test** — forge-test-guard.sh will catch it
2. **Never modify code without checking --impact** — you'll break dependencies
3. **Never skip the CR loop** — no merge without explicit [approve]
4. **Never combine multiple issues in one PR** — one issue = one PR
5. **Never remove REQ tags without updating SPEC** — pre-commit hook will block
6. **Never wire a system without a test** — we learned this the hard way (6 unwired systems)
7. **Never create a hook without an integration test** — untested hooks fail silently
8. **Never commit without conventional format** — commit-msg hook will block

---

## Verification: Is This Protocol Being Followed?

Run these checks:

```bash
# Are all scripts tested?
bash scripts/forge-test-guard.sh

# Are all skill/agent references valid?
tests/bats/bin/bats tests/bash/unit/commands-validation.bats

# Are there suspect REQs?
bash scripts/forge-enforce.sh check-suspect

# Is the triangle synced?
bash scripts/forge-triangle.sh check

# What's the impact of my changes?
python3 scripts/forge-registry.py --impact <file>
```
