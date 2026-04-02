# CLAUDE.md — [PROJECT NAME]

[One-line project description.]

## SDLC Flow

```text
STAGE 0: PLAN
  1. Read SPEC.md completely
  2. Create implementation plan table
  3. Show plan to user → proceed to Stage 1

STAGE 1: SPECIFY
  /specify SPEC.md → /checkpoint → /gate stage-1

STAGE 2: ARCHITECT
  /design-doc → /plan-tasks → /checkpoint each → /gate stage-2

STAGE 3: IMPLEMENT (per issue, per phase)
  For each issue:
    1. @context-loader-agent fetches library docs
    2. Select agent by domain (see Agent Selection below)
    3. Agent runs Forge Cell (research → TDD → quality → sync → judge → commit)
    4. /checkpoint after each agent
    5. Format + lint + test
    6. If fail → /investigate → reflexion max 3
    7. Green → commit → close issue
  /gate after each phase

STAGE 4: VALIDATE
  /audit-patterns full (>90%) → /sc:test --coverage → /gate stage-4

STAGE 5: REVIEW
  /retro → update playbook → /prune → /gate stage-5

STAGE 6: ITERATE
  Feedback → new issues → loop to Stage 1 or 3
```

## Agent Selection

| Domain | Agent | context7 Libs |
|--------|-------|---------------|
| [domain-1] | @[agent-name] | [libraries] |
| [domain-2] | @[agent-name] | [libraries] |
| [domain-3] | @[agent-name] | [libraries] |
| Frontend | /sc:implement | — |

## Tech Stack

| Layer | Technology | Notes |
|---|---|---|
| Runtime | [e.g., Python 3.12] | via [package manager] |
| Framework | [e.g., Django 5.x] | [notes] |
| API | [e.g., Django Ninja] | [notes] |
| Database | [e.g., PostgreSQL 15+] | [notes] |
| Cache | [e.g., Redis 7] | [notes] |
| Storage | [e.g., AWS S3] | [notes] |
| Frontend | [e.g., Django templates + vanilla JS] | [notes] |

## Architecture Rules

1. [Rule — e.g., "Django Ninja for ALL API routes — NEVER import rest_framework"]
2. [Rule]
3. [Rule]
4. [Rule]
5. [Rule]

## Lessons Learned

[Initially empty. Grows with every /retro. Format:]
- [N]. [Lesson description — e.g., "CSRF handled per-auth-class, not globally"]

## Post-Implementation Rule

After ANY code generation:
1. Format + lint
2. Run tests
Do NOT defer testing to a separate step.
