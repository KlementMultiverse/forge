# /sc:improve — Apply Improvements

Apply code improvements identified during validation phase.

## What It Does

1. Read findings from /sc:analyze, /audit-patterns, /security-scan
2. Prioritize: security fixes > correctness > performance > style
3. Apply each improvement
4. Run tests after each change
5. Verify no regressions

## Rules
- Every improvement must reference the finding that motivated it
- Run full test suite after each change
- Never batch unrelated improvements
