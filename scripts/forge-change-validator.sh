#!/bin/bash
# Forge Change Validator — automatic protocol enforcement
# Runs checks before/after any forge component change.
# Called by hooks and can be run manually.
#
# Usage:
#   forge-change-validator.sh pre-edit <file>     — check before editing
#   forge-change-validator.sh post-edit <file>     — check after editing
#   forge-change-validator.sh pre-commit           — check before committing
#   forge-change-validator.sh post-merge           — sync after merging
#   forge-change-validator.sh full-check           — run all checks

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
D="${PROJECT_ROOT:-$PWD}"
FORGE_DIR="${FORGE_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"

cmd_pre_edit() {
    local file="${1:?Usage: forge-change-validator.sh pre-edit <file>}"

    # Resolve to absolute path if relative
    if [[ "$file" != /* ]]; then
        file="$D/$file"
    fi

    echo "[FORGE-VALIDATE] Pre-edit checks for $file"

    # 1. Impact analysis
    if [ -f "$FORGE_DIR/scripts/forge-registry.py" ]; then
        local impact
        impact=$(python3 "$FORGE_DIR/scripts/forge-registry.py" --impact "$file" --json 2>/dev/null || echo "")
        if [ -n "$impact" ]; then
            local is_global
            is_global=$(echo "$impact" | python3 -c "import json,sys; print(json.load(sys.stdin).get('is_global_short_circuit', False))" 2>/dev/null || echo "False")
            if [ "$is_global" = "True" ]; then
                echo "[FORGE-VALIDATE] !! GLOBAL SHORT-CIRCUIT: This file affects ALL projects"
            fi
            local dep_count
            dep_count=$(echo "$impact" | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('dependents', [])))" 2>/dev/null || echo "0")
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

    # Resolve to absolute path if relative
    if [[ "$file" != /* ]]; then
        file="$D/$file"
    fi

    echo "[FORGE-VALIDATE] Post-edit checks for $file"

    # 1. Is this a new component file?
    local rel_file
    rel_file=$(python3 -c "import os; print(os.path.relpath('$file', '$FORGE_DIR'))" 2>/dev/null || basename "$file")

    local is_component=false
    case "$rel_file" in
        agents/*|commands/*|scripts/*|templates/*|rules/*)
            is_component=true
            ;;
    esac

    if $is_component; then
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

    # 1. REQ impact check
    if [ -f "$FORGE_DIR/scripts/req-impact-check.py" ]; then
        python3 "$FORGE_DIR/scripts/req-impact-check.py" --staged --update-state
        local rc=$?
        if [ $rc -ne 0 ]; then
            errors=$((errors + 1))
        fi
    fi

    # 2. Test guard — check if changed scripts have test updates
    if [ -f "$FORGE_DIR/scripts/forge-test-guard.sh" ]; then
        local guard_output
        guard_output=$(bash "$FORGE_DIR/scripts/forge-test-guard.sh" --changed 2>/dev/null)
        local guard_rc=$?
        if echo "$guard_output" | grep -q "⚠️" 2>/dev/null; then
            echo "$guard_output" | grep "⚠️" | sed 's/^/[FORGE-VALIDATE] /'
            errors=$((errors + 1))
        fi
    fi

    # 3. Suspect REQs
    if [ -f "$FORGE_DIR/scripts/forge-enforce.sh" ]; then
        bash "$FORGE_DIR/scripts/forge-enforce.sh" check-suspect 2>/dev/null
        local suspect_rc=$?
        if [ $suspect_rc -ne 0 ]; then
            echo "[FORGE-VALIDATE] WARNING: Unverified suspect REQs exist"
            errors=$((errors + 1))
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
    if [ -f "$FORGE_DIR/scripts/forge-readme-sync.sh" ]; then
        if bash "$FORGE_DIR/scripts/forge-readme-sync.sh" 2>/dev/null; then
            echo "  PASS"
        else
            echo "  DRIFT detected — run: forge-readme-sync.sh --fix"
            errors=$((errors + 1))
        fi
    else
        echo "  SKIP (forge-readme-sync.sh not found)"
    fi

    # 2. Test coverage
    echo ""
    echo "--- 2. Test Coverage ---"
    if [ -f "$FORGE_DIR/scripts/forge-test-guard.sh" ]; then
        bash "$FORGE_DIR/scripts/forge-test-guard.sh" 2>/dev/null | tail -5
        local guard_rc=${PIPESTATUS[0]:-$?}
        if [ $guard_rc -ne 0 ]; then
            errors=$((errors + 1))
        fi
    else
        echo "  SKIP (forge-test-guard.sh not found)"
    fi

    # 3. Suspect REQs
    echo ""
    echo "--- 3. Suspect REQs ---"
    if [ -f "$FORGE_DIR/scripts/forge-enforce.sh" ]; then
        bash "$FORGE_DIR/scripts/forge-enforce.sh" check-suspect 2>/dev/null || errors=$((errors + 1))
    else
        echo "  SKIP (forge-enforce.sh not found)"
    fi

    # 4. Triangle (if SPEC exists)
    if [ -f "$D/SPEC.md" ]; then
        echo ""
        echo "--- 4. Triangle Sync ---"
        if [ -f "$FORGE_DIR/scripts/forge-triangle.sh" ]; then
            bash "$FORGE_DIR/scripts/forge-triangle.sh" check 2>/dev/null | tail -5 || errors=$((errors + 1))
        fi
    fi

    # 5. Lint
    echo ""
    echo "--- 5. Component Lint ---"
    if [ -f "$FORGE_DIR/scripts/forge-lint.py" ]; then
        python3 "$FORGE_DIR/scripts/forge-lint.py" "$FORGE_DIR" 2>/dev/null | tail -3
    else
        echo "  SKIP (forge-lint.py not found)"
    fi

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
