# Universal Agent Execution Loop

<system-reminder>
This loop is NON-OPTIONAL. Every agent spawn MUST follow it. Hooks report handoff status after each agent (advisory); PM MUST act on MISSING/INCOMPLETE reports.
Discovery notes = single source of truth. Autoresearch is BOUNDED — NEVER invents new requirements.
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
   Spawn agent with prepared prompt → receive output

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

11. RATE: spawn @reviewer (1-5, must be >= 4)
    Rating uses a SEPARATE retry budget (max 2 re-reviews)
    If < 4 after 2 re-reviews: escalate to user

12. PROCEED to next step with verified output
```

## Bounded Autoresearch Rules
- Discovery notes are the SINGLE SOURCE OF TRUTH
- NEVER invent requirements not in discovery notes
- NEVER override user decisions from S2
- NEVER add compliance user explicitly rejected
- Enhance = ADD more context from discovery notes, NEVER remove existing prompt
- The ONLY way new info enters is via user answering a RAISED QUESTION
