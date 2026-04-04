#!/bin/bash
# Forge Handshake — file-based communication between builder and observer
#
# Builder calls:
#   forge-handshake.sh request-review <phase>     — signal observer to review
#   forge-handshake.sh wait-for-review <phase>    — block until observer responds
#   forge-handshake.sh read-feedback              — read observer's feedback
#
# Observer calls:
#   forge-handshake.sh check-pending              — any phases waiting for review?
#   forge-handshake.sh submit-review <phase> <verdict> — write review result
#   forge-handshake.sh write-feedback <file> <rating> <issues> — append to feedback

set -uo pipefail

find_root() {
    local d="${1:-$PWD}"
    while [ "$d" != "/" ]; do
        [ -f "$d/CLAUDE.md" ] || [ -d "$d/.git" ] && echo "$d" && return
        d=$(dirname "$d")
    done
    echo "$PWD"
}

D="${PROJECT_ROOT:-$(find_root)}"
HANDSHAKE_DIR="$D/docs/.handshake"
FEEDBACK_FILE="$D/docs/.observer-feedback.md"
REVIEWS_LOG="$D/docs/.observer-reviews.log"

mkdir -p "$HANDSHAKE_DIR"

# ═══════════════════════════════════════════════
# BUILDER: Request review from observer
# ═══════════════════════════════════════════════
cmd_request_review() {
    local phase="${1:?Usage: forge-handshake.sh request-review <phase>}"
    local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Write the request file — observer polls for these
    cat > "$HANDSHAKE_DIR/phase-${phase}-ready" << EOF
{
  "phase": $phase,
  "requested_at": "$ts",
  "status": "PENDING",
  "files_to_review": [
$(cd "$D" && git diff --name-only HEAD~1 2>/dev/null | sed 's/^/    "/;s/$/"/' | paste -sd',' -)
  ]
}
EOF

    # Clear any old feedback for this phase
    rm -f "$HANDSHAKE_DIR/phase-${phase}-reviewed"

    echo "[HANDSHAKE] Review requested for Phase $phase at $ts"
    echo "[HANDSHAKE] Observer will review and respond. Waiting..."
}

# ═══════════════════════════════════════════════
# BUILDER: Wait for observer review (with timeout)
# ═══════════════════════════════════════════════
cmd_wait_for_review() {
    local phase="${1:?Usage: forge-handshake.sh wait-for-review <phase>}"
    local timeout="${2:-180}"  # default 3 minutes
    local elapsed=0

    # Check if review request exists
    if [ ! -f "$HANDSHAKE_DIR/phase-${phase}-ready" ]; then
        echo "[HANDSHAKE] No review requested for Phase $phase. Continuing."
        return 0
    fi

    # Poll for response
    while [ $elapsed -lt $timeout ]; do
        if [ -f "$HANDSHAKE_DIR/phase-${phase}-reviewed" ]; then
            local verdict=$(python3 -c "import json; print(json.load(open('$HANDSHAKE_DIR/phase-${phase}-reviewed')).get('verdict','UNKNOWN'))" 2>/dev/null)
            local fixes=$(python3 -c "import json; f=json.load(open('$HANDSHAKE_DIR/phase-${phase}-reviewed')).get('fixes_needed',[]); print(len(f))" 2>/dev/null)

            echo "[HANDSHAKE] Observer reviewed Phase $phase: $verdict ($fixes fixes needed)"

            if [ "$verdict" = "PASS" ] || [ "$verdict" = "APPROVED" ]; then
                echo "[HANDSHAKE] Phase $phase APPROVED. Continuing."
                return 0
            elif [ "$verdict" = "NEEDS_FIX" ]; then
                echo "[HANDSHAKE] Phase $phase NEEDS FIXES. Read docs/.observer-feedback.md for details."
                echo "[HANDSHAKE] Apply fixes, then continue."
                return 1
            fi
            return 0
        fi

        sleep 10
        elapsed=$((elapsed + 10))
        # Show progress every 30 seconds
        if [ $((elapsed % 30)) -eq 0 ]; then
            echo "[HANDSHAKE] Waiting for observer... ${elapsed}s / ${timeout}s"
        fi
    done

    echo "[HANDSHAKE] Observer timeout after ${timeout}s. Proceeding without review."
    echo "[HANDSHAKE] Observer can still review — findings will be applied in CASE 8 (violation remediation)."
    return 0
}

# ═══════════════════════════════════════════════
# BUILDER: Read feedback
# ═══════════════════════════════════════════════
cmd_read_feedback() {
    if [ -f "$FEEDBACK_FILE" ]; then
        echo "=== Observer Feedback ==="
        cat "$FEEDBACK_FILE"
    else
        echo "No observer feedback found."
    fi
}

# ═══════════════════════════════════════════════
# OBSERVER: Check for pending reviews
# ═══════════════════════════════════════════════
cmd_check_pending() {
    local found=0
    for req in "$HANDSHAKE_DIR"/phase-*-ready; do
        [ -f "$req" ] || continue
        local phase=$(basename "$req" | sed 's/phase-//;s/-ready//')
        local reviewed="$HANDSHAKE_DIR/phase-${phase}-reviewed"

        if [ ! -f "$reviewed" ]; then
            echo "PENDING: Phase $phase awaiting review"
            # Show files to review
            python3 -c "import json; files=json.load(open('$req')).get('files_to_review',[]); [print(f'  → {f}') for f in files]" 2>/dev/null
            found=1
        fi
    done

    if [ "$found" -eq 0 ]; then
        echo "No pending reviews."
    fi
}

# ═══════════════════════════════════════════════
# OBSERVER: Submit review for a phase
# ═══════════════════════════════════════════════
cmd_submit_review() {
    local phase="${1:?Usage: forge-handshake.sh submit-review <phase> <PASS|NEEDS_FIX>}"
    local verdict="${2:?Usage: forge-handshake.sh submit-review <phase> <PASS|NEEDS_FIX>}"
    local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Read fixes from feedback file if NEEDS_FIX
    local fixes="[]"
    if [ "$verdict" = "NEEDS_FIX" ] && [ -f "$FEEDBACK_FILE" ]; then
        fixes=$(python3 -c "
lines = open('$FEEDBACK_FILE').readlines()
fixes = [l.strip().lstrip('- ') for l in lines if l.strip().startswith('- ') and 'NEEDS_FIX' not in l]
import json; print(json.dumps(fixes[-10:]))
" 2>/dev/null || echo "[]")
    fi

    cat > "$HANDSHAKE_DIR/phase-${phase}-reviewed" << EOF
{
  "phase": $phase,
  "verdict": "$verdict",
  "reviewed_at": "$ts",
  "fixes_needed": $fixes
}
EOF

    echo "[HANDSHAKE] Submitted review for Phase $phase: $verdict"
}

# ═══════════════════════════════════════════════
# OBSERVER: Write feedback for a specific file
# ═══════════════════════════════════════════════
cmd_write_feedback() {
    local file="${1:?Usage: forge-handshake.sh write-feedback <file> <rating> <issues>}"
    local rating="${2:?}"
    shift 2
    local issues="$*"
    local ts=$(date -u +%H:%M:%S)

    # Append to feedback file
    echo "### $file — $rating/5" >> "$FEEDBACK_FILE"
    echo "$issues" >> "$FEEDBACK_FILE"
    echo "" >> "$FEEDBACK_FILE"

    # Also append to reviews log
    echo "$ts | $file | $rating/5 | $([ $rating -ge 4 ] && echo PASS || echo NEEDS_FIX) | $issues" >> "$REVIEWS_LOG"
}

# ═══════════════════════════════════════════════
# DISPATCH
# ═══════════════════════════════════════════════
case "${1:-help}" in
    request-review)   shift; cmd_request_review "$@" ;;
    wait-for-review)  shift; cmd_wait_for_review "$@" ;;
    read-feedback)    cmd_read_feedback ;;
    check-pending)    cmd_check_pending ;;
    submit-review)    shift; cmd_submit_review "$@" ;;
    write-feedback)   shift; cmd_write_feedback "$@" ;;
    *)
        echo "Forge Handshake — builder↔observer communication"
        echo ""
        echo "Builder commands:"
        echo "  request-review <phase>        Signal observer to review"
        echo "  wait-for-review <phase>       Block until observer responds (3min timeout)"
        echo "  read-feedback                 Read observer findings"
        echo ""
        echo "Observer commands:"
        echo "  check-pending                 Any phases waiting for review?"
        echo "  submit-review <phase> <verdict>  Write review result (PASS|NEEDS_FIX)"
        echo "  write-feedback <file> <rating> <issues>  Log a file review"
        ;;
esac
