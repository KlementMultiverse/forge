#!/usr/bin/env bats
# Tests for forge-flex-detect.sh — FLEX_SIGNAL detection in agent output
# Related: #202, CR plan Phase 2 Task 2.1

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    FORGE_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
    export FORGE_DIR
    SCRIPT="$FORGE_DIR/scripts/forge-flex-detect.sh"
    TEST_DIR=$(mktemp -d)
}

teardown() {
    _common_teardown
    rm -rf "$TEST_DIR"
}

# ─── SCRIPT EXISTS ───

@test "forge-flex-detect.sh exists and is executable" {
    assert [ -f "$SCRIPT" ]
    assert [ -x "$SCRIPT" ]
}

@test "forge-flex-detect.sh has help" {
    run "$SCRIPT" --help
    assert_success
    assert_output --partial "Usage"
}

# ─── SIGNAL DETECTION ───

@test "detects FLEX_SIGNAL in output file" {
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
Some agent output here.

## FLEX_SIGNAL
TYPE: AMEND_RULES
TARGET: CLAUDE.md
STEP: S3
WHAT: Rule contradicts FastAPI choice
WHY: CLAUDE.md says "use Django Ninja" but stack is FastAPI
PROPOSED: Remove Django Ninja reference
SEVERITY: BLOCKING
SIGNAL
    run "$SCRIPT" "$TEST_DIR/output.md"
    assert_success
    assert_output --partial "AMEND_RULES"
    assert_output --partial "BLOCKING"
}

@test "returns exit 1 when no FLEX_SIGNAL present" {
    echo "Clean agent output, no issues found." > "$TEST_DIR/output.md"
    run "$SCRIPT" "$TEST_DIR/output.md"
    [ "$status" -eq 1 ]
}

@test "returns exit 2 on missing file" {
    run "$SCRIPT" "$TEST_DIR/nonexistent.md"
    [ "$status" -eq 2 ]
}

# ─── ALL SIGNAL TYPES ───

@test "detects all 10 TYPE values" {
    for type in AMEND_RULES UPDATE_SPEC FIX_DESIGN FIX_ROUTING FIX_SCAFFOLD ADD_SECURITY SPAWN_AGENT UPDATE_TESTS LOOP_BACK DEEP_REVIEW; do
        cat > "$TEST_DIR/output.md" <<SIGNAL
## FLEX_SIGNAL
TYPE: $type
TARGET: test.md
STEP: N0
WHAT: test
WHY: test
PROPOSED: test
SEVERITY: INFO
SIGNAL
        run "$SCRIPT" "$TEST_DIR/output.md"
        assert_success
        assert_output --partial "$type"
    done
}

# ─── SEVERITY LEVELS ───

@test "detects INFO severity" {
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
## FLEX_SIGNAL
TYPE: AMEND_RULES
TARGET: CLAUDE.md
STEP: N4
WHAT: Minor style inconsistency
WHY: Not critical
PROPOSED: Adjust later
SEVERITY: INFO
SIGNAL
    run "$SCRIPT" "$TEST_DIR/output.md"
    assert_success
    assert_output --partial "INFO"
}

@test "detects ADVISORY severity" {
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
## FLEX_SIGNAL
TYPE: UPDATE_SPEC
TARGET: SPEC.md
STEP: N3
WHAT: Missing edge case
WHY: Test revealed gap
PROPOSED: Add REQ
SEVERITY: ADVISORY
SIGNAL
    run "$SCRIPT" "$TEST_DIR/output.md"
    assert_success
    assert_output --partial "ADVISORY"
}

@test "detects BLOCKING severity" {
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
## FLEX_SIGNAL
TYPE: FIX_DESIGN
TARGET: docs/design-doc.md
STEP: N0
WHAT: API contract wrong
WHY: Endpoint returns 404
PROPOSED: Fix contract
SEVERITY: BLOCKING
SIGNAL
    run "$SCRIPT" "$TEST_DIR/output.md"
    assert_success
    assert_output --partial "BLOCKING"
}

# ─── JSON OUTPUT ───

@test "supports --json flag" {
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
## FLEX_SIGNAL
TYPE: AMEND_RULES
TARGET: CLAUDE.md
STEP: S3
WHAT: Rule conflict
WHY: Evidence here
PROPOSED: Fix it
SEVERITY: BLOCKING
SIGNAL
    run "$SCRIPT" --json "$TEST_DIR/output.md"
    assert_success
    # Should be valid JSON
    echo "$output" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null
    assert [ $? -eq 0 ]
}

# ─── SEVERITY FILTER ───

@test "supports --severity-filter flag" {
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
## FLEX_SIGNAL
TYPE: AMEND_RULES
TARGET: CLAUDE.md
STEP: S3
WHAT: Rule conflict
WHY: Evidence
PROPOSED: Fix
SEVERITY: INFO
SIGNAL
    run "$SCRIPT" --severity-filter BLOCKING "$TEST_DIR/output.md"
    # INFO signal filtered out when asking for BLOCKING only
    [ "$status" -eq 1 ]
}

# ─── MULTIPLE SIGNALS ───

@test "detects multiple FLEX_SIGNALs in one output" {
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
Agent output here.

## FLEX_SIGNAL
TYPE: AMEND_RULES
TARGET: CLAUDE.md
STEP: S3
WHAT: Rule 1 wrong
WHY: Evidence 1
PROPOSED: Fix 1
SEVERITY: BLOCKING

More output.

## FLEX_SIGNAL
TYPE: UPDATE_SPEC
TARGET: SPEC.md
STEP: S4
WHAT: Missing REQ
WHY: Evidence 2
PROPOSED: Add REQ
SEVERITY: ADVISORY
SIGNAL
    run "$SCRIPT" "$TEST_DIR/output.md"
    assert_success
    assert_output --partial "AMEND_RULES"
    assert_output --partial "UPDATE_SPEC"
}

# ─── MALFORMED SIGNALS ───

@test "handles malformed signal gracefully" {
    cat > "$TEST_DIR/output.md" <<'SIGNAL'
## FLEX_SIGNAL
TYPE: AMEND_RULES
TARGET:
SEVERITY:
SIGNAL
    run "$SCRIPT" "$TEST_DIR/output.md"
    # Should detect but report as malformed
    assert_output --partial "AMEND_RULES"
}

# ─── DESIGN RULES IN LOOP FILE ───

@test "universal-agent-loop.md has 13 steps" {
    run grep -E "^[0-9]+\." "$FORGE_DIR/rules/universal-agent-loop.md"
    assert_success
    run grep "13\\. PROCEED" "$FORGE_DIR/rules/universal-agent-loop.md"
    assert_success
}

@test "step 11 is FLEX CHECKPOINT" {
    run grep "11\\. FLEX CHECKPOINT" "$FORGE_DIR/rules/universal-agent-loop.md"
    assert_success
}

@test "FLEX_SIGNAL format defined in loop file" {
    run grep "## FLEX_SIGNAL" "$FORGE_DIR/rules/universal-agent-loop.md"
    assert_success
}

@test "decision authority table has all 10 types" {
    for type in AMEND_RULES UPDATE_SPEC FIX_DESIGN FIX_ROUTING FIX_SCAFFOLD ADD_SECURITY SPAWN_AGENT UPDATE_TESTS DEEP_REVIEW; do
        run grep "$type" "$FORGE_DIR/rules/universal-agent-loop.md"
        assert_success
    done
}

@test "safety limits defined" {
    run grep -E "5.*per signal|10.*per step|30.*per phase" "$FORGE_DIR/rules/universal-agent-loop.md"
    assert_success
}

@test "Gate 3 is FLAT (no recursive step 11)" {
    run grep -i "FLAT.*loop\|NO recursive" "$FORGE_DIR/rules/universal-agent-loop.md"
    assert_success
}

@test "signal identity is TYPE + TARGET" {
    run grep -E "Signal identity.*TYPE.*TARGET|identity.*TYPE.*TARGET" "$FORGE_DIR/rules/universal-agent-loop.md"
    assert_success
}
