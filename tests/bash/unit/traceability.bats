#!/usr/bin/env bats
# Tests for scripts/traceability.sh
# Verifies REQ tag scanning across SPEC, tests, and code

setup() {
    load '../../test_helper/common-setup'
    _common_setup
}

teardown() {
    _common_teardown
}

# ─── Basic Operation ───

@test "traceability fails without SPEC.md" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/traceability.sh" "$TEST_PROJECT"
    assert_failure
    assert_output --partial "SPEC.md not found"
}

@test "traceability reports 0 REQs for empty spec" {
    cd "$TEST_PROJECT"
    echo "# Empty Spec" > SPEC.md
    run bash "$FORGE_DIR/scripts/traceability.sh" "$TEST_PROJECT"
    assert_failure
    assert_output --partial "0 requirements found"
}

# ─── REQ Format Support (unified regex — issue #40) ───

@test "traceability finds bracket format [REQ-001]" {
    cd "$TEST_PROJECT"
    echo "[REQ-001] Test requirement" > SPEC.md
    setup_mock_test "auth" "REQ-001"
    setup_mock_code "auth" "REQ-001"
    run bash "$FORGE_DIR/scripts/traceability.sh" "$TEST_PROJECT"
    assert_output --partial "1 requirements found"
}

@test "traceability finds named format REQ-AUTH-001" {
    cd "$TEST_PROJECT"
    echo "REQ-AUTH-001 Test requirement" > SPEC.md
    setup_mock_test "auth" "REQ-AUTH-001"
    setup_mock_code "auth" "REQ-AUTH-001"
    run bash "$FORGE_DIR/scripts/traceability.sh" "$TEST_PROJECT"
    assert_output --partial "1 requirements found"
}

@test "traceability finds both formats in same spec" {
    cd "$TEST_PROJECT"
    cat > SPEC.md << 'EOF'
[REQ-001] Basic requirement
REQ-AUTH-001 Auth requirement
EOF
    run bash "$FORGE_DIR/scripts/traceability.sh" "$TEST_PROJECT"
    assert_output --partial "2 requirements found"
}

# ─── Coverage Checking ───

@test "traceability reports PASS with full coverage" {
    # Use a clean dir without copied forge scripts (they contain REQ tags)
    local CLEAN_DIR="$(mktemp -d)"
    echo "REQ-AUTH-001 User must login" > "$CLEAN_DIR/SPEC.md"
    mkdir -p "$CLEAN_DIR/apps/auth"
    echo '# REQ-AUTH-001 code' > "$CLEAN_DIR/apps/auth/models.py"
    echo 'def test_x(): """REQ-AUTH-001 test"""' > "$CLEAN_DIR/apps/auth/tests.py"
    run bash "$FORGE_DIR/scripts/traceability.sh" "$CLEAN_DIR"
    rm -rf "$CLEAN_DIR"
    assert_output --partial "PASS"
}

@test "traceability reports MISSING TEST when no test file exists" {
    cd "$TEST_PROJECT"
    echo "REQ-AUTH-001 User must login" > SPEC.md
    # Code exists but NO test file at all
    setup_mock_code "auth" "REQ-AUTH-001"
    run bash "$FORGE_DIR/scripts/traceability.sh" "$TEST_PROJECT"
    assert_failure
    assert_output --partial "MISSING TEST"
}

@test "traceability detects orphan REQs in code but not spec" {
    cd "$TEST_PROJECT"
    echo "REQ-AUTH-001 Only in spec" > SPEC.md
    # Create code with REQ not in spec (different REQ tag)
    mkdir -p apps/ghost
    echo '# REQ-GHOST-001 orphan code' > apps/ghost/models.py
    run bash "$FORGE_DIR/scripts/traceability.sh" "$TEST_PROJECT"
    assert_failure
    assert_output --partial "ORPHAN"
}
