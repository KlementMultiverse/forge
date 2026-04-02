# /challenge — Pre-Spec Validation (Forcing Questions)

Challenge the spec BEFORE building. Runs diagnostic questions that expose weak assumptions, missing demand signals, and scope creep.

## Input
$ARGUMENTS — path to SPEC.md or project description

## Execution

<system-reminder>
This command runs BEFORE Stage 1. Its purpose is to kill bad ideas early and strengthen good ones. Be ruthless but constructive.
</system-reminder>

Ask these 6 forcing questions (inspired by YC's office hours):

### 1. Demand Reality
"Who is desperately trying to solve this problem RIGHT NOW? Not 'would be nice' — who is in PAIN?"
- If the answer is vague → flag: spec may be solution-looking-for-a-problem

### 2. Status Quo
"How do they solve it today? What specific tool/process do they use?"
- If no current solution exists → flag: may not be a real problem
- If current solution is "good enough" → flag: what's the 10x improvement?

### 3. Desperate Specificity
"Can you name ONE specific person who would pay for this?"
- If only "companies" or "users" → flag: too abstract

### 4. Narrowest Wedge
"What is the SMALLEST version that delivers value? Not MVP — the narrowest possible wedge."
- If the spec has 10+ models and 20+ endpoints → flag: likely over-scoped for v1

### 5. Observation Test
"What have you OBSERVED (not assumed) about how users work?"
- If all requirements are assumed → flag: needs user research first

### 6. Future-Fit
"In 2 years, will this architecture still make sense? What would break?"
- If the answer is "everything" → flag: architecture is too rigid

## Output

```markdown
# Spec Challenge Report

## Verdict: [PROCEED / REFINE / RETHINK]

## Question Results
1. Demand: [STRONG / WEAK / MISSING] — [finding]
2. Status Quo: [CLEAR / VAGUE / UNKNOWN] — [finding]
3. Specificity: [SPECIFIC / ABSTRACT] — [finding]
4. Scope: [FOCUSED / OVER-SCOPED] — [finding]
5. Observation: [OBSERVED / ASSUMED] — [finding]
6. Future-Fit: [RESILIENT / BRITTLE] — [finding]

## Recommendations
- [What to change in the spec before proceeding]
```

## When To Use
- BEFORE Stage 1 (/specify) — challenge the spec first
- When scope feels too large
- When you're unsure if the problem is real
