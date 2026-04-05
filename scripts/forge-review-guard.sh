#!/bin/bash
# Forge Review Guard — tracks review completion and blocks gate/PR without it
#
# Usage:
#   forge-review-guard.sh mark-reviewed <phase>   — mark review done for phase
#   forge-review-guard.sh check-reviewed <phase>   — check if review done (exit 2 if not)
#   forge-review-guard.sh check-for-gate            — block gate if review not done
#   forge-review-guard.sh check-for-pr              — block PR/push if review not done
#   forge-review-guard.sh reset                     — clear all review markers
#   forge-review-guard.sh status                    — show all review markers

set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$PWD}"
REVIEW_DIR="$PROJECT_ROOT/docs/.forge-reviews"
STATE_FILE="$PROJECT_ROOT/docs/forge-state.json"

mkdir -p "$REVIEW_DIR"

get_current_phase() {
    if [ -f "$STATE_FILE" ]; then
        python3 -c "import json; print(json.load(open('$STATE_FILE')).get('current_phase', '?'))" 2>/dev/null || echo "?"
    else
        echo "?"
    fi
}

cmd_mark_reviewed() {
    local phase="${1:-$(get_current_phase)}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat > "$REVIEW_DIR/phase-${phase}-reviewed.json" << EOF
{
  "phase": $phase,
  "reviewed_at": "$timestamp",
  "reviewer": "inline-review",
  "status": "REVIEWED"
}
EOF

    echo "[FORGE-REVIEW] Phase $phase marked as REVIEWED at $timestamp"
}

cmd_check_reviewed() {
    local phase="${1:-$(get_current_phase)}"
    local marker="$REVIEW_DIR/phase-${phase}-reviewed.json"

    if [ -f "$marker" ]; then
        local ts
        ts=$(python3 -c "import json; print(json.load(open('$marker')).get('reviewed_at','?'))" 2>/dev/null)
        echo "[FORGE-REVIEW] Phase $phase: REVIEWED (at $ts)"
        return 0
    else
        echo "[FORGE-REVIEW] BLOCKED: Phase $phase NOT reviewed. Run /review first." >&2
        exit 2
    fi
}

cmd_check_for_gate() {
    local phase
    phase=$(get_current_phase)
    local marker="$REVIEW_DIR/phase-${phase}-reviewed.json"

    if [ -f "$marker" ]; then
        return 0
    else
        echo "[FORGE-BLOCKED] Cannot run /gate — /review has NOT run for Phase $phase." >&2
        echo "[FORGE-BLOCKED] Architectural flow: code → /review → fix → commit → /gate → PR" >&2
        echo "[FORGE-BLOCKED] Run /review NOW, then retry /gate." >&2
        exit 2
    fi
}

cmd_check_for_pr() {
    local phase
    phase=$(get_current_phase)
    local marker="$REVIEW_DIR/phase-${phase}-reviewed.json"

    if [ -f "$marker" ]; then
        return 0
    else
        echo "[FORGE-BLOCKED] Cannot create PR or push — /review has NOT run for Phase $phase." >&2
        echo "[FORGE-BLOCKED] Flow: code → /review → fix → commit → /gate → PR" >&2
        echo "[FORGE-BLOCKED] Run /review first." >&2
        exit 2
    fi
}

cmd_reset() {
    rm -f "$REVIEW_DIR"/phase-*-reviewed.json
    echo "[FORGE-REVIEW] All review markers cleared"
}

cmd_status() {
    echo "=== Review Status ==="
    local found=0
    for f in "$REVIEW_DIR"/phase-*-reviewed.json; do
        [ -f "$f" ] || continue
        found=1
        local phase ts
        phase=$(python3 -c "import json; print(json.load(open('$f')).get('phase','?'))" 2>/dev/null)
        ts=$(python3 -c "import json; print(json.load(open('$f')).get('reviewed_at','?'))" 2>/dev/null)
        echo "  Phase $phase: REVIEWED at $ts"
    done
    if [ "$found" -eq 0 ]; then
        echo "  No phases reviewed yet"
    fi
}

case "${1:-help}" in
    mark-reviewed)    shift; cmd_mark_reviewed "$@" ;;
    check-reviewed)   shift; cmd_check_reviewed "$@" ;;
    check-for-gate)   cmd_check_for_gate ;;
    check-for-pr)     cmd_check_for_pr ;;
    reset)            cmd_reset ;;
    status)           cmd_status ;;
    *)
        echo "Usage: forge-review-guard.sh <command>"
        echo "  mark-reviewed [phase]   Mark review done"
        echo "  check-reviewed [phase]  Check if reviewed (BLOCKS if not)"
        echo "  check-for-gate          Block /gate without review"
        echo "  check-for-pr            Block PR/push without review"
        echo "  reset                   Clear markers"
        echo "  status                  Show all markers"
        ;;
esac
