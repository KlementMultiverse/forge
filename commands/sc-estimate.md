# /sc:estimate — Effort Estimation

Estimate effort for each issue/task based on the design document.

## What It Does

1. Read design-doc.md and issue files
2. For each issue: estimate complexity (S/M/L/XL)
3. Factor in: model changes, API endpoints, test count, integration points
4. Order by dependency (blocked issues last)
5. Total estimate for the build

## Output
- Effort table: issue | complexity | estimate | dependencies
- Critical path identification
