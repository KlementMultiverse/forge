#!/bin/bash
# Forge Test Guard — detect untested script changes
# Checks that every script has a corresponding test file
# and warns when scripts change without test updates.
#
# Usage:
#   forge-test-guard.sh              # full report
#   forge-test-guard.sh --changed    # only check git-changed scripts
#
# Implements #67

set -uo pipefail

FORGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$FORGE_DIR/scripts"
BASH_TESTS="$FORGE_DIR/tests/bash/unit"
INTEGRATION_TESTS="$FORGE_DIR/tests/bash/integration"
PY_TESTS="$FORGE_DIR/tests/python/unit"

TESTED=0
MISSING=0
TOTAL=0
STALE=0

echo "=== Forge Test Guard ==="
echo ""

# Check 1: Every .sh script has a .bats test
echo "--- Bash Scripts ---"
for script in "$SCRIPTS_DIR"/*.sh; do
    [ -f "$script" ] || continue
    TOTAL=$((TOTAL + 1))
    name=$(basename "$script" .sh)

    # Search in unit and integration tests
    test_file=$(find "$BASH_TESTS" "$INTEGRATION_TESTS" -name "*${name}*" -name "*.bats" 2>/dev/null | head -1)
    # Also match partial names (forge-observer for forge-observer-approve)
    if [ -z "$test_file" ]; then
        short_name="${name%-*}"
        test_file=$(find "$BASH_TESTS" "$INTEGRATION_TESTS" -name "*${short_name}*" -name "*.bats" 2>/dev/null | head -1)
    fi

    if [ -n "$test_file" ]; then
        TESTED=$((TESTED + 1))
        echo "  ✅ $name → $(basename "$test_file")"
    else
        MISSING=$((MISSING + 1))
        echo "  ❌ $name — NO TEST"
    fi
done

echo ""

# Check 2: Every .py script has a pytest file
echo "--- Python Scripts ---"
for script in "$SCRIPTS_DIR"/*.py; do
    [ -f "$script" ] || continue
    TOTAL=$((TOTAL + 1))
    name=$(basename "$script" .py)
    # Convert hyphens to underscores for pytest naming
    pytest_name=$(echo "$name" | tr '-' '_')

    test_file=$(find "$PY_TESTS" -name "*${pytest_name}*" -name "*.py" 2>/dev/null | head -1)

    if [ -n "$test_file" ]; then
        TESTED=$((TESTED + 1))
        echo "  ✅ $name → $(basename "$test_file")"
    else
        MISSING=$((MISSING + 1))
        echo "  ❌ $name — NO TEST"
    fi
done

echo ""

# Check 3: Script changed but test didn't (git diff, only if --changed flag)
if [ "${1:-}" = "--changed" ]; then
    echo "--- Changed Without Test Update ---"
    changed_scripts=$(git -C "$FORGE_DIR" diff --cached --name-only -- 'scripts/*.sh' 'scripts/*.py' 2>/dev/null)
    if [ -n "$changed_scripts" ]; then
        for script in $changed_scripts; do
            name=$(basename "$script" | sed 's/\.\(sh\|py\)$//')
            test_changed=$(git -C "$FORGE_DIR" diff --cached --name-only -- "tests/**/*${name}*" 2>/dev/null | head -1)
            if [ -z "$test_changed" ]; then
                echo "  ⚠️  $script changed but no test file was updated"
                STALE=$((STALE + 1))
            fi
        done
        if [ "$STALE" -eq 0 ]; then
            echo "  All changed scripts have test updates"
        fi
    else
        echo "  No staged script changes"
    fi
    echo ""
fi

# Summary
echo "=== Summary ==="
if [ "$TOTAL" -gt 0 ]; then
    COVERAGE=$((TESTED * 100 / TOTAL))
else
    COVERAGE=0
fi
echo "  Scripts: $TOTAL"
echo "  Tested:  $TESTED ($COVERAGE%)"
echo "  Missing: $MISSING"
if [ "$STALE" -gt 0 ]; then
    echo "  Stale:   $STALE (changed without test update)"
fi
echo ""

if [ "$MISSING" -eq 0 ] && [ "$STALE" -eq 0 ]; then
    echo "PASS: Full test coverage"
    exit 0
else
    echo "GAPS: $MISSING scripts without tests"
    exit 1
fi
