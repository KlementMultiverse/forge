# /learn — Save Insight to Playbook

Save a discovered insight or lesson to the self-improving playbook.

## Input
$ARGUMENTS — the insight to save (e.g., "strip_tags on all LLM output before storage")

## Execution

1. Read current playbook/strategies.md
2. Check for duplicates (is this insight already captured?)
3. If duplicate → increment helpful counter on existing entry
4. If new → add entry with initial counters:

```markdown
[str-{next_id}] helpful=0 harmful=0 :: {insight text}
```

5. Categorize:
   - STRATEGIES & INSIGHTS → general best practices
   - COMMON MISTAKES TO AVOID → error patterns
   - DOMAIN-SPECIFIC → stack-related rules

## When To Call

- After an agent discovers a gap during research (Step 2 of Forge Cell)
- After /investigate identifies a prevention measure
- After /retro extracts lessons learned
- Anytime a non-obvious pattern is validated

## Related Commands

- `/prune` — removes entries where harmful > helpful
- `/evolve` — clusters strong entries into reusable skills
- `/retro` — bulk-updates counters based on build outcomes
