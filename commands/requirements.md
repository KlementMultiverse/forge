# /requirements — Extract Requirements

Extract structured requirements from discovery research.

## Input
docs/discovery-report.md — the discovery report from /discover

## Execution

Spawn `@requirements-analyst` with:
  TASK: Extract all requirements from the discovery report
  - Functional requirements (what the system DOES) → tagged [REQ-001], [REQ-002], etc.
  - Non-functional requirements (how WELL it does it) → performance, security, scalability
  - User stories (As a [user], I want [goal] so that [benefit])
  - Acceptance criteria (Given/When/Then for each requirement)

Then spawn `/sc:brainstorm` for Socratic discovery:
  - What edge cases are we missing?
  - What could go wrong?
  - What assumptions are we making?

## Output

Save to `docs/requirements.md`:
```markdown
# Requirements: [Project Name]

## Functional Requirements
- [REQ-001] [Description]
- [REQ-002] [Description]
...

## Non-Functional Requirements
- [NFR-001] [Performance/Security/Scalability requirement]
...

## User Stories
- As a [user], I want [goal] so that [benefit] → [REQ-xxx]
...

## Acceptance Criteria
Given [precondition]
When [action]
Then [result]
→ verifies [REQ-xxx]
```

## Judge
@business-panel-experts validates: Are requirements viable? Complete? Prioritized?
