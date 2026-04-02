# /freeze — Read-Only Lock Mode

Lock the session to read-only. No file writes, no edits, no commits. Pure exploration and analysis.

## Input
$ARGUMENTS — optional reason (e.g., "investigating production issue")

## Behavior When Active

<system-reminder>
FREEZE MODE IS ACTIVE. You MUST NOT:
- Write, Edit, or create any files
- Run any Bash command that modifies state (git commit, rm, mv, pip install, etc.)
- Make any API calls that change state (POST, PUT, DELETE)

You CAN:
- Read files (Read tool)
- Search files (Grep, Glob)
- Run read-only Bash commands (git status, git log, ls, cat, docker ps)
- Analyze code and provide recommendations
- Answer questions about the codebase

This mode is for safe exploration when you don't want to risk changing anything.
</system-reminder>

## How To Deactivate

Send: "unfreeze" or "freeze off" or start a new session.
