# Universal Agent Execution Loop

<system-reminder>
This loop is NON-OPTIONAL. Every step MUST follow it — whether agent spawn OR slash command.
Hooks report handoff status after each step (advisory); PM MUST act on MISSING/INCOMPLETE reports.
Discovery notes = single source of truth. Autoresearch is BOUNDED — NEVER invents new requirements.
Step 11 (FLEX CHECKPOINT) is a DEFINITIVE STEP — always runs, has full authority within its correction loop, only exits when clean.
</system-reminder>

```text
1. PREPARE:
   PM reads input artifact (discovery notes / SPEC / previous step output)
   PM reads agent-specific context (stack registry, templates, prior traces)
   PM prepares prompt with ALL accumulated context

2. DEFINE HANDOFF METRIC (per-step — see each STEP in phase files):
   MUST PROPAGATE: items from input that MUST appear in output
   MUST NOT APPEAR: items from EXCLUDED / rejected items

3. ATTEMPT 1:
   Execute step (spawn agent OR run command) → receive output

4. MEASURE (BOUNDED by discovery notes — NEVER invent):
   FOR EACH item in MUST PROPAGATE:
     Present in output? → COVERED
     Missing?           → MISSING
     Partial?           → INCOMPLETE
   FOR EACH item in output not traceable to input:
     → INVENTED (flag for removal — agent hallucinated this)
   SCORE = COVERED / (COVERED + MISSING + INCOMPLETE + INVENTED)
   Note: INVENTED items reduce the score — hallucinations are failures too

5. IF SCORE < 100%:
   AUTORESEARCH (BOUNDED enhancement — ADD context, NEVER remove):
     - List MISSING items with exact quotes from discovery notes
     - List INCOMPLETE items with what needs more detail
     - List INVENTED items to remove
     - ENHANCE prompt: keep ALL of previous prompt + append:
       "YOU MISSED: [exact items from discovery notes]"
       "REMOVE: [invented items not in discovery notes]"
       "INCOMPLETE: [items needing more detail]"
   → ATTEMPT 2 with enhanced prompt → MEASURE again

6. IF STILL < 100%: further enhance → ATTEMPT 3 → MEASURE

7. IF ALL 3 ATTEMPTS < 100%:
   ESCALATE to user: "After 3 attempts, best score is {SCORE}%. Missing: [list]."
   User decides: proceed with best OR update discovery notes → re-run

8. IF CRITICAL GAP FOUND (agent discovers something missing from input):
   RAISE QUESTION to user: "I found a gap: {gap}. Should I add {X}?"
   User answers → update discovery notes → re-run with updated input
   This is the ONLY way new info enters (via user, not agent invention)

9. PICK BEST output (highest SCORE from 3 attempts)

10. REVERSE ENGINEER + CROSS-VERIFY (bidirectional):
    FORWARD:  Does previous step output data appear in current output?
    BACKWARD: Does current output data trace back to previous step?
    Mismatch → flag and fix or raise question to user

11. FLEX CHECKPOINT (ALWAYS runs — definitive step, not optional):
    Scan output for FLEX_SIGNAL section.
    IF no FLEX_SIGNAL → pass through (step is clean)
    IF FLEX_SIGNAL found:
      Parse: TYPE, TARGET, STEP, WHAT, WHY, PROPOSED, SEVERITY
      IF SEVERITY = INFO → log to trace, pass through
      IF SEVERITY = ADVISORY → log to trace, flag for next /review
      IF SEVERITY = BLOCKING → ENTER CORRECTION LOOP:
        ┌─ GATE 1: CR reviews proposal (post to PR/issue, get feedback)
        │   CR rejects → log reason, skip signal
        ├─ GATE 2: Spawn correct agent to fix TARGET:
        │   CLAUDE.md        → @system-architect
        │   SPEC.md          → @requirements-analyst
        │   Design doc       → @backend-architect
        │   agent-routing.md → @system-architect
        │   Scaffold/infra   → @devops-architect
        │   Security rules   → @security-engineer
        │   New agent needed → @agent-factory
        │   Tests            → @quality-engineer
        │   Discovery notes  → PM + USER confirmation (highest impact)
        ├─ GATE 3: Universal loop on the fix (attempt → measure → max 3)
        ├─ GATE 4: @reviewer rates fix (>= 4, SEPARATE from signaling agent)
        ├─ GATE 5: Impact check
        │   Run: forge-registry.py --impact {TARGET}
        │   CLAUDE.md changed → re-validate downstream artifacts
        │   SPEC.md changed → re-check traceability
        │   Design doc changed → re-check implementation
        ├─ Re-scan: did fix produce NEW signals?
        │   YES → loop again (max 5 iterations per signal)
        │   NO  → EXIT correction loop
        └─ Max limits: 5 per signal, 10 per step, 30 per phase
           Exceeded → ESCALATE to user with full context
    EXIT with all corrections applied.

12. RATE: spawn @reviewer (1-5, must be >= 4)
    Rating uses a SEPARATE retry budget (max 2 re-reviews)
    If < 4 after 2 re-reviews: escalate to user

13. PROCEED to next step with verified output
```

## FLEX_SIGNAL Format

Every agent MUST include this if they discover an issue with a previous artifact:

```text
## FLEX_SIGNAL
TYPE: AMEND_RULES | UPDATE_SPEC | FIX_DESIGN | FIX_ROUTING | FIX_SCAFFOLD |
      ADD_SECURITY | SPAWN_AGENT | UPDATE_TESTS | DEEP_REVIEW
TARGET: [file path — CLAUDE.md, SPEC.md, docs/design-doc.md, etc.]
STEP: [which step created it — S3, N0, Step 14, etc.]
WHAT: [exact problem description]
WHY: [evidence — quote conflicting parts]
PROPOSED: [what should change — propose, never decide]
SEVERITY: INFO | ADVISORY | BLOCKING
```

## Decision Authority (manifesto: agents propose, never decide)

| Decision | Proposes | Reviews | Approves | Implements |
|---|---|---|---|---|
| Amend CLAUDE.md | Agent (signal) | CR (plan) | @reviewer (>= 4) | @system-architect |
| Update SPEC.md | Agent (signal) | CR (plan) | @reviewer (>= 4) | @requirements-analyst |
| Fix design doc | Agent (signal) | CR (plan) | @reviewer (>= 4) | @backend-architect |
| Spawn new agent | Agent (signal) | CR (plan) | @reviewer (>= 4) | @agent-factory |
| Add security rule | Agent (signal) | CR (plan) | @reviewer (>= 4) | @security-engineer |
| Update discovery | Agent signals | PM asks user | USER decides | PM updates |

## Bounded Autoresearch Rules
- Discovery notes are the SINGLE SOURCE OF TRUTH
- NEVER invent requirements not in discovery notes
- NEVER override user decisions from S2
- NEVER add compliance user explicitly rejected
- Enhance = ADD more context from discovery notes, NEVER remove existing prompt
- The ONLY way new info enters is via user answering a RAISED QUESTION
- FLEX_SIGNAL corrections go through 5 gates — no single entity decides

## Safety Limits
- Max 5 correction iterations per signal
- Max 10 flex checkpoints per step
- Max 30 per phase
- Same file amended max 3 times (prevent oscillation)
- Discovery notes loop-back requires USER confirmation
- After any max exceeded → ESCALATE to user
