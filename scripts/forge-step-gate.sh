#!/bin/bash
# forge-step-gate.sh — Blocks progress if reviewer hasn't run or trace is missing
# Called by Stop hook to enforce per-step quality gates
# Exit codes: 0=pass, 1=blocked (reviewer missing), 2=blocked (trace missing), 3=error

set -euo pipefail

USAGE="Usage: forge-step-gate.sh check [project-dir]
       forge-step-gate.sh --help

Checks that the current step has:
  1. @reviewer entry in activity log (reviewer ran)
  2. Trace files saved (input.md + output.md + meta.md)

Exit codes:
  0 = all checks pass
  1 = reviewer not run for current step
  2 = trace files missing for current step
  3 = error (missing state file, etc.)"

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "$USAGE"
    exit 0
fi

CMD="${1:-}"
DIR="${2:-$PWD}"

if [ "$CMD" != "check" ]; then
    echo "$USAGE" >&2
    exit 3
fi

STATE_FILE="$DIR/docs/forge-state.json"
ACTIVITY_LOG="$DIR/docs/.builder-activity.log"

if [ ! -f "$STATE_FILE" ]; then
    # No state file = not a forge project, skip silently
    exit 0
fi

# Get current step from state
CURRENT_STEP=$(python3 -c "
import json
with open('$STATE_FILE') as f:
    d = json.load(f)
print(d.get('current_step', 0))
" 2>/dev/null || echo 0)

if [ "$CURRENT_STEP" -eq 0 ]; then
    exit 0
fi

# Get last completed action from activity log
if [ ! -f "$ACTIVITY_LOG" ]; then
    if [ "$CURRENT_STEP" -gt 0 ]; then
        echo "[FORGE] BLOCKED: Activity log missing but step $CURRENT_STEP is active. Cannot verify reviewer ran."
        exit 1
    fi
    exit 0
fi

# Check 1: Did @reviewer run after the last agent/skill?
# Exclude AGENT reviewer, gate, checkpoint from "work" actions
LAST_AGENT=$(grep -nE "AGENT |SKILL " "$ACTIVITY_LOG" 2>/dev/null | grep -vE "AGENT reviewer|SKILL gate|SKILL checkpoint|SKILL cr" | tail -1 | cut -d: -f1 || true)
LAST_REVIEWER=$(grep -n "AGENT reviewer" "$ACTIVITY_LOG" 2>/dev/null | tail -1 | cut -d: -f1 || true)

if [ -n "$LAST_AGENT" ] && [ -n "$LAST_REVIEWER" ]; then
    if [ "$LAST_REVIEWER" -lt "$LAST_AGENT" ]; then
        echo "[FORGE] BLOCKED: @reviewer has NOT run after the last agent/skill execution."
        echo "[FORGE] Last agent/skill at log line $LAST_AGENT, last reviewer at line $LAST_REVIEWER."
        echo "[FORGE] Spawn @reviewer to rate the output before proceeding."
        exit 1
    fi
elif [ -n "$LAST_AGENT" ] && [ -z "$LAST_REVIEWER" ]; then
    echo "[FORGE] BLOCKED: @reviewer has NEVER run in this session."
    echo "[FORGE] Spawn @reviewer to rate the last agent/skill output before proceeding."
    exit 1
fi

# Check 2: Are trace files saved for the current step?
TRACE_DIR="$DIR/docs/forge-trace"
if [ -d "$TRACE_DIR" ]; then
    # Find trace folder matching current step number
    STEP_TRACE=$(find "$TRACE_DIR" -maxdepth 1 -name "${CURRENT_STEP}*" -o -name "0${CURRENT_STEP}*" -o -name "00${CURRENT_STEP}*" 2>/dev/null | head -1 || true)
    if [ -z "$STEP_TRACE" ]; then
        # Also check by latest folder as fallback
        STEP_TRACE=$(ls -1d "$TRACE_DIR"/*/ 2>/dev/null | tail -1 || true)
    fi
    if [ -n "$STEP_TRACE" ] && [ -d "$STEP_TRACE" ]; then
        MISSING=0
        for FILE in input.md output.md meta.md; do
            if [ ! -f "$STEP_TRACE/$FILE" ]; then
                echo "[FORGE] BLOCKED: Trace file missing: $STEP_TRACE/$FILE"
                MISSING=$((MISSING + 1))
            fi
        done
        if [ "$MISSING" -gt 0 ]; then
            echo "[FORGE] Save all 3 trace files before proceeding."
            exit 2
        fi
    fi
fi

exit 0
