# /sc:analyze — Code Quality Analysis

Analyze the codebase for quality issues, complexity, and maintainability.

## What It Does

1. Run linting (ruff check)
2. Check file sizes (>300 lines = split needed)
3. Check function complexity
4. Check for TODO/FIXME/HACK comments (should be issues)
5. Check import organization
6. Report code health score

## Output
- Quality report with scores per module
- Action items for improvements
