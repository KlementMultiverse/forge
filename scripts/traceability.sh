#!/bin/bash
# Forge Traceability Check
# Scans [REQ-xxx] tags across spec, tests, and code
# Reports: coverage, orphans, drift

set -e

PROJECT_ROOT="${1:-.}"
SPEC_FILE="$PROJECT_ROOT/SPEC.md"

if [ ! -f "$SPEC_FILE" ]; then
    echo "ERROR: SPEC.md not found at $SPEC_FILE"
    exit 1
fi

echo "=== Forge Traceability Report ==="
echo ""

# Extract all REQ tags from spec
SPEC_REQS=$(grep -oP '\[REQ-\d+\]' "$SPEC_FILE" | sort -u)
SPEC_COUNT=$(echo "$SPEC_REQS" | wc -l)
echo "SPEC.md: $SPEC_COUNT requirements found"

# Find REQ tags in test files
TEST_REQS=$(grep -roPh '\[REQ-\d+\]' "$PROJECT_ROOT/tests/" "$PROJECT_ROOT/apps/*/tests.py" 2>/dev/null | sort -u || echo "")
TEST_COUNT=$(echo "$TEST_REQS" | grep -c '\[REQ' || echo "0")
echo "Tests:   $TEST_COUNT requirements referenced"

# Find REQ tags in code files (excluding tests and spec)
CODE_REQS=$(grep -roPh '\[REQ-\d+\]' "$PROJECT_ROOT/apps/" --include="*.py" --exclude="*test*" 2>/dev/null | sort -u || echo "")
CODE_COUNT=$(echo "$CODE_REQS" | grep -c '\[REQ' || echo "0")
echo "Code:    $CODE_COUNT requirements referenced"

echo ""

# Check coverage: REQs in spec that have tests
MISSING_TESTS=0
MISSING_CODE=0
echo "--- Coverage Check ---"
for req in $SPEC_REQS; do
    HAS_TEST=$(echo "$TEST_REQS" | grep -c "$req" || echo "0")
    HAS_CODE=$(echo "$CODE_REQS" | grep -c "$req" || echo "0")

    if [ "$HAS_TEST" = "0" ]; then
        echo "  MISSING TEST: $req"
        MISSING_TESTS=$((MISSING_TESTS + 1))
    fi
    if [ "$HAS_CODE" = "0" ]; then
        echo "  MISSING CODE: $req"
        MISSING_CODE=$((MISSING_CODE + 1))
    fi
done

# Check orphans: REQs in tests/code that aren't in spec
echo ""
echo "--- Orphan Check ---"
ORPHANS=0
for req in $TEST_REQS $CODE_REQS; do
    IN_SPEC=$(echo "$SPEC_REQS" | grep -c "$req" || echo "0")
    if [ "$IN_SPEC" = "0" ] && [ -n "$req" ]; then
        echo "  ORPHAN: $req (in tests/code but not in spec)"
        ORPHANS=$((ORPHANS + 1))
    fi
done

echo ""
echo "=== Summary ==="
COVERED=$((SPEC_COUNT - MISSING_TESTS))
if [ "$SPEC_COUNT" -gt 0 ]; then
    COVERAGE=$((COVERED * 100 / SPEC_COUNT))
else
    COVERAGE=0
fi
echo "Coverage:  $COVERAGE% ($COVERED/$SPEC_COUNT requirements have tests)"
echo "Orphans:   $ORPHANS"
echo "Missing tests: $MISSING_TESTS"
echo "Missing code:  $MISSING_CODE"

if [ "$COVERAGE" = "100" ] && [ "$ORPHANS" = "0" ]; then
    echo ""
    echo "PASS: Full traceability achieved"
    exit 0
else
    echo ""
    echo "FAIL: Traceability gaps found"
    exit 1
fi
