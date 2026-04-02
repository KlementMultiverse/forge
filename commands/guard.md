# /guard — Block Destructive Operations

Automatically block all destructive operations without asking. Unlike /careful (which asks), /guard silently prevents and suggests safe alternatives.

## Input
$ARGUMENTS — optional scope (e.g., "git", "files", "all")

## Behavior When Active

<system-reminder>
GUARD MODE IS ACTIVE. The following are BLOCKED (not asked — blocked):
- `rm -rf`, `rm -r` on directories
- `git reset --hard`, `git push --force`, `git checkout .`, `git clean -f`
- `DROP TABLE`, `TRUNCATE`, `DELETE FROM` without WHERE
- `docker compose down -v` (destroys volumes)
- Overwriting files without reading them first
- Any command matching patterns in hooks/hooks.json PreToolUse deny list

When blocked, suggest the SAFE alternative:
- Instead of `rm -rf dir/` → "Move to trash: mv dir/ /tmp/dir-backup-$(date +%s)"
- Instead of `git reset --hard` → "Create backup branch: git branch backup-$(date +%s)"
- Instead of `DROP TABLE` → "Rename: ALTER TABLE x RENAME TO x_deprecated"
</system-reminder>

## How To Deactivate

Send: "guard off" or start a new session.
