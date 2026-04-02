# /feasibility — Tech Stack Selection

Analyze requirements and recommend the best production-grade tech stack.

## Input
docs/requirements.md — the requirements from /requirements

## Execution

Spawn `@system-architect` with:
  TASK: Recommend the best production-grade stack for these requirements
  - Analyze each requirement → what technology fits best?
  - Consider: multi-tenancy, real-time, storage, AI, scale
  - Recommend specific versions, not just names
  - Explain WHY each choice (trade-offs, alternatives)

Spawn `@security-engineer` with:
  TASK: Review the recommended stack for security
  - Authentication/authorization approach
  - Data isolation strategy
  - Known vulnerabilities in recommended versions
  - Compliance considerations

**ASK USER:** "Recommended stack: [table]. Use this or pick your own?"

**Check:** Do agents exist for this stack in agents/stacks/{stack}/?
  - YES → load them
  - NO → spawn @agent-factory to create them

## Output

Save to `docs/feasibility.md`:
```markdown
# Feasibility: [Project Name]

## Recommended Stack
| Layer | Technology | Version | Why |
|-------|-----------|---------|-----|
...

## Risk Matrix
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
...

## Stack Agents
- Loaded from: agents/stacks/{stack}/
- Or: created by @agent-factory

## Security Assessment
[Security engineer's review]
```
