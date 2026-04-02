# /prune — Remove Bad Rules

Scan the playbook and remove strategies that cause more harm than help.

## Input
No arguments. Reads playbook/strategies.md automatically.

## Execution

1. Read playbook/strategies.md
2. Scan every entry for pruning criteria:

   **Remove if:**
   - harmful > helpful (net negative — rule causes more problems than it solves)
   - helpful = 0 AND harmful > 0 (never helped, only hurt)
   - helpful = 0 AND harmful = 0 AND age > 5 builds (never validated — dead weight)

3. For each entry to prune:
   a) Move to `playbook/archived.md` with reason:
   ```
   [PRUNED 2026-04-02] [str-002] helpful=3 harmful=5 :: use global CSRF parameter
   Reason: harmful > helpful — caused API errors in 2 projects
   ```
   b) Remove from playbook/strategies.md

4. Report:
   ```
   Pruned: {N} strategies removed
   - [str-xxx]: {reason}
   - [str-xxx]: {reason}
   Remaining: {N} active strategies
   Archived: playbook/archived.md
   ```

## Rules

- NEVER delete without archiving — pruned entries go to archived.md
- NEVER prune strategies with helpful > harmful (they're working)
- Always include the reason for pruning
- Run /prune after every /retro to keep the playbook clean
