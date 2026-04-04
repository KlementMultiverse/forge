#!/bin/bash
# Observer approval script — called by observer after reviewing all phase artifacts
# Determines current phase, checks if all reviews pass, writes explicit approval
#
# Usage:
#   forge-observer-approve.sh check <project_path>   — check if ready to approve
#   forge-observer-approve.sh approve <project_path>  — write approval (only if all pass)
#   forge-observer-approve.sh reject <project_path> <reason> — write rejection

set -uo pipefail

PROJ="${2:-$PWD}"
REVIEWS_LOG="$PROJ/docs/.observer-reviews.log"
STATE_FILE="$PROJ/docs/forge-state.json"

get_phase() {
    python3 -c "
import json, sys
try:
    d = json.load(open('$STATE_FILE'))
    s = d.get('current_step', 0)
    if s <= 8: print(0)
    elif s <= 11: print(1)
    elif s <= 19: print(2)
    elif s <= 39: print(3)
    elif s <= 46: print(4)
    elif s <= 56: print(5)
    else: print(6)
except: print(-1)
" 2>/dev/null
}

cmd_check() {
    local phase
    phase=$(get_phase)

    if [ "$phase" = "-1" ]; then
        echo "[OBSERVER] Cannot read forge-state.json at $PROJ"
        exit 1
    fi

    echo "[OBSERVER] Current phase: $phase"

    # Check reviews log
    if [ ! -f "$REVIEWS_LOG" ]; then
        echo "[OBSERVER] No reviews log — nothing reviewed yet"
        echo "[OBSERVER] VERDICT: NOT READY (no reviews)"
        exit 1
    fi

    # Count NEEDS_FIX
    local fixes
    fixes=$(grep -c "NEEDS_FIX" "$REVIEWS_LOG" 2>/dev/null || true)
    fixes="${fixes//[^0-9]/}"
    [ -z "$fixes" ] && fixes=0

    if [ "$fixes" -gt 0 ]; then
        echo "[OBSERVER] Found $fixes NEEDS_FIX items:"
        grep "NEEDS_FIX" "$REVIEWS_LOG" | tail -5
        echo "[OBSERVER] VERDICT: NOT READY (fix issues first)"
        exit 1
    fi

    # Count PASS reviews
    local passes
    passes=$(grep -c "PASS" "$REVIEWS_LOG" 2>/dev/null || true)
    passes="${passes//[^0-9]/}"
    [ -z "$passes" ] && passes=0

    # Check if already approved
    if grep -q "PHASE-${phase}-APPROVED" "$REVIEWS_LOG" 2>/dev/null; then
        echo "[OBSERVER] Phase $phase already approved"
        echo "[OBSERVER] VERDICT: ALREADY APPROVED"
        exit 0
    fi

    echo "[OBSERVER] $passes PASS reviews, 0 NEEDS_FIX"
    echo "[OBSERVER] VERDICT: READY TO APPROVE"
    echo "[OBSERVER] Run: forge-observer-approve.sh approve $PROJ"
    exit 0
}

cmd_approve() {
    local phase
    phase=$(get_phase)
    local ts
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Double-check no NEEDS_FIX
    local fixes
    fixes=$(grep -c "NEEDS_FIX" "$REVIEWS_LOG" 2>/dev/null || true)
    fixes="${fixes//[^0-9]/}"
    [ -z "$fixes" ] && fixes=0

    if [ "$fixes" -gt 0 ]; then
        echo "[OBSERVER] CANNOT APPROVE — $fixes NEEDS_FIX items remain"
        exit 1
    fi

    # Write explicit approval
    echo "$ts | PHASE-${phase}-APPROVED | All Phase $phase artifacts reviewed and approved" >> "$REVIEWS_LOG"
    echo "[OBSERVER] Phase $phase APPROVED at $ts"
    echo "[OBSERVER] Builder will detect approval and proceed to next phase"
}

cmd_reject() {
    local phase
    phase=$(get_phase)
    local reason="${3:-no reason given}"
    local ts
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    echo "$ts | PHASE-${phase}-REJECTED | $reason" >> "$REVIEWS_LOG"
    echo "[OBSERVER] Phase $phase REJECTED: $reason"
    echo "[OBSERVER] Builder will stay blocked until issues are fixed"
}

case "${1:-check}" in
    check)   cmd_check ;;
    approve) cmd_approve ;;
    reject)  shift; cmd_reject "$@" ;;
    *)       echo "Usage: forge-observer-approve.sh check|approve|reject <project_path> [reason]" ;;
esac
