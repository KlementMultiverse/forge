#!/bin/bash
# Forge Phase Gate — checks observer + CodeRabbit before allowing phase transition
# Called by Stop hook after each gate. Returns:
#   0 = CLEAR (both approved, proceed)
#   1 = WAIT (still reviewing)
#   2 = NEEDS_FIX (issues found)
#
# Usage: forge-phase-gate.sh check

set -uo pipefail

D="${PROJECT_ROOT:-$PWD}"
REVIEWS_LOG="$D/docs/.observer-reviews.log"
REVIEWING="$D/docs/.observer-reviewing"
GATE_CLEAR="$D/docs/.phase-gate-clear"

cmd_check() {
    local blocked=0
    local reasons=""

    # ─── CHECK 1: Observer reviewing in progress? ───
    if [ -f "$REVIEWING" ]; then
        local age
        age=$(python3 -c "import os,time; print(int(time.time()-os.path.getmtime('$REVIEWING')))" 2>/dev/null || echo 0)
        # If older than 10 minutes, observer might have crashed — clear it
        if [ "$age" -gt 600 ]; then
            echo "[PHASE-GATE] Observer review stale (${age}s). Clearing."
            rm -f "$REVIEWING"
        else
            echo "[PHASE-GATE] WAIT: Observer reviewing (${age}s ago)"
            blocked=1
            reasons="${reasons}observer-reviewing "
        fi
    fi

    # ─── CHECK 2: Observer NEEDS_FIX items? ───
    if [ -f "$REVIEWS_LOG" ]; then
        local fixes
        fixes=$(grep -c "NEEDS_FIX" "$REVIEWS_LOG" 2>/dev/null || echo "0")
        fixes="${fixes//[^0-9]/}"
        [ -z "$fixes" ] && fixes=0
        if [ "$fixes" -gt 0 ]; then
            echo "[PHASE-GATE] NEEDS_FIX: $fixes items from observer"
            grep "NEEDS_FIX" "$REVIEWS_LOG" | tail -3
            blocked=2
            reasons="${reasons}observer-needs-fix "
        else
            echo "[PHASE-GATE] Observer: PASS"
        fi
    else
        echo "[PHASE-GATE] Observer: no reviews yet (OK for early phases)"
    fi

    # ─── CHECK 3: CodeRabbit on open PR? ───
    local pr_num
    pr_num=$(gh pr list --state open --json number -q '.[0].number' 2>/dev/null || echo "")

    if [ -n "$pr_num" ]; then
        echo "[PHASE-GATE] Open PR: #$pr_num"

        # Check for CodeRabbit reviews
        local cr_state
        cr_state=$(gh api "repos/{owner}/{repo}/pulls/$pr_num/reviews" \
            --jq '[.[] | select(.user.login | contains("coderabbit"))] | last | .state' 2>/dev/null || echo "NONE")

        case "$cr_state" in
            APPROVED)
                echo "[PHASE-GATE] CodeRabbit: APPROVED"
                ;;
            CHANGES_REQUESTED)
                echo "[PHASE-GATE] NEEDS_FIX: CodeRabbit requested changes"
                # Get the comments
                local comments
                comments=$(gh api "repos/{owner}/{repo}/pulls/$pr_num/comments" \
                    --jq '[.[] | select(.user.login | contains("coderabbit"))] | .[-3:] | .[].body' 2>/dev/null || echo "")
                if [ -n "$comments" ]; then
                    echo "$comments" | head -20
                fi
                blocked=2
                reasons="${reasons}coderabbit-changes "
                ;;
            NONE|"")
                # No CodeRabbit review yet — check if it's been long enough
                local pr_age
                pr_age=$(gh pr view "$pr_num" --json createdAt -q '.createdAt' 2>/dev/null || echo "")
                if [ -n "$pr_age" ]; then
                    local age_min
                    age_min=$(python3 -c "
from datetime import datetime, timezone
created = datetime.fromisoformat('$pr_age'.replace('Z','+00:00'))
now = datetime.now(timezone.utc)
print(int((now - created).total_seconds() / 60))
" 2>/dev/null || echo 0)
                    if [ "$age_min" -lt 5 ]; then
                        echo "[PHASE-GATE] WAIT: CodeRabbit hasn't reviewed yet (${age_min}m, give it 5m)"
                        blocked=1
                        reasons="${reasons}coderabbit-pending "
                    else
                        echo "[PHASE-GATE] CodeRabbit: no review after ${age_min}m — proceeding without"
                    fi
                fi
                ;;
            *)
                echo "[PHASE-GATE] CodeRabbit: $cr_state"
                ;;
        esac
    else
        echo "[PHASE-GATE] No open PR (OK — CodeRabbit check skipped)"
    fi

    # ─── VERDICT ───
    echo ""
    if [ "$blocked" -eq 0 ]; then
        echo "[PHASE-GATE] ✓ ALL CLEAR — proceed to next phase"
        touch "$GATE_CLEAR"
        return 0
    elif [ "$blocked" -eq 1 ]; then
        echo "[PHASE-GATE] ⏳ WAITING — run 'sleep 30' then check again"
        rm -f "$GATE_CLEAR"
        return 1
    else
        echo "[PHASE-GATE] ✗ BLOCKED — fix issues before proceeding"
        echo "[PHASE-GATE] Blocked by: $reasons"
        rm -f "$GATE_CLEAR"
        return 2
    fi
}

case "${1:-check}" in
    check) cmd_check ;;
    clear)
        # Force clear (for manual override)
        touch "$GATE_CLEAR"
        echo "[PHASE-GATE] Manually cleared"
        ;;
    *)
        echo "Usage: forge-phase-gate.sh check|clear"
        ;;
esac
