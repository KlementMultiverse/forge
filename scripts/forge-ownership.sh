#!/bin/bash
# Forge Ownership — per-directory code ownership tracking
# Chromium-style OWNERS files: agent, requirements, reviewer
#
# Usage:
#   forge-ownership.sh check              — show all ownership
#   forge-ownership.sh orphans            — files without OWNERS
#   forge-ownership.sh who <file>         — who owns this file?
#   forge-ownership.sh reqs <agent>       — which REQs does agent own?
#   forge-ownership.sh create <dir> <agent> <reqs> — create OWNERS file
#
# Implements #41: Per-directory OWNERS files

set -uo pipefail

D="${PROJECT_ROOT:-$PWD}"

cmd_check() {
    echo "=== Code Ownership Report ==="
    echo ""

    local owners_count=0
    local total_reqs=0

    while IFS= read -r -d '' owners_file; do
        owners_count=$((owners_count + 1))
        local dir
        dir=$(dirname "$owners_file")
        local rel_dir
        rel_dir=$(python3 -c "import os; print(os.path.relpath('$dir', '$D'))")

        local agent=""
        local reqs=""
        local reviewer=""
        local created=""

        while IFS= read -r line; do
            case "$line" in
                agent:*)    agent="${line#agent: }" ;;
                requirements:*) reqs="${line#requirements: }" ;;
                reviewer:*) reviewer="${line#reviewer: }" ;;
                created:*)  created="${line#created: }" ;;
            esac
        done < <(grep -v '^#' "$owners_file" | grep -v '^$')

        local req_count=0
        if [ -n "$reqs" ]; then
            req_count=$(echo "$reqs" | tr ',' '\n' | wc -l)
            total_reqs=$((total_reqs + req_count))
        fi

        echo "  $rel_dir/"
        echo "    Agent:    ${agent:-unassigned}"
        echo "    REQs:     ${reqs:-none} ($req_count)"
        echo "    Reviewer: ${reviewer:-none}"
        echo ""
    done < <(find "$D" -name "OWNERS" -not -path "*/.venv/*" -not -path "*/.git/*" -not -path "*/__pycache__/*" -print0 2>/dev/null)

    echo "=== Summary ==="
    echo "  OWNERS files: $owners_count"
    echo "  Total REQs tracked: $total_reqs"

    if [ "$owners_count" -eq 0 ]; then
        echo ""
        echo "  No OWNERS files found. Create with:"
        echo "  forge-ownership.sh create <dir> <agent> <reqs>"
    fi
}

cmd_orphans() {
    echo "=== Orphan Files (no OWNERS) ==="
    echo ""

    local orphan_count=0

    # Find all .py files and check if their directory has an OWNERS file
    while IFS= read -r pyfile; do
        local dir
        dir=$(dirname "$pyfile")

        # Walk up directories looking for OWNERS
        local found=false
        local check_dir="$dir"
        while [ "$check_dir" != "$D" ] && [ "$check_dir" != "/" ]; do
            if [ -f "$check_dir/OWNERS" ]; then
                found=true
                break
            fi
            check_dir=$(dirname "$check_dir")
        done

        if ! $found; then
            local rel
            rel=$(python3 -c "import os; print(os.path.relpath('$pyfile', '$D'))")
            echo "  $rel"
            orphan_count=$((orphan_count + 1))
        fi
    done < <(find "$D" -name "*.py" -not -path "*/.venv/*" -not -path "*/.git/*" -not -path "*/__pycache__/*" -not -path "*/migration*/*" -print 2>/dev/null)

    echo ""
    echo "Orphan files: $orphan_count"
}

cmd_who() {
    local filepath="${1:?Usage: forge-ownership.sh who <file>}"

    # Resolve to absolute
    if [[ "$filepath" != /* ]]; then
        filepath="$D/$filepath"
    fi

    if [ ! -f "$filepath" ]; then
        echo "File not found: $filepath"
        return 1
    fi

    local dir
    dir=$(dirname "$filepath")
    local rel
    rel=$(python3 -c "import os; print(os.path.relpath('$filepath', '$D'))")

    # Walk up directories looking for OWNERS
    local check_dir="$dir"
    while [ "$check_dir" != "$D" ] && [ "$check_dir" != "/" ]; do
        if [ -f "$check_dir/OWNERS" ]; then
            local agent=""
            local reqs=""
            while IFS= read -r line; do
                case "$line" in
                    agent:*)        agent="${line#agent: }" ;;
                    requirements:*) reqs="${line#requirements: }" ;;
                esac
            done < <(grep -v '^#' "$check_dir/OWNERS" | grep -v '^$')

            local owners_rel
            owners_rel=$(python3 -c "import os; print(os.path.relpath('$check_dir', '$D'))")
            echo "File:  $rel"
            echo "Owner: ${agent:-unassigned}"
            echo "REQs:  ${reqs:-none}"
            echo "From:  $owners_rel/OWNERS"
            return 0
        fi
        check_dir=$(dirname "$check_dir")
    done

    echo "File:  $rel"
    echo "Owner: NONE (no OWNERS file found)"
    echo "Fix:   forge-ownership.sh create $(dirname "$rel") @agent-name REQ-xxx"
    return 1
}

cmd_reqs() {
    local target_agent="${1:?Usage: forge-ownership.sh reqs <agent>}"

    echo "=== REQs owned by $target_agent ==="
    echo ""

    local found=0
    while IFS= read -r -d '' owners_file; do
        local agent=""
        local reqs=""
        local dir
        dir=$(dirname "$owners_file")
        local rel_dir
        rel_dir=$(python3 -c "import os; print(os.path.relpath('$dir', '$D'))")

        while IFS= read -r line; do
            case "$line" in
                agent:*)        agent="${line#agent: }" ;;
                requirements:*) reqs="${line#requirements: }" ;;
            esac
        done < <(grep -v '^#' "$owners_file" | grep -v '^$')

        if [ "$agent" = "$target_agent" ]; then
            echo "  $rel_dir/: $reqs"
            found=$((found + 1))
        fi
    done < <(find "$D" -name "OWNERS" -not -path "*/.venv/*" -not -path "*/.git/*" -print0 2>/dev/null)

    echo ""
    echo "Directories owned: $found"
}

cmd_create() {
    local dir="${1:?Usage: forge-ownership.sh create <dir> <agent> <reqs>}"
    local agent="${2:?Missing agent name (e.g., @backend-architect)}"
    local reqs="${3:?Missing requirements (e.g., REQ-AUTH-001,REQ-AUTH-002)}"
    local today
    today=$(date +%Y-%m-%d)

    # Resolve path
    if [[ "$dir" != /* ]]; then
        dir="$D/$dir"
    fi

    mkdir -p "$dir"

    cat > "$dir/OWNERS" << EOF
# Forge OWNERS — code ownership for this directory
# Created by forge-ownership.sh
agent: $agent
requirements: $reqs
created: $today
last_verified: $today
EOF

    local rel_dir
    rel_dir=$(python3 -c "import os; print(os.path.relpath('$dir', '$D'))")
    echo "Created $rel_dir/OWNERS"
    echo "  Agent: $agent"
    echo "  REQs:  $reqs"
}

case "${1:-help}" in
    check)   cmd_check ;;
    orphans) cmd_orphans ;;
    who)     shift; cmd_who "$@" ;;
    reqs)    shift; cmd_reqs "$@" ;;
    create)  shift; cmd_create "$@" ;;
    *)
        echo "Forge Ownership — per-directory code ownership tracking"
        echo ""
        echo "Usage: forge-ownership.sh <command> [args]"
        echo ""
        echo "Commands:"
        echo "  check              Show all ownership"
        echo "  orphans            Find files without OWNERS"
        echo "  who <file>         Who owns this file?"
        echo "  reqs <agent>       Which REQs does agent own?"
        echo "  create <dir> <agent> <reqs>  Create OWNERS file"
        ;;
esac
