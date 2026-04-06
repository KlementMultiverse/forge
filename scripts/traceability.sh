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
SPEC_REQS=$(grep -oP '(?:\[REQ-\d+\]|REQ-[A-Z]+-\d+)' "$SPEC_FILE" | sort -u || echo "")
if [ -z "$SPEC_REQS" ]; then
    SPEC_COUNT=0
    echo "SPEC.md: 0 requirements found"
    echo ""
    echo "=== Summary ==="
    echo "Coverage:  0% (0/0 requirements have tests)"
    echo "Orphans:   0"
    echo "Missing tests: 0"
    echo "Missing code:  0"
    echo ""
    echo "WARN: No REQ tags found in SPEC.md. Supports [REQ-001] and REQ-AUTH-001 formats. Run /generate-spec or /specify to add them."
    exit 1
fi
SPEC_COUNT=$(echo "$SPEC_REQS" | wc -l)
echo "SPEC.md: $SPEC_COUNT requirements found"

# Find REQ tags in test files — search multiple common locations
TEST_REQS=""
for test_path in \
    "$PROJECT_ROOT/tests/" \
    "$PROJECT_ROOT/apps/*/tests.py" \
    "$PROJECT_ROOT/apps/*/tests/" \
    "$PROJECT_ROOT/*/tests.py" \
    "$PROJECT_ROOT/*/tests/"; do
    FOUND=$(grep -roPh '(?:\[REQ-\d+\]|REQ-[A-Z]+-\d+)' $test_path 2>/dev/null || true)
    if [ -n "$FOUND" ]; then
        TEST_REQS="$TEST_REQS
$FOUND"
    fi
done
TEST_REQS=$(echo "$TEST_REQS" | sort -u | grep 'REQ-' || echo "")
TEST_COUNT=$(echo "$TEST_REQS" | grep -c 'REQ-' || echo "0")
echo "Tests:   $TEST_COUNT requirements referenced"

# Find REQ tags in code files (excluding tests and spec) — search .py, .ts, .js
CODE_REQS=""
for ext in "*.py" "*.ts" "*.js"; do
    FOUND=$(grep -roPh '(?:\[REQ-\d+\]|REQ-[A-Z]+-\d+)' "$PROJECT_ROOT" --include="$ext" --exclude="*test*" --exclude="*spec*" --exclude="SPEC.md" 2>/dev/null || true)
    if [ -n "$FOUND" ]; then
        CODE_REQS="$CODE_REQS
$FOUND"
    fi
done
CODE_REQS=$(echo "$CODE_REQS" | sort -u | grep 'REQ-' || echo "")
CODE_COUNT=$(echo "$CODE_REQS" | grep -c 'REQ-' || echo "0")
echo "Code:    $CODE_COUNT requirements referenced"

echo ""

# Check coverage: REQs in spec that have tests
MISSING_TESTS=0
MISSING_CODE=0
echo "--- Coverage Check ---"
for req in $SPEC_REQS; do
    HAS_TEST=$(echo "$TEST_REQS" | grep -cF "$req" 2>/dev/null || true)
    HAS_TEST="${HAS_TEST:-0}"
    HAS_TEST="${HAS_TEST//[^0-9]/}"
    [ -z "$HAS_TEST" ] && HAS_TEST=0
    HAS_CODE=$(echo "$CODE_REQS" | grep -cF "$req" 2>/dev/null || true)
    HAS_CODE="${HAS_CODE:-0}"
    HAS_CODE="${HAS_CODE//[^0-9]/}"
    [ -z "$HAS_CODE" ] && HAS_CODE=0

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
    IN_SPEC=$(echo "$SPEC_REQS" | grep -cF "$req" 2>/dev/null || true)
    IN_SPEC="${IN_SPEC:-0}"
    IN_SPEC="${IN_SPEC//[^0-9]/}"
    [ -z "$IN_SPEC" ] && IN_SPEC=0
    if [ "$IN_SPEC" = "0" ] && [ -n "$req" ]; then
        echo "  ORPHAN: $req (in tests/code but not in spec)"
        ORPHANS=$((ORPHANS + 1))
    fi
done

echo ""

# Check: all REQs from docs/requirements.md are in SPEC.md
if [ -f "$PROJECT_ROOT/docs/requirements.md" ]; then
    echo "--- Requirements Traceability Check ---"
    REQ_IN_REQS=$(grep -oP '(?:\[REQ-\d+\]|REQ-[A-Z]+-\d+)' "$PROJECT_ROOT/docs/requirements.md" | sort -u || echo "")
    REQ_IN_SPEC=$(grep -oP '(?:\[REQ-\d+\]|REQ-[A-Z]+-\d+)' "$SPEC_FILE" | sort -u || echo "")
    MISSING_FROM_SPEC=$(comm -23 <(echo "$REQ_IN_REQS") <(echo "$REQ_IN_SPEC"))
    if [ -n "$MISSING_FROM_SPEC" ]; then
        echo "  WARNING: REQs in docs/requirements.md but MISSING from SPEC.md:"
        echo "$MISSING_FROM_SPEC" | while read -r req; do echo "    $req"; done
        MISSING_TESTS=$((MISSING_TESTS + $(echo "$MISSING_FROM_SPEC" | wc -l)))
    else
        echo "  All REQs from docs/requirements.md are present in SPEC.md"
    fi
    echo ""
fi

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
