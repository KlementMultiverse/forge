#!/bin/bash
# Forge Trace Update — manage in-file FORGE TRACE blocks
# Adds lightweight change history to code files.
#
# Usage:
#   forge-trace-update.sh add <file> <req> <agent> <pr> [description]
#   forge-trace-update.sh add-multi <file> <req1,req2> <agent> <pr> [desc]
#   forge-trace-update.sh show <file>
#   forge-trace-update.sh check <file>     — verify trace block exists
#   forge-trace-update.sh init <file> <req> <agent> — create initial trace
#   forge-trace-update.sh split <src> <dst1> <dst2> — handle file splits
#   forge-trace-update.sh archive <file>   — archive overflow to .forge/trace-archive.json
#
# Implements #44 + #51: In-file FORGE TRACE block with edge case handling
#
# Source of truth:
#   - Inline [REQ-xxx] in code = WHAT the code does
#   - FORGE TRACE block = WHO changed it, WHEN, WHY (PR reference)
#
# Edge cases handled (#51):
#   1. Merge conflicts: last writer appends; reviewer reconciles at N9
#   2. Drift: check command detects missing trace; warn hook can enforce
#   3. Source of truth: inline REQ = what, trace = who/when/why
#   4. Archive: overflow to .forge/trace-archive.json
#   5. Multi-language: comment syntax per extension
#   6. Linter ordering: trace-update runs LAST (documented for hook config)
#   7. Multi-REQ: add-multi command, one line per REQ
#   8. Human commits: falls back to git author if no agent
#   9. File splits: split command copies trace + adds split note

set -uo pipefail

D="${PROJECT_ROOT:-$PWD}"
MAX_TRACE_LINES=10
ARCHIVE_FILE="$D/.forge/trace-archive.json"

get_comment_char() {
    local file="$1"
    case "$file" in
        *.py|*.sh|*.yml|*.yaml|*.toml|*.rb)  echo "#" ;;
        *.js|*.ts|*.jsx|*.tsx|*.java|*.go|*.rs|*.c|*.cpp|*.h) echo "//" ;;
        *.css|*.sql)  echo "/*" ;;
        *.html)       echo "<!--" ;;
        *)            echo "#" ;;
    esac
}

get_comment_end() {
    local file="$1"
    case "$file" in
        *.css|*.sql)  echo " */" ;;
        *.html)       echo " -->" ;;
        *)            echo "" ;;
    esac
}

# Edge case #5: Check if file supports inline comments
supports_comments() {
    local file="$1"
    case "$file" in
        *.json|*.yaml|*.yml) return 1 ;;  # No inline comments or sidecar preferred
        *)                   return 0 ;;
    esac
}

# Edge case #8: Get current agent or fall back to git author
get_author() {
    local agent="${1:-}"
    if [ -n "$agent" ]; then
        echo "$agent"
        return
    fi
    # Try to get from activity log
    if [ -f "$D/docs/.builder-activity.log" ]; then
        local last_agent
        last_agent=$(grep "Agent:" "$D/docs/.builder-activity.log" 2>/dev/null | tail -1 | sed 's/.*Agent: //' | awk '{print $1}')
        if [ -n "$last_agent" ]; then
            echo "$last_agent"
            return
        fi
    fi
    # Fall back to git author
    local git_author
    git_author=$(git config user.name 2>/dev/null || echo "unknown")
    echo "$git_author"
}

TRACE_MARKER="FORGE TRACE"

# Edge case #4: Archive overflow entries to .forge/trace-archive.json
archive_overflow() {
    local file="$1"
    local cc
    cc=$(get_comment_char "$file")

    # Get all trace lines
    local trace_lines
    trace_lines=$(awk "/$TRACE_MARKER/{found=1; next} found{print}" "$file" | grep "^${cc}" 2>/dev/null || echo "")

    if [ -z "$trace_lines" ]; then
        return
    fi

    local trace_count
    trace_count=$(echo "$trace_lines" | wc -l)

    if [ "$trace_count" -le "$MAX_TRACE_LINES" ]; then
        return
    fi

    # Archive oldest entries (beyond MAX_TRACE_LINES)
    local overflow_count=$((trace_count - MAX_TRACE_LINES))
    local overflow_lines
    overflow_lines=$(echo "$trace_lines" | head -"$overflow_count")

    mkdir -p "$(dirname "$ARCHIVE_FILE")"

    python3 - "$ARCHIVE_FILE" "$file" "$overflow_lines" << 'PYEOF'
import json, sys, os
from datetime import datetime, timezone

archive_path = sys.argv[1]
source_file = sys.argv[2]
overflow = sys.argv[3]

archive = {}
if os.path.exists(archive_path):
    try:
        with open(archive_path) as f:
            archive = json.load(f)
    except (json.JSONDecodeError, IOError):
        archive = {}

archive.setdefault("version", "1.0.0")
archive.setdefault("entries", {})

entries = archive["entries"].setdefault(source_file, [])
existing_lines = {e["line"] for e in entries}
for line in overflow.strip().split("\n"):
    stripped = line.strip()
    if stripped and stripped not in existing_lines:
        entries.append({
            "line": stripped,
            "archived_at": datetime.now(timezone.utc).isoformat(),
        })
        existing_lines.add(stripped)

with open(archive_path, 'w') as f:
    json.dump(archive, f, indent=2)
PYEOF

    echo "  Archived $overflow_count entries to $ARCHIVE_FILE"
}

cmd_add() {
    local file="${1:?Usage: forge-trace-update.sh add <file> <req> <agent> <pr> [description]}"
    local req="${2:?Missing REQ tag}"
    local agent
    agent=$(get_author "${3:-}")
    local pr="${4:?Missing PR number}"
    local desc="${5:-}"
    local today
    today=$(date +%Y-%m-%d)

    if [ ! -f "$file" ]; then
        echo "File not found: $file"
        return 1
    fi

    # Edge case #5: JSON/YAML files without comment support get sidecar
    if ! supports_comments "$file"; then
        local sidecar="${file}.forge-trace"
        echo "# ─── ${TRACE_MARKER} ─── (sidecar for $(basename "$file"))" > "$sidecar"
        echo "# [${req}] modified by ${agent} | PR ${pr} | ${today}${desc:+ | $desc}" >> "$sidecar"
        echo "Created sidecar trace: $sidecar"
        return 0
    fi

    local cc
    cc=$(get_comment_char "$file")
    local ce
    ce=$(get_comment_end "$file")

    local trace_line="${cc} [${req}] modified by ${agent} | PR ${pr} | ${today}"
    if [ -n "$desc" ]; then
        trace_line="${trace_line} | ${desc}"
    fi
    trace_line="${trace_line}${ce}"

    # Check if trace block exists
    if grep -q "$TRACE_MARKER" "$file" 2>/dev/null; then
        # Archive overflow before adding
        archive_overflow "$file"

        # Count existing trace lines
        local trace_count
        trace_count=$(awk "/$TRACE_MARKER/{found=1; next} found{print}" "$file" | grep -c "^${cc}" 2>/dev/null || echo "0")

        # If at max, remove oldest (first trace line after marker)
        if [ "$trace_count" -ge "$MAX_TRACE_LINES" ]; then
            python3 - "$file" "$TRACE_MARKER" "$cc" << 'PYEOF'
import sys
filepath, marker, comment_char = sys.argv[1], sys.argv[2], sys.argv[3]
with open(filepath) as f:
    lines = f.readlines()
marker_idx = None
first_trace_idx = None
for i, line in enumerate(lines):
    if marker in line:
        marker_idx = i
    elif marker_idx is not None and first_trace_idx is None and line.strip().startswith(comment_char):
        first_trace_idx = i
        break
if first_trace_idx is not None:
    del lines[first_trace_idx]
    with open(filepath, 'w') as f:
        f.writelines(lines)
PYEOF
        fi

        # Append new trace line at end of file
        echo "$trace_line" >> "$file"
    else
        # Create trace block
        echo "" >> "$file"
        echo "${cc} ─── ${TRACE_MARKER} ───${ce}" >> "$file"
        echo "$trace_line" >> "$file"
    fi

    echo "Added trace: $trace_line"
}

# Edge case #7: Multi-REQ changes — one line per REQ
# Archives once before adding, not per REQ (prevents duplicate archiving)
cmd_add_multi() {
    local file="${1:?Usage: forge-trace-update.sh add-multi <file> <req1,req2> <agent> <pr> [desc]}"
    local reqs="${2:?Missing REQ tags (comma-separated)}"
    local agent
    agent=$(get_author "${3:-}")
    local pr="${4:?Missing PR number}"
    local desc="${5:-}"
    local today
    today=$(date +%Y-%m-%d)

    if [ ! -f "$file" ]; then
        echo "File not found: $file"
        return 1
    fi

    if ! supports_comments "$file"; then
        # Sidecar mode — append all REQs to sidecar
        local sidecar="${file}.forge-trace"
        if [ ! -f "$sidecar" ]; then
            echo "# ─── ${TRACE_MARKER} ─── (sidecar for $(basename "$file"))" > "$sidecar"
        fi
        IFS=',' read -ra req_array <<< "$reqs"
        for req in "${req_array[@]}"; do
            req=$(echo "$req" | xargs)
            echo "# [${req}] modified by ${agent} | PR ${pr} | ${today}${desc:+ | $desc}" >> "$sidecar"
        done
        echo "Added ${#req_array[@]} trace entries to sidecar: $sidecar"
        return 0
    fi

    local cc ce
    cc=$(get_comment_char "$file")
    ce=$(get_comment_end "$file")

    # Ensure trace block exists
    if ! grep -q "$TRACE_MARKER" "$file" 2>/dev/null; then
        echo "" >> "$file"
        echo "${cc} ─── ${TRACE_MARKER} ───${ce}" >> "$file"
    fi

    # Archive once before adding multiple entries
    archive_overflow "$file"

    IFS=',' read -ra req_array <<< "$reqs"
    for req in "${req_array[@]}"; do
        req=$(echo "$req" | xargs)
        local trace_line="${cc} [${req}] modified by ${agent} | PR ${pr} | ${today}"
        if [ -n "$desc" ]; then
            trace_line="${trace_line} | ${desc}"
        fi
        trace_line="${trace_line}${ce}"
        echo "$trace_line" >> "$file"
    done

    echo "Added ${#req_array[@]} trace entries to $file"
}

cmd_init() {
    local file="${1:?Usage: forge-trace-update.sh init <file> <req> <agent>}"
    local req="${2:?Missing REQ tag}"
    local agent
    agent=$(get_author "${3:-}")
    local today
    today=$(date +%Y-%m-%d)

    if [ ! -f "$file" ]; then
        echo "File not found: $file"
        return 1
    fi

    # Edge case #5: sidecar for non-comment files
    if ! supports_comments "$file"; then
        local sidecar="${file}.forge-trace"
        echo "# ─── ${TRACE_MARKER} ─── (sidecar for $(basename "$file"))" > "$sidecar"
        echo "# [${req}] created by ${agent} | ${today}" >> "$sidecar"
        echo "Initialized sidecar trace: $sidecar"
        return 0
    fi

    local cc
    cc=$(get_comment_char "$file")
    local ce
    ce=$(get_comment_end "$file")

    if grep -q "$TRACE_MARKER" "$file" 2>/dev/null; then
        echo "Trace block already exists in $file"
        return 0
    fi

    echo "" >> "$file"
    echo "${cc} ─── ${TRACE_MARKER} ───${ce}" >> "$file"
    echo "${cc} [${req}] created by ${agent} | ${today}${ce}" >> "$file"

    echo "Initialized trace in $file"
}

# Edge case #9: File splits — copy trace to both files + add split note
cmd_split() {
    local src="${1:?Usage: forge-trace-update.sh split <source> <dest1> <dest2>}"
    local dst1="${2:?Missing first destination file}"
    local dst2="${3:?Missing second destination file}"
    local today
    today=$(date +%Y-%m-%d)

    if [ ! -f "$src" ]; then
        echo "Source file not found: $src"
        return 1
    fi

    # Get existing trace lines (raw text, will be re-commented per destination)
    local trace_lines
    trace_lines=$(awk "/$TRACE_MARKER/{found=1; next} found{print}" "$src" 2>/dev/null || echo "")

    if [ -z "$trace_lines" ]; then
        echo "No trace block in $src — nothing to copy"
        return 0
    fi

    # Add trace to dst1 if it exists — use DST comment syntax
    if [ -f "$dst1" ] && ! grep -q "$TRACE_MARKER" "$dst1" 2>/dev/null; then
        local cc1 ce1
        cc1=$(get_comment_char "$dst1")
        ce1=$(get_comment_end "$dst1")
        echo "" >> "$dst1"
        echo "${cc1} ─── ${TRACE_MARKER} ───${ce1}" >> "$dst1"
        echo "$trace_lines" >> "$dst1"
        echo "${cc1} split from $(basename "$src") | ${today}${ce1}" >> "$dst1"
        echo "Copied trace to $dst1"
    fi

    # Add trace to dst2 if it exists — use DST comment syntax
    if [ -f "$dst2" ] && ! grep -q "$TRACE_MARKER" "$dst2" 2>/dev/null; then
        local cc2 ce2
        cc2=$(get_comment_char "$dst2")
        ce2=$(get_comment_end "$dst2")
        echo "" >> "$dst2"
        echo "${cc2} ─── ${TRACE_MARKER} ───${ce2}" >> "$dst2"
        echo "$trace_lines" >> "$dst2"
        echo "${cc2} split from $(basename "$src") | ${today}${ce2}" >> "$dst2"
        echo "Copied trace to $dst2"
    fi

    # Add split note to source — use SOURCE comment syntax
    if [ -f "$src" ]; then
        local cc_src ce_src
        cc_src=$(get_comment_char "$src")
        ce_src=$(get_comment_end "$src")
        echo "${cc_src} split to $(basename "$dst1"), $(basename "$dst2") | ${today}${ce_src}" >> "$src"
        echo "Added split note to $src"
    fi
}

cmd_show() {
    local file="${1:?Usage: forge-trace-update.sh show <file>}"

    if [ ! -f "$file" ]; then
        echo "File not found: $file"
        return 1
    fi

    # Check for sidecar first
    if [ -f "${file}.forge-trace" ]; then
        echo "=== FORGE TRACE (sidecar): $file ==="
        cat "${file}.forge-trace"
        return 0
    fi

    if grep -q "$TRACE_MARKER" "$file" 2>/dev/null; then
        echo "=== FORGE TRACE: $file ==="
        awk "/$TRACE_MARKER/{found=1} found{print}" "$file"
    else
        echo "No FORGE TRACE block in $file"
    fi
}

cmd_check() {
    local file="${1:?Usage: forge-trace-update.sh check <file>}"

    if [ ! -f "$file" ]; then
        echo "File not found: $file"
        return 1
    fi

    # Check sidecar for non-comment files
    if ! supports_comments "$file"; then
        if [ -f "${file}.forge-trace" ]; then
            echo "PASS: $file has sidecar FORGE TRACE"
            return 0
        else
            echo "FAIL: $file missing FORGE TRACE sidecar (${file}.forge-trace)"
            return 1
        fi
    fi

    if grep -q "$TRACE_MARKER" "$file" 2>/dev/null; then
        local trace_count
        local cc
        cc=$(get_comment_char "$file")
        trace_count=$(awk "/$TRACE_MARKER/{found=1; next} found{print}" "$file" | grep -c "^${cc}" 2>/dev/null || echo "0")
        echo "PASS: $file has FORGE TRACE ($trace_count entries)"
        return 0
    else
        # Edge case #2: drift detection
        echo "FAIL: $file missing FORGE TRACE block"
        echo "  Fix: forge-trace-update.sh init $file <REQ> <agent>"
        return 1
    fi
}

# Edge case #4: Show archived entries for a file
cmd_archive() {
    local file="${1:?Usage: forge-trace-update.sh archive <file>}"

    if [ ! -f "$ARCHIVE_FILE" ]; then
        echo "No archive file at $ARCHIVE_FILE"
        return 0
    fi

    python3 - "$ARCHIVE_FILE" "$file" << 'PYEOF'
import json, sys
archive_path, target_file = sys.argv[1], sys.argv[2]
with open(archive_path) as f:
    archive = json.load(f)
entries = archive.get("entries", {}).get(target_file, [])
if not entries:
    print(f"No archived entries for {target_file}")
else:
    print(f"=== Archived FORGE TRACE: {target_file} ({len(entries)} entries) ===")
    for e in entries:
        print(f"  {e['line']}  (archived: {e.get('archived_at', 'unknown')})")
PYEOF
}

case "${1:-help}" in
    add)       shift; cmd_add "$@" ;;
    add-multi) shift; cmd_add_multi "$@" ;;
    init)      shift; cmd_init "$@" ;;
    show)      shift; cmd_show "$@" ;;
    check)     shift; cmd_check "$@" ;;
    split)     shift; cmd_split "$@" ;;
    archive)   shift; cmd_archive "$@" ;;
    *)
        echo "Forge Trace Update — in-file change history"
        echo ""
        echo "Usage: forge-trace-update.sh <command> [args]"
        echo ""
        echo "Commands:"
        echo "  add <file> <req> <agent> <pr> [desc]       Add trace entry"
        echo "  add-multi <file> <r1,r2> <agent> <pr> [d]  Add multiple REQs"
        echo "  init <file> <req> <agent>                  Create initial trace"
        echo "  show <file>                                Show trace block"
        echo "  check <file>                               Verify trace exists"
        echo "  split <src> <dst1> <dst2>                  Handle file splits"
        echo "  archive <file>                             Show archived entries"
        echo ""
        echo "Source of truth:"
        echo "  Inline [REQ-xxx] = WHAT the code does"
        echo "  FORGE TRACE block = WHO changed it, WHEN, WHY"
        ;;
esac
