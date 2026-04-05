# /specify — Feature Specification with Proposal

Generate a structured feature proposal from a SPEC file or feature description. Embeds Steve's AI-First SDLC feature proposal template. Creates GitHub Issues for each task.

## Input
$ARGUMENTS — path to SPEC file or feature description text

## Phase 0: Context Loading (MANDATORY)

<system-reminder>
Do NOT skip this phase. Read everything before writing anything.
</system-reminder>

1. Read CLAUDE.md → extract: project identity, tech stack, architecture rules, API contracts
2. Read the SPEC or feature description at $ARGUMENTS
3. If a `docs/proposals/` directory exists, read existing proposals to avoid duplication
4. Identify the next proposal number (NN) by counting existing proposals

## Phase 1: Requirements Discovery

Spawn `@requirements-analyst` agent with:
  TASK: Analyze the spec at $ARGUMENTS and extract structured requirements
  CONTEXT: CLAUDE.md + the spec file
  EXPECTED OUTPUT: List of functional requirements, non-functional requirements, user stories, ambiguities found

Then spawn `@business-panel-experts` agent with:
  TASK: Validate the product from business/strategy perspective
  CONTEXT: The requirements from requirements-analyst
  EXPECTED OUTPUT: Business risks, market considerations, prioritization suggestions

## Phase 2: Fill Proposal Template

<system-reminder>
Every proposal MUST have Given/When/Then acceptance criteria.
Every proposal MUST flag assumptions with [NEEDS CLARIFICATION].
Every proposal MUST have a risks table with Probability × Impact × Mitigation.
</system-reminder>

Using the output from Phase 1, fill this template EXACTLY:

```markdown
# Feature Proposal: [Feature Name]

**Proposal Number:** [NN]
**Status:** Draft
**Author:** Claude Code + [user]
**Created:** [YYYY-MM-DD]
**Target Branch:** `feature/[branch-name]`

---

## Problem Statement

[What is currently broken or missing? Who is affected? What happens if we don't fix it?]

[NEEDS CLARIFICATION]: [Flag any assumptions or ambiguities here]

## User Stories

- As a [user type], I want [goal] so that [benefit]
- As a [user type], I want [goal] so that [benefit]

## Proposed Solution

### High-Level Approach

[Non-technical summary — what the user will see and experience]

### Technical Approach

[Architecture changes, new components, dependencies, API changes.
Reference CLAUDE.md architecture rules. Reference SPEC.md sections.]

### Alternatives Considered

1. **[Alternative 1]**: [Description. Pros. Cons. Why not chosen.]
2. **[Alternative 2]**: [Description. Pros. Cons. Why not chosen.]

---

## Implementation Plan

### Phase 1: [Foundation]
- [ ] [P] Task 1 (can run in parallel)
- [ ] [P] Task 2 (can run in parallel)
- [ ] Task 3 (depends on above)

### Phase 2: [Core Implementation]
- [ ] Task 1
- [ ] Task 2

### Phase 3: [Testing & Documentation]
- [ ] Write tests
- [ ] Update documentation
- [ ] Run pattern audit

**Dependencies:** [Libraries, services, AWS resources needed]

[P] = can run in parallel
[NEEDS CLARIFICATION]: [Flag uncertain implementation details]

---

## Acceptance Criteria

Given [precondition]
When [action]
Then [expected result]

Given [precondition]
When [action]
Then [expected result]

[Minimum 5 acceptance criteria. Cover happy path + error cases + edge cases.]

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | Low/Med/High | Low/Med/High | [Strategy] |
| [Risk 2] | Low/Med/High | Low/Med/High | [Strategy] |

## Open Questions

- [ ] [Question that needs answering before implementation]
- [ ] [Question that needs answering before implementation]

## Security & Privacy

[Authentication/authorization changes. Data exposure risks. Input validation needs.
Tenant isolation implications. S3 access controls. Compliance requirements.
Write "N/A" only if genuinely not applicable — for this project it almost always applies.]

---

**Retrospective:** `docs/retrospectives/[NN]-[feature-name].md` (link after implementation)
```

## Phase 3: Save & Create Issues

1. Save the filled proposal to `docs/proposals/[NN]-[feature-name].md`
2. Check if a GitHub remote is configured: `git remote get-url origin 2>/dev/null`
3. If GitHub remote exists, for each task in the Implementation Plan, create a GitHub Issue:
   ```
   gh issue create \
     --title "[Phase N] Task description" \
     --body "From proposal [NN]. Acceptance criteria: [relevant criteria]" \
     --label "phase-3-implement,ready,domain-[relevant],[priority]"
   ```
4. If no GitHub remote is configured, save issues as markdown files instead:
   ```
   mkdir -p docs/issues/
   # For each task, create docs/issues/[NN]-[task-slug].md with title, body, and labels
   ```
   Log: "No GitHub remote configured — issues saved to docs/issues/ as markdown files"
5. Report: proposal saved, [N] issues created (GitHub or local)

## Phase 4: Handoff

Return this handoff to the PM agent:

```
## Handoff: specify → design-doc
### Task Completed: Feature proposal [NN] written
### Files Changed: docs/proposals/[NN]-[feature-name].md
### GitHub Issues Created: [count] issues with labels
### Context for Next Agent: Proposal is ready for architecture design via /design-doc
### Blockers: [any NEEDS CLARIFICATION items that must be resolved first]
```
