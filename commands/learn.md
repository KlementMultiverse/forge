# /learn — Save Insight to Playbook

Save a discovered insight or lesson to the self-improving playbook.

## Input
$ARGUMENTS — the insight to save (e.g., "strip_tags on all LLM output before storage")

## Execution

1. Read the insight from $ARGUMENTS
2. Read .forge/playbook/strategies.md (or playbook/strategies.md)
3. Determine next [str-xxx] ID:
   - Grep for existing `[str-` entries
   - Find highest number, increment by 1
   - If no entries exist, start at [str-001]
4. Check for duplicates (grep for similar text in strategies.md)
   - If duplicate found → increment helpful counter on existing entry instead of adding new
5. If new → append entry with initial counters:

```markdown
[str-{next_id}] helpful=0 harmful=0 :: {insight text}
```

6. Categorize and place under the correct section:
   - STRATEGIES & INSIGHTS → general best practices
   - COMMON MISTAKES TO AVOID → error patterns
   - DOMAIN-SPECIFIC → stack-related rules
7. Write the updated file back to disk
8. Report: "Saved [str-{id}] to playbook"

## When To Call

- After an agent discovers a gap during research (Step 2 of Forge Cell)
- After /investigate identifies a prevention measure
- After /retro extracts lessons learned
- Anytime a non-obvious pattern is validated

## Related Commands

- `/prune` — removes entries where harmful > helpful
- `/evolve` — clusters strong entries into reusable skills
- `/retro` — bulk-updates counters based on build outcomes
