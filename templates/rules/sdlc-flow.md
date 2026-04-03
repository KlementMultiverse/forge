---
description: SDLC flow for Forge-managed projects. Loaded when PM orchestrator runs.
paths: ["docs/**", "SPEC.md", "CLAUDE.md"]
---

# SDLC Flow

{{SDLC_FLOW_CONTENT}}

The default stages below are customized during /setup. Replace {{SDLC_FLOW_CONTENT}} with the filled version.

```text
STAGE 0: PLAN
  1. Read SPEC.md completely
  2. Create implementation plan table (phase, domain, agent, dependencies)
  3. Show plan to user with checkboxes → proceed to Stage 1

STAGE 1: SPECIFY
  /specify SPEC.md → /checkpoint → /gate stage-1

STAGE 2: ARCHITECT
  /design-doc → /plan-tasks → /checkpoint each → /gate stage-2

STAGE 3: IMPLEMENT (per issue, per phase)
  For each issue:
    1. @context-loader-agent fetches library docs via context7
    2. Select agent by domain (see .claude/rules/agent-routing.md)
    3. Agent runs Forge Cell:
       a. Research (read spec, tests, code, rules, API contracts)
       b. TDD (test first → FAIL → code → PASS → all tests PASS)
       c. Quality (lint + format + full test suite)
       d. Sync check (spec <-> test <-> code, [REQ-xxx] traceability)
       e. Per-agent judge rates 1-5 (accept >= 4, reiterate < 4, max 3)
       f. Commit → close issue → /checkpoint → /learn
    4. If fail → /investigate → @root-cause-analyst reflexion (max 3)
    5. Green → commit → close issue
  /gate after each phase

STAGE 4: VALIDATE
  /audit-patterns full (>90%) → /sc:test --coverage → /security-scan → /gate stage-4

STAGE 5: REVIEW
  /retro → update playbook → /prune → /evolve → /gate stage-5 (final PR → merge)

STAGE 6: ITERATE
  Feedback → new issues → loop to Stage 1 (features) or Stage 3 (fixes)
```

## PM Agent Rules

1. NEVER write application code — only delegate and evaluate
2. Every agent run goes through /run-with-checkpoint
3. Every stage boundary goes through /gate
4. Max 2 agents in parallel, only for independent tasks
5. Sequential for dependent tasks (models before endpoints, shared before tenant)
6. If credentials needed (AWS, OpenAI) → STOP and ask the user
7. If agent output fails checkpoint → fix agent prompt, re-run (max 3)
8. Track progress via GitHub Issues (gh issue edit labels)
