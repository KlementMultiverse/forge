# /codex — Multi-Model Cross-Review

Get a second opinion from a different AI model. Catches blind spots that a single model misses.

## Input
$ARGUMENTS — scope (e.g., "apps/workflows/api.py", "last commit", "security")

## Why This Matters

One model reviewing its own code = confirmation bias. Two models reviewing = blind spots caught.

## Execution

### Mode 1: Code Review (default)
```
1. Collect the code to review (files, diff, or scope)
2. Send to secondary model (via API or CLI):
   - codex-cli: `codex review [files]`
   - openai: `openai api chat -m gpt-4o -p "Review this code for bugs, security, performance"`
   - gemini: `gemini review [files]`
3. Compare findings with primary Claude review
4. Overlap analysis: issues found by BOTH models = high confidence
5. Unique findings: issues found by only ONE model = investigate
```

### Mode 2: Adversarial Challenge
```
1. Primary model writes the code
2. Secondary model tries to BREAK it:
   - Edge cases the primary missed
   - Security vulnerabilities
   - Race conditions
   - Input validation gaps
3. Any break → create issue → fix cycle
```

### Mode 3: Architecture Consultation
```
1. Present the design decision to secondary model
2. Ask: "What's wrong with this approach?"
3. Compare perspectives
4. Synthesize: strongest approach from both
```

## Output

```markdown
## Cross-Model Review: [scope]

### Primary Model Findings: [count]
### Secondary Model Findings: [count]

### Overlap (high confidence — both models agree)
- [issue] → MUST fix

### Primary Only (investigate)
- [issue] → verify if real

### Secondary Only (investigate)
- [issue] → verify if real

### Verdict: [ALIGNED / DIVERGENT]
```

## When To Run
- Phase 3: after complex implementations (security, auth, data isolation)
- Phase 4: as part of validation alongside /security-scan
- On demand: when confidence in approach is low
