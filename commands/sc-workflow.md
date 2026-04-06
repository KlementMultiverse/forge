# /sc:workflow — Dependency Ordering

Determine the correct execution order for issues based on dependencies.

## What It Does

1. Read all issue files from docs/issues/
2. Extract dependencies (which issues block which)
3. Topological sort for execution order
4. Identify critical path
5. Flag circular dependencies

## Output
- Ordered issue list: execute in this sequence
- Dependency graph (text or mermaid)
- Critical path highlighted
