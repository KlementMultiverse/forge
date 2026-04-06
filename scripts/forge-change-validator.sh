#!/bin/bash
# Forge Change Validator — automatic protocol enforcement
# Runs ALL checks needed before/after any forge component change.
# Called by hooks and can be run manually.
#
# Usage:
#   forge-change-validator.sh pre-edit <file>     — run before editing a file
#   forge-change-validator.sh post-edit <file>     — run after editing a file
#   forge-change-validator.sh pre-commit           — run before committing
#   forge-change-validator.sh post-merge           — run after merging
#   forge-change-validator.sh full-check           — run all checks

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
D="${PROJECT_ROOT:-$PWD}"
FORGE_DIR="${FORGE_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"

cmd_pre_edit() {
    local file="${1:?Usage: forge-change-validator.sh pre-edit <file>}"
    echo "[FORGE-VALIDATE] Pre-edit checks for $file"

    # 1. Impact analysis
    if [ -f "$FORGE_DIR/scripts/forge-registry.py" ]; then
        local impact
        impact=$(python3 "$FORGE_DIR/scripts/forge-registry.py" --impact "$file" --json 2>/dev/null)
        if [ -n "$impact" ]; then
            local is_global
            is_global=$(echo "$impact" | python3 -c "import json,sys; print(json.load(sys.stdin).get('is_global_short_circuit', False))" 2>/dev/null)
            if [ "$is_global" = "True" ]; then
                echo "[FORGE-VALIDATE] !! GLOBAL SHORT-CIRCUIT: This file affects ALL projects"
            fi
            local dep_count
            dep_count=$(echo "$impact" | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('dependents', [])))" 2>/dev/null)
            if [ "$dep_count" -gt 0 ]; then
                echo "[FORGE-VALIDATE] $dep_count reverse dependents affected"
            fi
        fi
    fi

    # 2. Ownership check
    if [ -f "$FORGE_DIR/scripts/forge-ownership.sh" ]; then
        bash "$FORGE_DIR/scripts/forge-ownership.sh" who "$file" 2>/dev/null | grep -v "^$" | sed 's/^/[FORGE-VALIDATE] /'
    fi

    # 3. REQ tags in file
    if [ -f "$file" ]; then
        local reqs
        reqs=$(grep -oP '(?:\[REQ-\d+\]|REQ-[A-Z]+-\d+)' "$file" 2>/dev/null | sort -u | tr '\n' ', ' | sed 's/,$//')
        if [ -n "$reqs" ]; then
            echo "[FORGE-VALIDATE] REQs served: $reqs"
        fi
    fi

    # 4. Suspect REQs
    if [ -f "$FORGE_DIR/scripts/forge-enforce.sh" ]; then
        bash "$FORGE_DIR/scripts/forge-enforce.sh" check-suspect 2>/dev/null | grep -v "^$" | sed 's/^/[FORGE-VALIDATE] /'
    fi
}

cmd_post_edit() {
    local file="${1:?Usage: forge-change-validator.sh post-edit <file>}"
    echo "[FORGE-VALIDATE] Post-edit checks for $file"

    # 1. Is this a new component file?
    local is_component=false
    case "$file" in
        agents/*|commands/*|scripts/*|templates/*|rules/*)
            is_component=true
            ;;
    esac

    if $is_component; then
        # Check if test exists
        local name
        name=$(basename "$file" | sed 's/\.\(sh\|py\|md\)$//')
        local has_test
        has_test=$(find "$FORGE_DIR/tests" -name "*${name}*" 2>/dev/null | head -1)
        if [ -z "$has_test" ]; then
            echo "[FORGE-VALIDATE] WARNING: No test found for $name"
            echo "[FORGE-VALIDATE] Create test before using this component"
        fi
    fi

    # 2. Triangle check (if file has REQ tags)
    if [ -f "$file" ] && grep -qP '(?:\[REQ-\d+\]|REQ-[A-Z]+-\d+)' "$file" 2>/dev/null; then
        if [ -f "$D/SPEC.md" ] && [ -f "$FORGE_DIR/scripts/forge-triangle.sh" ]; then
            echo "[FORGE-VALIDATE] Checking triangle sync..."
            bash "$FORGE_DIR/scripts/forge-triangle.sh" check 2>/dev/null | tail -3 | sed 's/^/[FORGE-VALIDATE] /'
        fi
    fi

    # 3. FORGE TRACE reminder
    if [ -f "$file" ] && grep -q "FORGE TRACE" "$file" 2>/dev/null; then
        echo "[FORGE-VALIDATE] Remember to update FORGE TRACE block"
    fi
}

cmd_pre_commit() {
    echo "[FORGE-VALIDATE] Pre-commit checks"
    local errors=0

    # 1. REQ impact check (delegated to req-impact-check.py)
    if [ -f "$FORGE_DIR/scripts/req-impact-check.py" ]; then
        python3 "$FORGE_DIR/scripts/req-impact-check.py" --staged --update-state 2>/dev/null
        if [ $? -ne 0 ]; then
            errors=$((errors + 1))
        fi
    fi

    # 2. Test guard
    if [ -f "$FORGE_DIR/scripts/forge-test-guard.sh" ]; then
        bash "$FORGE_DIR/scripts/forge-test-guard.sh" --changed 2>/dev/null | grep "⚠️" | sed 's/^/[FORGE-VALIDATE] /'
    fi

    # 3. Suspect REQs
    if [ -f "$FORGE_DIR/scripts/forge-enforce.sh" ]; then
        bash "$FORGE_DIR/scripts/forge-enforce.sh" check-suspect 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "[FORGE-VALIDATE] WARNING: Unverified suspect REQs exist"
        fi
    fi

    return $errors
}

cmd_post_merge() {
    echo "[FORGE-VALIDATE] Post-merge sync"

    # 1. README sync
    if [ -f "$FORGE_DIR/scripts/forge-readme-sync.sh" ]; then
        bash "$FORGE_DIR/scripts/forge-readme-sync.sh" --fix 2>/dev/null | tail -3
    fi

    # 2. Registry regeneration
    if [ -f "$FORGE_DIR/scripts/forge-registry.py" ]; then
        python3 "$FORGE_DIR/scripts/forge-registry.py" "$FORGE_DIR" 2>/dev/null | tail -3
    fi

    # 3. Lint check
    if [ -f "$FORGE_DIR/scripts/forge-lint.py" ]; then
        python3 "$FORGE_DIR/scripts/forge-lint.py" "$FORGE_DIR" 2>/dev/null | tail -3
    fi

    echo "[FORGE-VALIDATE] Post-merge sync complete"
}

cmd_full_check() {
    echo "=== FORGE FULL VALIDATION ==="
    local errors=0

    # 1. README sync
    echo ""
    echo "--- 1. README Sync ---"
    if bash "$FORGE_DIR/scripts/forge-readme-sync.sh" 2>/dev/null; then
        echo "  PASS"
    else
        echo "  DRIFT detected — run: forge-readme-sync.sh --fix"
        errors=$((errors + 1))
    fi

    # 2. Test coverage
    echo ""
    echo "--- 2. Test Coverage ---"
    bash "$FORGE_DIR/scripts/forge-test-guard.sh" 2>/dev/null; RC=$?; bash "$FORGE_DIR/scripts/forge-test-guard.sh" 2>/dev/null | tail -5; if [ $RC -ne 0 ]; then errors=$((errors + 1)); fi

    # 3. Suspect REQs
    echo ""
    echo "--- 3. Suspect REQs ---"
    bash "$FORGE_DIR/scripts/forge-enforce.sh" check-suspect 2>/dev/null || errors=$((errors + 1))

    # 4. Triangle (if SPEC exists)
    if [ -f "$D/SPEC.md" ]; then
        echo ""
        echo "--- 4. Triangle Sync ---"
        bash "$FORGE_DIR/scripts/forge-triangle.sh" check 2>/dev/null | tail -5 || errors=$((errors + 1))
    fi

    # 5. Lint
    echo ""
    echo "--- 5. Component Lint ---"
    python3 "$FORGE_DIR/scripts/forge-lint.py" "$FORGE_DIR" 2>/dev/null | tail -3

    echo ""
    echo "=== RESULT: $errors errors ==="
    return $errors
}

case "${1:-help}" in
    pre-edit)    shift; cmd_pre_edit "$@" ;;
    post-edit)   shift; cmd_post_edit "$@" ;;
    pre-commit)  cmd_pre_commit ;;
    post-merge)  cmd_post_merge ;;
    full-check)  cmd_full_check ;;
    *)
        echo "Forge Change Validator — automatic protocol enforcement"
        echo ""
        echo "Usage: forge-change-validator.sh <command> [args]"
        echo ""
        echo "Commands:"
        echo "  pre-edit <file>    Check before editing (impact, ownership, REQs)"
        echo "  post-edit <file>   Check after editing (tests, triangle, trace)"
        echo "  pre-commit         Check before committing (REQ impact, test-guard)"
        echo "  post-merge         Sync after merge (README, registry, lint)"
        echo "  full-check         Run ALL validation checks"
        ;;
esac
