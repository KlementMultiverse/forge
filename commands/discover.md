# /discover — Problem Space Research

Research the problem space before writing any specification.

## Input
$ARGUMENTS — A description of what to build

## Execution

Spawn `@deep-research-agent` with:
  TASK: Research this problem space thoroughly
  - Who has this problem? (specific user types)
  - How do they solve it today? (existing solutions, competitors)
  - What's wrong with current solutions? (pain points, gaps)
  - What would success look like? (outcomes, not features)
  - Market size and viability

## Output

Save to `docs/discovery-report.md`:
```markdown
# Discovery Report: [Project Idea]

## Problem Statement
[What is broken/missing/expensive]

## Target Users
[Specific user types with their context]

## Current Solutions
[How they solve it today + what's wrong]

## Opportunity
[What success looks like]

## Key Insights
[Non-obvious findings from research]
```

## Judge
PM validates: Is the problem real? Are users specific? Is there a gap?
