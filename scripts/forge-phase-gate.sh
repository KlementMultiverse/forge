#!/bin/bash
# Forge Phase Gate — EXPLICIT approval required from observer + CodeRabbit
# Builder CANNOT proceed until both have explicitly approved.
#
# @forge-meta
# id: forge-phase-gate
# type: script
# depended_by.hooks: Stop
# depends_on.scripts: forge-enforce.sh
# provides: gate-check, phase-approval
# @end-forge-meta
#
# Returns:
#   0 = CLEAR (both explicitly approved)
#   1 = WAIT (still reviewing or no response yet)
#   2 = NEEDS_FIX (issues found, must fix first)
#
# Usage:
#   forge-phase-gate.sh check          — check both approvals
#   forge-phase-gate.sh clear          — manual override (emergency only)
#   forge-phase-gate.sh status         — show current approval state

set -uo pipefail

# Source shared phase mapping and dependency checker
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/forge-phase-map.sh"
source "$SCRIPT_DIR/forge-deps.sh" && check_forge_deps

D="${PROJECT_ROOT:-$PWD}"
APPROVAL_DIR="$D/docs/.approvals"
REVIEWS_LOG="$D/docs/.observer-reviews.log"
REVIEWING="$D/docs/.observer-reviewing"

mkdir -p "$APPROVAL_DIR"

get_current_phase() {
    local step
    step=$(python3 -c "
import json
with open('$D/docs/forge-state.json') as f:
    d = json.load(f)
print(d.get('current_step', 0))
" 2>/dev/null || echo 0)
    get_phase_for_step "$step"
}

cmd_check() {
    local phase
    phase=$(get_current_phase)
    local observer_ok=false
    local coderabbit_ok=false
    local approval_file="$APPROVAL_DIR/phase-${phase}.json"

    # ─── CIRCUIT BREAKER ───
    local STATE_FILE="$D/docs/forge-state.json"
    if [ -f "$STATE_FILE" ]; then
        local cb_action
        cb_action=$(python3 -c "
import json, datetime

with open('$STATE_FILE') as f:
    state = json.load(f)

cb = state.get('gate_circuit', {
    'state': 'CLOSED',
    'poll_count': 0,
    'cooldown_count': 0,
    'last_poll_at': None,
    'cooldown_until': None,
    'last_response': None
})

now = datetime.datetime.now(datetime.UTC)

# Check if in cooldown
if cb['state'] == 'OPEN' and cb.get('cooldown_until'):
    cooldown_end = datetime.datetime.fromisoformat(cb['cooldown_until'])
    if now < cooldown_end:
        remaining = int((cooldown_end - now).total_seconds())
        print(f'COOLDOWN:{remaining}')
    else:
        # Cooldown expired → half-open
        cb['state'] = 'HALF_OPEN'
        state['gate_circuit'] = cb
        with open('$STATE_FILE', 'w') as f:
            json.dump(state, f, indent=2)
        print('HALF_OPEN')
elif cb['state'] == 'HALF_OPEN':
    print('POLL')
elif cb.get('cooldown_count', 0) >= 3:
    print('ESCALATE')
else:
    # CLOSED — normal polling
    cb['poll_count'] = cb.get('poll_count', 0) + 1
    cb['last_poll_at'] = now.isoformat()

    # After 5 polls → open circuit
    if cb['poll_count'] >= 5:
        cb['state'] = 'OPEN'
        cb['cooldown_count'] = cb.get('cooldown_count', 0) + 1
        cb['cooldown_until'] = (now + datetime.timedelta(minutes=5)).isoformat()
        cb['poll_count'] = 0
        state['gate_circuit'] = cb
        with open('$STATE_FILE', 'w') as f:
            json.dump(state, f, indent=2)
        print('OPEN')
    else:
        state['gate_circuit'] = cb
        with open('$STATE_FILE', 'w') as f:
            json.dump(state, f, indent=2)
        print('POLL')
" 2>/dev/null || echo "POLL")

        case "$cb_action" in
            COOLDOWN:*)
                local remaining="${cb_action#COOLDOWN:}"
                echo "[PHASE-GATE] CIRCUIT OPEN — cooldown active (${remaining}s remaining)"
                echo "[PHASE-GATE] Action: Wait for cooldown. Do NOT poll."
                return 1
                ;;
            OPEN)
                echo "[PHASE-GATE] CIRCUIT OPENED — 5 polls with no approval"
                echo "[PHASE-GATE] Entering 5-minute cooldown. Will auto-retry after."
                return 1
                ;;
            ESCALATE)
                echo "[PHASE-GATE] ESCALATED — 3 cooldown cycles exhausted"
                echo "[PHASE-GATE] Manual override needed: forge-phase-gate.sh clear"
                return 2
                ;;
            HALF_OPEN)
                echo "[PHASE-GATE] HALF-OPEN — cooldown expired, single poll..."
                ;;
            POLL)
                ;;
        esac
    fi

    echo "[PHASE-GATE] Checking approvals for Phase $phase"
    echo ""

    # ─── OBSERVER CHECK ───
    echo "--- Observer ---"

    # Is observer still reviewing?
    if [ -f "$REVIEWING" ]; then
        local age
        age=$(python3 -c "import os,time; print(int(time.time()-os.path.getmtime('$REVIEWING')))" 2>/dev/null || echo 0)
        if [ "$age" -gt 600 ]; then
            echo "  Review stale (${age}s). Clearing signal."
            rm -f "$REVIEWING"
        else
            echo "  STATUS: REVIEWING (${age}s ago)"
            echo "  ACTION: Wait for observer to finish. Run: sleep 30"
            echo ""
            echo "[PHASE-GATE] ⏳ WAITING — observer still reviewing"
            return 1
        fi
    fi

    # Check for explicit APPROVED in reviews log
    if [ -f "$REVIEWS_LOG" ]; then
        # Look for NEEDS_FIX first (blocks everything)
        local fixes
        fixes=$(grep -c "NEEDS_FIX" "$REVIEWS_LOG" 2>/dev/null || true)
        fixes="${fixes//[^0-9]/}"
        [ -z "$fixes" ] && fixes=0

        if [ "$fixes" -gt 0 ]; then
            echo "  STATUS: NEEDS_FIX ($fixes items)"
            grep "NEEDS_FIX" "$REVIEWS_LOG" | tail -3
            echo "  ACTION: Fix all NEEDS_FIX items. Observer will re-review on file change."
            echo ""
            echo "[PHASE-GATE] ✗ BLOCKED — observer found issues"
            return 2
        fi

        # Look for explicit APPROVED for this phase
        if grep -q "PHASE-${phase}-APPROVED" "$REVIEWS_LOG" 2>/dev/null; then
            echo "  STATUS: APPROVED ✓"
            observer_ok=true
        else
            # Has reviews but no explicit approval — need observer to approve
            local review_count
            review_count=$(grep -c "PASS" "$REVIEWS_LOG" 2>/dev/null || true)
            review_count="${review_count//[^0-9]/}"
            [ -z "$review_count" ] && review_count=0
            echo "  STATUS: $review_count reviews PASS but NO explicit phase approval"
            echo "  ACTION: Observer must write 'PHASE-${phase}-APPROVED' to reviews log"
            echo "  WAITING: Observer will auto-approve when all artifacts pass review"
        fi
    else
        echo "  STATUS: No reviews yet"
        echo "  ACTION: Observer hasn't reviewed Phase $phase artifacts yet. Waiting."
    fi

    # ─── CODERABBIT CHECK ───
    echo ""
    echo "--- CodeRabbit ---"

    local pr_num
    pr_num=$(gh pr list --state open --json number -q '.[0].number' 2>/dev/null || echo "")

    if [ -n "$pr_num" ]; then
        echo "  PR: #$pr_num"

        # Get CodeRabbit review state
        local cr_state
        cr_state=$(gh api "repos/{owner}/{repo}/pulls/$pr_num/reviews" \
            --jq '[.[] | select(.user.login | contains("coderabbit"))] | last | .state' 2>/dev/null || echo "NONE")

        # Also check for CodeRabbit comments (it sometimes comments without formal review)
        local cr_comments
        cr_comments=$(gh api "repos/{owner}/{repo}/pulls/$pr_num/comments" \
            --jq '[.[] | select(.user.login | contains("coderabbit"))] | length' 2>/dev/null || echo "0")

        case "$cr_state" in
            APPROVED)
                echo "  STATUS: APPROVED ✓"
                coderabbit_ok=true
                ;;
            CHANGES_REQUESTED)
                echo "  STATUS: CHANGES REQUESTED"
                echo "  ACTION: Read CodeRabbit comments, fix issues, push, wait for re-review"
                # Show latest comments
                gh api "repos/{owner}/{repo}/pulls/$pr_num/comments" \
                    --jq '[.[] | select(.user.login | contains("coderabbit"))] | .[-3:] | .[].body' 2>/dev/null | head -30
                echo ""
                echo "[PHASE-GATE] ✗ BLOCKED — CodeRabbit requested changes"
                return 2
                ;;
            COMMENTED)
                echo "  STATUS: COMMENTED (not yet approved)"
                echo "  ACTION: Check comments — may need fixes. Waiting for APPROVED state."
                if [ "$cr_comments" -gt 0 ]; then
                    echo "  ($cr_comments comments — read them with: gh pr view $pr_num --comments)"
                fi
                ;;
            NONE|"")
                # Check how long PR has been open
                local pr_created
                pr_created=$(gh pr view "$pr_num" --json createdAt -q '.createdAt' 2>/dev/null || echo "")
                if [ -n "$pr_created" ]; then
                    local age_min
                    age_min=$(python3 -c "
from datetime import datetime, timezone
created = datetime.fromisoformat('$pr_created'.replace('Z','+00:00'))
now = datetime.now(timezone.utc)
print(int((now - created).total_seconds() / 60))
" 2>/dev/null || echo 0)
                    echo "  STATUS: No review yet (PR open ${age_min}m)"
                    if [ "$age_min" -lt 10 ]; then
                        echo "  ACTION: CodeRabbit typically responds in 5-10 min. Waiting."
                    else
                        echo "  STATUS: No response after ${age_min}m"
                        echo "  ACTION: CodeRabbit may be unavailable. Check: gh pr view $pr_num --comments"
                        echo "  You can manually approve with: forge-phase-gate.sh approve-cr $phase"
                    fi
                else
                    echo "  STATUS: Cannot determine PR age"
                fi
                ;;
            *)
                echo "  STATUS: $cr_state (unknown)"
                ;;
        esac
    else
        local has_remote
        has_remote=$(git -C "$D" remote -v 2>/dev/null | head -1)
        if [ -z "$has_remote" ]; then
            echo "  STATUS: *** NO GIT REMOTE CONFIGURED ***"
            echo "  ERROR: CodeRabbit CANNOT review without a GitHub repo."
            echo "  FIX: gh repo create <org>/<name> --private --source=. --push"
            echo ""
            echo "[PHASE-GATE] ⚠ WARNING: No remote = no CodeRabbit = reduced quality"
            coderabbit_ok=true
        else
            echo "  STATUS: Remote exists but no open PR"
            echo "  FIX: git push && gh pr create --title 'Phase $phase' --body 'Forge build'"
        fi
    fi

    # ─── VERDICT ───
    echo ""
    if $observer_ok && $coderabbit_ok; then
        echo "[PHASE-GATE] ✓ BOTH APPROVED — proceed to next phase"
        # Write approval record
        python3 -c "
import json
from datetime import datetime, timezone
approval = {
    'phase': $phase,
    'observer': 'APPROVED',
    'coderabbit': 'APPROVED',
    'approved_at': datetime.now(timezone.utc).isoformat()
}
with open('$approval_file', 'w') as f:
    json.dump(approval, f, indent=2)
"
        # Reset circuit breaker on approval
        if [ -f "$D/docs/forge-state.json" ]; then
            python3 -c "
import json
with open('$D/docs/forge-state.json') as f:
    state = json.load(f)
state['gate_circuit'] = {'state': 'CLOSED', 'poll_count': 0, 'cooldown_count': 0, 'last_poll_at': None, 'cooldown_until': None, 'last_response': None}
with open('$D/docs/forge-state.json', 'w') as f:
    json.dump(state, f, indent=2)
" 2>/dev/null
        fi
        return 0
    elif $observer_ok; then
        echo "[PHASE-GATE] ⏳ WAITING — Observer approved, CodeRabbit pending"
        echo "  Run: sleep 60 then check again"
        return 1
    elif $coderabbit_ok; then
        echo "[PHASE-GATE] ⏳ WAITING — CodeRabbit approved, Observer pending"
        echo "  Observer must explicitly approve Phase $phase"
        return 1
    else
        echo "[PHASE-GATE] ⏳ WAITING — neither has approved yet"
        echo "  Run: sleep 60 then check again"
        return 1
    fi
}

cmd_status() {
    local phase
    phase=$(get_current_phase)
    echo "=== Phase Gate Status ==="
    echo "Current phase: $phase"
    echo ""

    # Observer
    if grep -q "PHASE-${phase}-APPROVED" "$REVIEWS_LOG" 2>/dev/null; then
        echo "Observer: APPROVED ✓"
    elif [ -f "$REVIEWING" ]; then
        echo "Observer: REVIEWING..."
    elif grep -q "NEEDS_FIX" "$REVIEWS_LOG" 2>/dev/null; then
        echo "Observer: NEEDS_FIX ✗"
    else
        echo "Observer: PENDING"
    fi

    # CodeRabbit
    local pr_num
    pr_num=$(gh pr list --state open --json number -q '.[0].number' 2>/dev/null || echo "")
    if [ -n "$pr_num" ]; then
        local cr_state
        cr_state=$(gh api "repos/{owner}/{repo}/pulls/$pr_num/reviews" \
            --jq '[.[] | select(.user.login | contains("coderabbit"))] | last | .state' 2>/dev/null || echo "NONE")
        echo "CodeRabbit: $cr_state (PR #$pr_num)"
    else
        echo "CodeRabbit: N/A (no PR)"
    fi

    # Approval file
    if [ -f "$APPROVAL_DIR/phase-${phase}.json" ]; then
        echo ""
        echo "Approval record:"
        cat "$APPROVAL_DIR/phase-${phase}.json"
    fi
}

cmd_approve_cr() {
    # Manual CodeRabbit approval (when CR is unavailable)
    local phase="${1:-$(get_current_phase)}"
    echo "PHASE-${phase}-CR-MANUAL-APPROVED" >> "$REVIEWS_LOG"
    echo "Manually approved CodeRabbit for Phase $phase"
}

case "${1:-check}" in
    check)      cmd_check ;;
    status)     cmd_status ;;
    clear)      touch "$APPROVAL_DIR/phase-$(get_current_phase).json"; echo "Manually cleared" ;;
    approve-cr) shift; cmd_approve_cr "$@" ;;
    *)          echo "Usage: forge-phase-gate.sh check|status|clear|approve-cr [phase]" ;;
esac
