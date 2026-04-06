#!/bin/bash
# Forge Trace Update — manage in-file FORGE TRACE blocks
# Adds lightweight change history to code files.
#
# Usage:
#   forge-trace-update.sh add <file> <req> <agent> <pr> <description>
#   forge-trace-update.sh show <file>
#   forge-trace-update.sh check <file>     — verify trace block exists
#   forge-trace-update.sh init <file> <req> <agent> — create initial trace
#
# Implements #44: In-file FORGE TRACE block
#
# Rules:
#   - Trace block MUST be at the END of the file
#   - Max 10 lines — older entries archived
#   - Language-aware comment syntax
#   - Inline REQ = what, trace = who/when/why

set -uo pipefail

D="${PROJECT_ROOT:-$PWD}"
MAX_TRACE_LINES=10

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

TRACE_MARKER="FORGE TRACE"

cmd_add() {
    local file="${1:?Usage: forge-trace-update.sh add <file> <req> <agent> <pr> <description>}"
    local req="${2:?Missing REQ tag}"
    local agent="${3:?Missing agent name}"
    local pr="${4:?Missing PR number}"
    local desc="${5:-}"
    local today
    today=$(date +%Y-%m-%d)

    if [ ! -f "$file" ]; then
        echo "File not found: $file"
        return 1
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
        # Count existing trace lines (lines after the marker, starting with comment char)
        local trace_count
        trace_count=$(awk "/$TRACE_MARKER/{found=1; next} found{print}" "$file" | grep -c "^${cc}" 2>/dev/null || echo "0")

        # If at max, remove oldest (first trace line after marker)
        if [ "$trace_count" -ge "$MAX_TRACE_LINES" ]; then
            # Remove the first trace entry (oldest) after the marker
            python3 -c "
lines = open('$file').readlines()
marker_idx = None
first_trace_idx = None
for i, line in enumerate(lines):
    if '$TRACE_MARKER' in line:
        marker_idx = i
    elif marker_idx is not None and first_trace_idx is None and line.strip().startswith('$cc'):
        first_trace_idx = i
        break
if first_trace_idx is not None:
    del lines[first_trace_idx]
    open('$file', 'w').writelines(lines)
"
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

cmd_init() {
    local file="${1:?Usage: forge-trace-update.sh init <file> <req> <agent>}"
    local req="${2:?Missing REQ tag}"
    local agent="${3:?Missing agent name}"
    local today
    today=$(date +%Y-%m-%d)

    if [ ! -f "$file" ]; then
        echo "File not found: $file"
        return 1
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

cmd_show() {
    local file="${1:?Usage: forge-trace-update.sh show <file>}"

    if [ ! -f "$file" ]; then
        echo "File not found: $file"
        return 1
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

    if grep -q "$TRACE_MARKER" "$file" 2>/dev/null; then
        local trace_count
        local cc
        cc=$(get_comment_char "$file")
        trace_count=$(awk "/$TRACE_MARKER/{found=1; next} found{print}" "$file" | grep -c "^${cc}" 2>/dev/null || echo "0")
        echo "PASS: $file has FORGE TRACE ($trace_count entries)"
        return 0
    else
        echo "FAIL: $file missing FORGE TRACE block"
        return 1
    fi
}

case "${1:-help}" in
    add)   shift; cmd_add "$@" ;;
    init)  shift; cmd_init "$@" ;;
    show)  shift; cmd_show "$@" ;;
    check) shift; cmd_check "$@" ;;
    *)
        echo "Forge Trace Update — in-file change history"
        echo ""
        echo "Usage: forge-trace-update.sh <command> [args]"
        echo ""
        echo "Commands:"
        echo "  add <file> <req> <agent> <pr> [desc]  Add trace entry"
        echo "  init <file> <req> <agent>             Create initial trace"
        echo "  show <file>                           Show trace block"
        echo "  check <file>                          Verify trace exists"
        ;;
esac
