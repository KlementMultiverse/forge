# /evolve — Cluster Strategies Into Skills

Scan the playbook for clusters of related high-scoring strategies and convert them into reusable skill files.

## Input
No arguments. Reads playbook/strategies.md automatically.

## Execution

1. Read playbook/strategies.md
2. Find clusters: 3+ strategies about the same domain or pattern
3. For each cluster with average helpful score > 3:

   a) Create a skill file:
   ```markdown
   # {Skill Name}

   Evolved from playbook strategies: {list of [str-xxx] IDs}

   ## Rules
   - {strategy 1 text}
   - {strategy 2 text}
   - {strategy 3 text}

   ## When To Apply
   {describe the situations where these rules matter}

   ## Evidence
   Combined helpful score: {sum}
   Combined harmful score: {sum}
   ```

   b) Save to appropriate location:
   - Domain-specific → `rules/{domain}.md` (append)
   - Stack-specific → `agents/stacks/{stack}/` (new skill file)
   - Universal → `rules/universal.md` (append)

   c) Tag original strategies in playbook:
   ```
   [str-001] helpful=5 harmful=0 :: validate tenant schema [evolved → django-tenancy-skill]
   ```

4. Report: "Evolved {N} clusters into {N} skills"

## Rules

- Only evolve strategies with helpful > 3 (proven useful)
- Never delete original strategies — tag them as evolved
- Never create a skill from < 3 related strategies (not enough evidence)
- Skill files must include the source strategy IDs for traceability
