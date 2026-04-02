# Self-Executing Agent Pattern

Agents don't just write code — they RUN it, CHECK errors, FIX them, and VERIFY. Learned from Claude Code's internal architecture.

## The Loop

```
WRITE → RUN → CHECK → FIX → VERIFY → DONE
  ↑                      │
  └──────────────────────┘ (max 3 iterations)
```

## How It Works

### Step 1: WRITE code
Agent writes implementation code (test first, then implementation).

### Step 2: RUN it
Agent uses Bash tool to execute:
```bash
# Run tests
uv run python manage.py test apps.workflows

# Run linting
ruff check apps/workflows/ --fix

# Run the specific function
uv run python -c "from apps.workflows.models import Task; print(Task.VALID_TRANSITIONS)"
```

### Step 3: CHECK errors (semantic classification)
Don't just check exit code. CLASSIFY what failed:

| Command | Exit Code | Classification |
|---------|-----------|---------------|
| `pytest` | 1 | TEST_FAILURE — which tests? what assertions? |
| `black` | 1 | FORMAT_ERROR — which files? what violations? |
| `ruff` | 1 | LINT_ERROR — which rules? which files:lines? |
| `python manage.py migrate` | 1 | MIGRATION_ERROR — missing field? dependency? |
| `python -c "import X"` | 1 | IMPORT_ERROR — missing package? wrong name? |
| `curl localhost:8000/api/` | 7 | CONNECTION_ERROR — server not running? wrong port? |

### Step 4: FIX based on error type
Each error type has a specific fix strategy:

```
TEST_FAILURE:
  1. Read the failing test output
  2. Identify: is the test wrong or the code wrong?
  3. Fix the correct one
  4. Re-run JUST the failing test

IMPORT_ERROR:
  1. Check if package is installed (uv pip list)
  2. If not → uv add [package]
  3. If yes → check import path (typo? wrong module?)

MIGRATION_ERROR:
  1. Read the error message
  2. Check model changes vs existing migrations
  3. Generate new migration → apply
```

### Step 5: VERIFY (run EVERYTHING)
After fixing, don't just re-run the failing test. Run ALL tests:
```bash
# Full test suite — no regressions
uv run python manage.py test

# Full lint — no new issues
black . && ruff check .

# Specific verification
uv run python -c "from apps.workflows.models import Task; assert hasattr(Task, 'transition_to')"
```

### Step 6: DONE or RETRY
- All pass → proceed to next step in Forge Cell
- Still failing → retry (max 3 iterations total)
- After 3 → /investigate → @root-cause-analyst → escalate if needed

## What Agents Should Run

### After Writing Models
```bash
uv run python manage.py makemigrations
uv run python manage.py migrate_schemas --shared  # or --tenant
uv run python -c "from apps.{app}.models import {Model}; print({Model}._meta.fields)"
```

### After Writing APIs
```bash
uv run python manage.py test apps.{app}.tests
# Quick smoke test:
uv run python -c "
from django.test import RequestFactory
from apps.{app}.api import api
print('API routes:', [r.path for r in api.urls])
"
```

### After Writing Templates
```bash
# Check template syntax
uv run python -c "
from django.template.loader import get_template
t = get_template('{template_name}.html')
print('Template loaded OK:', t.origin)
"
```

### After Writing Services
```bash
uv run python manage.py test apps.{app}.tests -k "test_{function_name}"
```

## Error Feedback Format

When an error occurs, format it so the model can react:

```
ERROR REPORT:
  Command: uv run python manage.py test apps.workflows
  Exit Code: 1
  Type: TEST_FAILURE

  Failing Tests:
    test_state_transition (apps.workflows.tests.TaskTest)
      AssertionError: 'assigned' != 'in_progress'
      File: apps/workflows/tests.py:45

  Passing Tests: 12/13

  Suggested Fix:
    Check VALID_TRANSITIONS dict — 'assigned' may not allow transition to target state
```

## Integration With Forge Cell

The self-executing pattern is embedded in Forge Cell Steps 3-4:

```
Step 3: TDD IMPLEMENTATION
  a) Write TEST → RUN test → must FAIL (proves test is real)
  b) Write CODE → RUN test → must PASS
  c) RUN ALL tests → no regressions
  d) If any RUN fails → classify error → FIX → re-RUN (max 3)

Step 4: BUILD + QUALITY
  RUN: /sc:build (compile if needed)
  RUN: black + ruff (auto via PostToolUse hook)
  RUN: full test suite
  CHECK: classify any errors semantically
  FIX: based on error type
  If 3 failures → /sc:troubleshoot → /investigate → escalate
```

## Rules
- ALWAYS run code after writing it — never assume it works
- ALWAYS classify errors semantically — "exit code 1" is useless
- ALWAYS fix based on error type — don't guess
- ALWAYS verify with FULL test suite — not just the changed test
- Max 3 self-fix iterations — then escalate (never infinite loop)
- NEVER start a dev server — only run commands that complete
