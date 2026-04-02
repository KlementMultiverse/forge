# /forge — Master Command

Run the entire SDLC autonomously from a single sentence.

## Input
$ARGUMENTS — A one-sentence description of what to build (e.g., "a clinic management portal for medical practices")

## Execution

<system-reminder>
This is the master orchestration command. It runs ALL stages sequentially.

REVIEWER RULE: Every agent output gets reviewed. NEVER skip the review step.
- Phase 0-2: @spec-panel or domain expert reviews
- Phase 3: Per-agent domain judge rates 1-5
- Phase 3 end: /review (inline staff-engineer review)
- All gates: CodeRabbit reviews PR → 0 suggestions required

CODERABBIT RULE: Every /gate creates a PR and waits for CodeRabbit.
- 0 suggestions → PASS → proceed to next phase
- >0 suggestions → FIX each one → push → wait for re-review → repeat until 0
- NEVER skip CodeRabbit. NEVER proceed with open suggestions.

The ONLY times to stop and ask the user:
1. /feasibility → "Recommended stack: [X]. Confirm?"
2. Credentials needed (AWS keys, API keys, etc.)
3. After 3 reflexion failures on a single issue
4. /challenge verdict is RETHINK
Everything else runs autonomously.
</system-reminder>

---

### Phase 0: Genesis

1. Run `/discover` with the user's sentence
   - Output: docs/discovery-report.md
   - **REVIEW:** PM validates — problem real? users identified? market exists?
   - If review fails → reiterate @deep-research-agent with feedback (max 3)
   - Git: commit

2. Run `/requirements` on the discovery report
   - Output: docs/requirements.md with [REQ-xxx] tags
   - **REVIEW:** @business-panel-experts validates viability + completeness
   - If review fails → reiterate @requirements-analyst with feedback (max 3)
   - Git: commit

3. Run `/feasibility` on the requirements
   - Output: docs/feasibility.md with tech stack + risk matrix
   - **REVIEW:** @system-architect validates stack fits requirements
   - **ASK USER:** "Recommended: [stack]. Use this or pick your own?"
   - Check: agents exist for stack? If not → @agent-factory creates them
   - Git: commit

4. Run `/generate-spec` synthesizing discovery + requirements + feasibility
   - Output: SPEC.md with all [REQ-xxx] tags
   - **REVIEW:** @requirements-analyst verifies ALL requirements captured
   - If any REQ missing → fix SPEC.md → re-review
   - Git: commit

5. Run `/challenge` on the generated SPEC.md
   - 6 forcing questions: demand, status quo, specificity, scope, observation, future-fit
   - **REVIEW:** PM validates challenge verdict
   - Verdict PROCEED → continue
   - Verdict REFINE → update SPEC.md → re-run /challenge
   - Verdict RETHINK → STOP and ask user
   - Git: commit

6. Run `/bootstrap` to scaffold the project
   - Creates: project folder, CLAUDE.md, git init, dependencies, docker
   - **REVIEW:** PM verifies scaffold matches SPEC (correct apps, correct structure)
   - Push to GitHub
   - Git: commit "init: scaffold project"

7. Run @code-archaeologist on the scaffolded project
   - Baseline assessment: architecture, quality metrics, file structure
   - Identifies any scaffold issues before building on top

8. Run `/sc:index-repo` on the new project
   - Generates PROJECT_INDEX.md (94% token savings per session)
   - Every future agent loads the index instead of scanning the full repo

8. Run `/sc:load` to initialize session context
   - Load project state, playbook, rules into session memory

9. **GATE:** `/gate phase-0`
   - Git push → create PR
   - CodeRabbit reviews → fix ALL suggestions → 0 remaining → PASS
   - If CodeRabbit has suggestions → fix → push → wait for re-review → repeat

---

### Phase 1: Specify

8. Run `/specify` on SPEC.md
   - Output: docs/proposals/01-project.md + GitHub Issues
   - **REVIEW:** @spec-panel (multi-expert) validates:
     - All [REQ-xxx] covered in proposal?
     - Acceptance criteria (Given/When/Then) for each requirement?
     - Implementation phases ordered correctly?
     - Risk table complete?
   - If review fails → reiterate with feedback (max 3)

9. Run `/checkpoint` — evaluate proposal quality (PASS/FAIL score)
   - If score <80% → fix issues → re-checkpoint

10. **GATE:** `/gate stage-1`
    - Git push → create PR
    - CodeRabbit reviews → fix ALL suggestions → 0 remaining → PASS

---

### Phase 2: Architect

11. Run @api-architect to design API contracts
    - Technology-agnostic contracts for EVERY endpoint
    - Exact request/response/error shapes
    - Both backend and frontend agents read SAME contract
    - Output: docs/api-contracts.md

12. Run `/design-doc` on the proposal + API contracts
    - Output: docs/design-doc.md (10 sections, Section 4 references api-contracts.md)
    - **REVIEW:** @spec-panel validates:
      - Every design decision has "Will implement X because" + alternatives?
      - API contracts in Section 4 have exact request/response/error shapes?
      - Testing strategy has 15+ scenarios?
      - Security section covers auth, tenant isolation, data protection?
    - If review fails → reiterate with feedback (max 3)

12. Run `/plan-tasks` on the design doc
    - Output: docs/implementation-plan.md + GitHub Issues
    - **REVIEW:** PM validates:
      - Dependency order correct? (infra → models → APIs → frontend)
      - Each task links to [REQ-xxx]?
      - Parallel markers [P] correct? (no write conflicts)
    - If review fails → fix task ordering → re-review

13. Run `/sc:estimate` on each phase
    - Effort estimation with confidence intervals
    - Risk assessment per phase

14. Run `/sc:workflow` to validate the implementation plan
    - Structured workflow validation from PRD
    - Confirms dependency ordering and parallel safety

15. Run `/checkpoint` for each output

16. **GATE:** `/gate stage-2`
    - Git push → create PR
    - CodeRabbit reviews → fix ALL suggestions → 0 remaining → PASS

---

### Phase 3: Implement

15. For each GitHub Issue (in dependency order):

    **THE FORGE CELL (9 steps — NEVER skip any):**

    Every agent runs through `/run-with-checkpoint` (auto-checkpointing wrapper).

    Step 0: TASK DECOMPOSITION
      - Run `/sc:spawn` to break complex issues into subtasks
      - Simple issues → skip to Step 1
      - Complex issues → decompose → execute subtasks sequentially

    Step 1: CONTEXT LOAD
      - @context-loader-agent fetches library docs via context7
      - Load relevant rules/ files for this domain

    Step 2: AGENT RESEARCH (self-discovery)
      - Selected agent reads: spec [REQ-xxx], existing tests, current code, rules/, API contracts
      - Agent identifies: gaps, missing requirements, improvements
      - If new insight → flag for spec/test/code update

    Step 3: TDD IMPLEMENTATION
      - a) Write TEST first → references [REQ-xxx]
      - b) Run test → MUST FAIL (proves test is real)
      - c) Write CODE → references [REQ-xxx]
      - d) Run test → MUST PASS
      - e) Run ALL tests → no regressions

    Step 4: BUILD + QUALITY
      - Run `/sc:build` to compile/package if needed
      - black + ruff (auto via PostToolUse hook)
      - Run full test suite
      - If FAIL:
        → Run `/sc:troubleshoot` first (diagnosis before fix)
        → Then `/investigate` (root cause analysis)
        → @root-cause-analyst reflexion (max 3 attempts)
        → Still fails? → STOP and ask user

    Step 5: SYNC CHECK (bidirectional)
      - New code? → verify [REQ-xxx] exists in SPEC
      - New behavior? → verify test exists
      - Gap found? → add to SPEC + add test + update code
      - Run traceability: 100% coverage, 0 orphans, 0 drift

    Step 6: PER-AGENT JUDGE (NEVER SKIP)
      - **REVIEW:** Domain-specific judge evaluates:
        - □ Output matches spec [REQ-xxx]?
        - □ Tests pass?
        - □ Architecture rules followed?
        - □ API contracts match design doc Section 4?
        - □ All documents in sync?
        - □ No security issues?
      - Rate quality: 1-5
      - Write mini-retrospective to: docs/retros/{agent}-{issue}.md
      - Rating ≥4 → ACCEPT
      - Rating <4 → REITERATE same agent with judge's feedback (max 3)
      - Judge's retro feeds into next attempt (agent reads what went wrong)

    Step 7: COMMIT + LEARN
      - Git commit with conventional message
      - GitHub: close issue
      - /checkpoint: evaluate agent output quality
      - If agent discovered improvements → /learn (save to playbook)

16. After each implementation phase (group of related issues):
    - **REVIEW:** Run `/review` on the phase's code
      - Staff-engineer level: completeness, security, architecture, edge cases
      - Fix-First mode: auto-fix obvious issues, flag design decisions
      - If issues found → fix → re-run /review until CLEAN
    - If frontend phase:
      - **REVIEW:** Run `/design-audit` on templates
        - 7-pass audit: info architecture, states, journey, consistency, responsive, accessibility, edge cases
        - Score must be ≥50/70. If <50 → fix → re-audit
      - **CRITIC:** Run `/critic` on frontend pages
        - Maps ALL elements (buttons, forms, links, events)
        - Tests ALL paths (depth + breadth + edge cases)
        - Auto-creates GitHub Issues for EVERY failure
        - Each issue triggers internal fix cycle:
          spec updated → test updated → code fixed → re-verified
        - Repeats until 0 new failures
    - Git push → create PR
    - **GATE:** `/gate phase-N`
      - CodeRabbit reviews → fix ALL suggestions → 0 remaining → PASS

---

### Phase 4: Validate

17. Run `/sc:analyze` on full codebase
    - Quality, security, performance, architecture analysis
    - Identifies issues before formal audit

18. Run `/audit-patterns full` → must be >90%
    - If <90% → fix top 5 failures → re-audit

19. Run `/sc:test --coverage`
    - Gate tests (blocking): unit + integration → must all pass
    - Periodic tests (non-blocking): E2E, performance

19. Run traceability check (scripts/traceability.sh)
    - 100% coverage, 0 orphans, 0 drift
    - If gaps → fix → re-check

20. Run `/security-scan` → OWASP Top 10 + STRIDE threat model
    - **REVIEW:** @security-engineer validates findings
    - CRITICAL/HIGH findings → must fix before proceeding
    - MEDIUM/LOW → create GitHub Issues for future fix

21. Run `/design-audit` on all frontend pages (if UI exists)
    - **REVIEW:** Score must be ≥50/70
    - If <50 → fix top issues → re-audit

22. Run `/critic` — FULL autonomous frontend test (if UI exists)
    - Maps entire frontend graph (pages, elements, paths)
    - Tests every depth path, breadth path, and edge case
    - Auto-creates issues for failures → internal fix cycle
    - Repeats until 0 new failures found
    - All fixes sync spec↔test↔code via [REQ-xxx]

23. **GATE:** `/gate stage-4`
    - Git push → create PR
    - CodeRabbit reviews → fix ALL suggestions → 0 remaining → PASS

---

### Phase 5: Review + Learn

23. Run `/sc:cleanup` on full codebase
    - Remove dead code, unused imports, optimize structure
    - @refactoring-expert handles complex refactors

24. Run `/sc:improve` on critical paths
    - Systematic quality + performance improvements
    - Auto-fix style issues, flag architectural changes for approval

25. Run `/retro` → retrospective
    - What went well (with evidence)
    - What could improve (with root cause + fix)
    - Lessons learned → feed to playbook

26. Run `/sc:reflect` to validate task completion
    - Verify all requirements met, all issues closed

27. Run `/sc:document` to generate/update project docs
    - API documentation, component docs, user guides

28. **REVIEW:** @playbook-curator delta-updates playbook
    - Increment helpful/harmful counters based on retro outcomes
    - Add new strategies from lessons learned
    - NEVER rewrite — only delta-update

25. Run `/prune` → remove rules where harmful > helpful
    - Pruned entries → playbook/archived.md (never deleted)

26. Run `/evolve` → cluster strong strategies (helpful >3) into reusable skills
    - 3+ related strategies → new skill file in rules/ or agents/stacks/

27. Run `/autoresearch` on agent prompts that scored <100% in checkpoints
    - Self-improving prompt loop — mutates prompts to fix identified issues
    - Makes next build better

28. Run `/sc:save` to persist session context
    - Cross-session memory via playbook + checkpoint files
    - Next session starts informed

29. **GATE:** `/gate stage-5`
    - Git push → create FINAL PR
    - CodeRabbit reviews → fix ALL suggestions → 0 remaining
    - MERGE → project complete

---

### Phase 6: Iterate

28. Collect feedback → new GitHub Issues
29. Bug found → /investigate FIRST (root cause before fix)
30. Fix → grows system:
    - New code → spec updated [REQ-xxx]
    - New test added
    - Playbook updated (/learn)
31. Loop to Phase 1 (new features) or Phase 3 Step 15 (fixes)

---

### Output

```
Forge complete.
- Project: [name]
- Location: [path]
- Tests: [count] passing
- Coverage: [%]
- Traceability: [%] REQ coverage
- Audit: [%] pattern pass rate
- Security: [risk level]
- Design: [score]/70
- PR: #[number] merged
- Reviews passed: [count] (per-agent judges + /review + CodeRabbit)
- Playbook: [count] strategies learned
```
