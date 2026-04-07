#!/bin/bash
# forge-handoff-targets.sh — Maps current step/skill to expected output artifact(s)
# Used by PostToolUse hooks to check the RIGHT files, not just CLAUDE.md/SPEC.md
# Exit codes: 0=targets found, 1=no targets (skip check)

set -euo pipefail

DIR="${1:-$PWD}"
STATE_FILE="$DIR/docs/forge-state.json"
ACTIVITY_LOG="$DIR/docs/.builder-activity.log"

if [ ! -f "$STATE_FILE" ] && [ ! -f "$ACTIVITY_LOG" ]; then
    exit 1
fi

# Get last action from activity log
LAST_ACTION=""
if [ -f "$ACTIVITY_LOG" ]; then
    LAST_ACTION=$(tail -1 "$ACTIVITY_LOG" 2>/dev/null || echo "")
fi

# Get current step from state
CURRENT_STEP=0
if [ -f "$STATE_FILE" ]; then
    CURRENT_STEP=$(python3 -c "
import json
with open('$STATE_FILE') as f:
    d = json.load(f)
print(d.get('current_step', 0))
" 2>/dev/null || echo 0)
fi

# Map skill/agent to expected output targets
# Phase A steps
if echo "$LAST_ACTION" | grep -qi "SKILL discover"; then
    echo "$DIR/docs/forge-trace/001-discover/output.md"
elif echo "$LAST_ACTION" | grep -qi "SKILL requirements"; then
    echo "$DIR/SPEC.md"
elif echo "$LAST_ACTION" | grep -qi "SKILL feasibility"; then
    echo "$DIR/docs/forge-trace/003-feasibility/output.md"
elif echo "$LAST_ACTION" | grep -qi "SKILL generate-spec"; then
    echo "$DIR/SPEC.md"
elif echo "$LAST_ACTION" | grep -qi "SKILL challenge"; then
    echo "$DIR/docs/forge-trace/005-challenge/output.md"
elif echo "$LAST_ACTION" | grep -qi "SKILL bootstrap"; then
    echo "$DIR/CLAUDE.md"
    echo "$DIR/SPEC.md"
elif echo "$LAST_ACTION" | grep -qi "AGENT system-architect"; then
    echo "$DIR/CLAUDE.md"
elif echo "$LAST_ACTION" | grep -qi "AGENT requirements-analyst"; then
    echo "$DIR/SPEC.md"
elif echo "$LAST_ACTION" | grep -qi "AGENT devops-architect"; then
    echo "$DIR/Dockerfile"
    echo "$DIR/docker-compose.yml"
elif echo "$LAST_ACTION" | grep -qi "AGENT backend-architect"; then
    # Find the latest trace output
    LATEST=$(ls -1d "$DIR/docs/forge-trace"/*/ 2>/dev/null | tail -1)
    if [ -n "$LATEST" ] && [ -f "$LATEST/output.md" ]; then
        echo "$LATEST/output.md"
    fi
elif echo "$LAST_ACTION" | grep -qi "AGENT security-engineer"; then
    LATEST=$(ls -1d "$DIR/docs/forge-trace"/*/ 2>/dev/null | tail -1)
    if [ -n "$LATEST" ] && [ -f "$LATEST/output.md" ]; then
        echo "$LATEST/output.md"
    fi
elif echo "$LAST_ACTION" | grep -qi "AGENT reviewer"; then
    # Reviewer output doesn't need handoff check — it IS the check
    exit 1
elif echo "$LAST_ACTION" | grep -qi "SKILL gate"; then
    # Gate doesn't produce artifacts — it validates them
    exit 1
elif echo "$LAST_ACTION" | grep -qi "SKILL checkpoint"; then
    # Checkpoint doesn't produce artifacts
    exit 1
else
    # Default: check CLAUDE.md and SPEC.md if they exist
    [ -f "$DIR/CLAUDE.md" ] && echo "$DIR/CLAUDE.md"
    [ -f "$DIR/SPEC.md" ] && echo "$DIR/SPEC.md"
fi

exit 0
