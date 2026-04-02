# /careful — Extra Caution Mode

Activate heightened safety for risky operations. Every destructive action requires explicit confirmation.

## Input
$ARGUMENTS — optional scope (e.g., "database", "production", "all")

## Behavior When Active

<system-reminder>
CAREFUL MODE IS ACTIVE. Before ANY of these actions, describe what you're about to do and wait for explicit "yes":
- Deleting files or directories
- Dropping/truncating database tables
- Git force push, reset --hard, branch -D
- Modifying production config
- Removing dependencies
- Overwriting uncommitted changes
- Sending external requests (API calls, webhooks)
- Modifying CI/CD pipelines

Do NOT proceed on assumed consent. Each action needs its own "yes".
</system-reminder>

## How To Deactivate

Send: "careful mode off" or start a new session.

## Difference From /freeze and /guard

- `/careful` — asks before destructive ops (human confirms each)
- `/freeze` — blocks ALL writes (read-only exploration)
- `/guard` — blocks destructive ops automatically (no confirmation, just blocked)
