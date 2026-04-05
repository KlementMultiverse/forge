#!/bin/bash
# Observer check script — runs every cycle, detects new files, triggers review
#
# Usage: forge-observer-check.sh <project_path>
# Output: status line + list of files needing review

set -uo pipefail

PROJ="${1:?Usage: forge-observer-check.sh <project_path>}"
STATE="$PROJ/docs/forge-state.json"
ACTIVITY="$PROJ/docs/.builder-activity.log"
REVIEWS="$PROJ/docs/.observer-reviews.log"
LAST_CHECK="/tmp/.forge-observer-last-check-$(echo "$PROJ" | md5sum | cut -c1-8)"
REVIEWED_FILES="/tmp/.forge-observer-reviewed-$(echo "$PROJ" | md5sum | cut -c1-8)"

touch "$LAST_CHECK" 2>/dev/null || true
touch "$REVIEWED_FILES" 2>/dev/null || true

# === STATE ===
phase="?"
step="?"
status="?"
if [ -f "$STATE" ]; then
    eval $(python3 -c "
import json
d = json.load(open('$STATE'))
print(f'phase={d.get(\"current_phase\",\"?\")};step={d.get(\"current_step\",\"?\")};status={d.get(\"status\",\"?\")}')" 2>/dev/null || echo "phase=?;step=?;status=?")
fi

# === FILES ===
total_files=$(find "$PROJ" -not -path "*/.git/*" -not -path "*__pycache__*" -not -path "*/.venv/*" -type f 2>/dev/null | wc -l)
new_files=$(find "$PROJ" -not -path "*/.git/*" -not -path "*/.venv/*" -not -path "*__pycache__*" -newer "$LAST_CHECK" -name "*.py" -o -newer "$LAST_CHECK" -name "*.md" -o -newer "$LAST_CHECK" -name "*.yml" -o -newer "$LAST_CHECK" -name "*.html" 2>/dev/null | grep -v ".venv" | grep -v "__pycache__" || true)
new_count=$(echo "$new_files" | grep -c "." 2>/dev/null || echo 0)

# === COMMITS ===
commits=$(git -C "$PROJ" rev-list --count HEAD 2>/dev/null || echo 0)

# === LAST ACTIVITY ===
last_activity="none"
if [ -f "$ACTIVITY" ]; then
    last_line=$(tail -1 "$ACTIVITY" 2>/dev/null || echo "")
    if [ -n "$last_line" ]; then
        last_activity=$(echo "$last_line" | cut -c1-50)
    fi
fi

# === STATUS LINE ===
echo "Phase $phase | Step $step/57 | Files $total_files (+$new_count new) | Commits $commits | Active: $last_activity"

# === FILES NEEDING REVIEW ===
review_needed=""
key_patterns="CLAUDE.md SPEC.md design-doc.md models.py api.py schemas.py tests.py tests_.*.py services.py docker-compose.yml DEPLOY.md urls.py views.py"

if [ -n "$new_files" ]; then
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        basename=$(basename "$file")

        # Check if this is a key file
        is_key=false
        for pattern in $key_patterns; do
            if echo "$basename" | grep -qE "^${pattern}$"; then
                is_key=true
                break
            fi
        done

        # Check if already reviewed (same path + same size = same content)
        if $is_key; then
            file_id="${file}:$(wc -c < "$file" 2>/dev/null || echo 0)"
            if ! grep -qF "$file_id" "$REVIEWED_FILES" 2>/dev/null; then
                review_needed="${review_needed}${file}\n"
                echo "$file_id" >> "$REVIEWED_FILES"
            fi
        fi
    done <<< "$new_files"
fi

# === OUTPUT REVIEW LIST ===
if [ -n "$review_needed" ]; then
    echo ""
    echo "=== FILES NEED REVIEW ==="
    echo -e "$review_needed" | grep -v "^$" | while read -r f; do
        echo "  REVIEW: $f"
    done
    echo ""
    echo "ACTION: For each file above, run steps 1-5 from the review protocol:"
    echo "  1. touch $PROJ/docs/.observer-reviewing"
    echo "  2. Spawn reviewer agent to rate the file"
    echo "  3. Log rating to $PROJ/docs/.observer-reviews.log"
    echo "  4. rm $PROJ/docs/.observer-reviewing"
    echo "  5. If all files reviewed and all PASS: bash ~/.claude/scripts/forge-observer-approve.sh approve $PROJ"
else
    # Check if we're at a gate boundary and need to approve
    if echo "$step" | grep -qE "^(8|11|19|39|46|56)$"; then
        approval_status=$(bash ~/.claude/scripts/forge-observer-approve.sh check "$PROJ" 2>&1 | tail -1)
        if echo "$approval_status" | grep -q "READY TO APPROVE"; then
            echo ""
            echo "=== GATE BOUNDARY — APPROVAL NEEDED ==="
            echo "ACTION: Run: bash ~/.claude/scripts/forge-observer-approve.sh approve $PROJ"
        elif echo "$approval_status" | grep -q "ALREADY APPROVED"; then
            echo "Gate: APPROVED"
        fi
    fi
fi

touch "$LAST_CHECK"
