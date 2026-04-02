# /forge — Master Command

Run the entire SDLC autonomously from a single sentence.

## Input
$ARGUMENTS — A one-sentence description of what to build (e.g., "a clinic management portal for medical practices")

## Execution

<system-reminder>
This is the master orchestration command. It runs ALL stages sequentially.
The ONLY times to stop and ask the user:
1. /feasibility → "Recommended stack: [X]. Confirm?"
2. Credentials needed (AWS keys, API keys, etc.)
3. After 3 reflexion failures on a single issue
Everything else runs autonomously.
</system-reminder>

### Phase 0: Genesis

1. Run `/discover` with the user's sentence
   - Output: docs/discovery-report.md
   - Judge: PM validates problem is real, users identified

2. Run `/requirements` on the discovery report
   - Output: docs/requirements.md with [REQ-xxx] tags
   - Judge: @business-panel-experts validates viability

3. Run `/feasibility` on the requirements
   - Output: docs/feasibility.md with tech stack + risk matrix
   - **ASK USER:** "Recommended: [stack]. Use this or pick your own?"
   - Check: agents exist for stack? If not → @agent-factory creates them

4. Run `/generate-spec` synthesizing discovery + requirements + feasibility
   - Output: SPEC.md with all [REQ-xxx] tags
   - Judge: @requirements-analyst verifies completeness

5. Run `/bootstrap` to scaffold the project
   - Creates: project folder, CLAUDE.md, git init, dependencies, docker
   - Push to GitHub

6. Run `/gate phase-0`

### Phase 1: Specify

7. Run `/specify` on SPEC.md
   - Output: docs/proposals/01-project.md + GitHub Issues
   - Judge: @spec-panel reviews

8. Run `/checkpoint`
9. Run `/gate stage-1`

### Phase 2: Architect

10. Run `/design-doc` on the proposal
    - Output: docs/design-doc.md (10 sections including API contracts)
    - Judge: @spec-panel reviews

11. Run `/plan-tasks` on the design doc
    - Output: docs/implementation-plan.md + GitHub Issues
    - Judge: PM verifies dependency order

12. Run `/checkpoint` for each
13. Run `/gate stage-2`

### Phase 3: Implement

14. For each GitHub Issue (in dependency order):
    - Run the Forge Cell:
      1. @context-loader-agent → fetch library docs
      2. Select domain agent → research + TDD + quality + sync
      3. Per-agent judge → rate 1-5, write mini-retro
      4. Accept (≥4) or reiterate (max 3)
      5. Git commit → close issue → /checkpoint
      6. /learn if new insight discovered

15. After each phase: git push → PR → /gate phase-N

### Phase 4: Validate

16. Run `/audit-patterns full` → must be >90%
17. Run `/sc:test --coverage`
18. Run traceability check → 100% coverage, 0 orphans, 0 drift
19. Run @security-engineer audit
20. Run `/gate stage-4`

### Phase 5: Review

21. Run `/retro` → retrospective
22. Delta-update playbook (helpful/harmful counters)
23. Run `/prune` → remove bad rules
24. Run `/evolve` → cluster strategies into skills
25. Run `/gate stage-5` → final PR → merge

### Output

```
Forge complete.
- Project: [name]
- Location: [path]
- Tests: [count] passing
- Coverage: [%]
- Traceability: [%] REQ coverage
- Audit: [%] pattern pass rate
- PR: #[number] merged
- Playbook: [count] strategies learned
```
