# Agentic Loop Pattern

How agents execute tasks in a recoverable, bounded loop.

## The Loop

```
while not done and attempts < MAX_RETRIES:
    1. Read current state (spec, tests, code)
    2. Plan what to do (research gaps, identify approach)
    3. Execute (write test → write code → run tests)
    4. Evaluate (did it work? did tests pass?)
    5. If success → done
    6. If failure → investigate root cause → adjust approach → retry
```

## Key Properties

### Bounded (Never Infinite)
- Max 3 retries per issue
- After 2 failed corrections → STOP and ask user
- Recovery counters track attempts, not exponential backoff

### Stateful (Carries Context)
- Each iteration knows what was tried before
- Failed approaches are recorded (don't repeat them)
- Judge's mini-retro feeds back into next attempt

### Recoverable (Can Roll Back)
- Git checkpoint at every transition
- Can restore to any previous state
- Failed attempt doesn't corrupt good state

## Anti-Patterns

- "Got an error, let me retry" → WRONG (investigate first)
- while(true) with no exit condition → WRONG (always bound)
- Same approach retried 5 times → WRONG (max 3, then escalate)
- Error ignored because "it works anyway" → WRONG (investigate every warning)

## The Reflexion Variant

When a test fails:
1. Agent reads the error message
2. Agent explains WHY it failed (not just what failed)
3. Agent proposes a DIFFERENT approach (not the same one)
4. Agent implements the new approach
5. If still fails → escalate (don't loop forever)
