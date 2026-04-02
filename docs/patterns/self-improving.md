# Self-Improving Playbook Pattern

The system gets smarter with every build through scored strategies.

## How It Works

Every rule/strategy has two counters:
```
[str-001] helpful=5 harmful=0 :: validate tenant schema before query
```

- **helpful** increments when the rule prevented a bug or guided correct output
- **harmful** increments when the rule caused a wrong approach or confusion

## Lifecycle

```
New insight discovered
    ↓
/learn adds: [str-xxx] helpful=0 harmful=0 :: insight text
    ↓
Over multiple builds, counters update based on outcomes
    ↓
/prune removes: harmful > helpful (net negative rules)
    ↓
/evolve clusters: 3+ related high-scoring strategies → reusable skill
    ↓
System has fewer bad rules, stronger good rules, new skills
```

## Delta Updates (Not Rewrites)

During /retro, the playbook curator:
1. Reads the retrospective
2. For each lesson: finds matching strategy → increments counter
3. New lesson → adds new entry
4. NEVER rewrites the entire playbook — preserves history

## Pruning Criteria

Remove when:
- harmful > helpful (net negative)
- helpful=0 AND harmful>0 (never helped, only hurt)
- helpful=0 AND harmful=0 AND age > 5 builds (never validated)

Pruned entries archived (not deleted) with reason.
