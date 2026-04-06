#!/usr/bin/env bats
# Tests for scripts/forge-triangle.sh
# Verifies SPEC ↔ TEST ↔ CODE triangle checking

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    export PROJECT_ROOT="$TEST_PROJECT"
    export D="$TEST_PROJECT"
}

teardown() {
    _common_teardown
}

@test "triangle help shows commands" {
    run bash "$FORGE_DIR/scripts/forge-triangle.sh" help
    assert_output --partial "check"
    assert_output --partial "check-req"
    assert_output --partial "tdd-check"
}

@test "triangle check fails without SPEC.md" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-triangle.sh" check
    assert_failure
    assert_output --partial "SPEC.md not found"
}

@test "triangle check shows SYNCED for complete triangle" {
    cd "$TEST_PROJECT"
    echo "REQ-AUTH-001 User login" > SPEC.md
    mkdir -p apps/auth
    echo '# REQ-AUTH-001 code' > apps/auth/models.py
    echo 'def test_x(): """REQ-AUTH-001"""' > apps/auth/tests.py
    run bash "$FORGE_DIR/scripts/forge-triangle.sh" check
    assert_success
    assert_output --partial "SYNCED"
}

@test "triangle check shows BROKEN for missing test" {
    cd "$TEST_PROJECT"
    echo "REQ-AUTH-001 User login" > SPEC.md
    mkdir -p apps/auth
    echo '# REQ-AUTH-001 code' > apps/auth/models.py
    run bash "$FORGE_DIR/scripts/forge-triangle.sh" check
    assert_failure
    assert_output --partial "BROKEN"
}

@test "triangle check shows ORPHAN for unspecced REQ" {
    cd "$TEST_PROJECT"
    echo "REQ-AUTH-001 Only this in spec" > SPEC.md
    mkdir -p apps/ghost
    echo '# REQ-GHOST-001 orphan' > apps/ghost/models.py
    run bash "$FORGE_DIR/scripts/forge-triangle.sh" check
    assert_failure
    assert_output --partial "ORPHAN"
}

@test "triangle check-req shows single REQ status" {
    cd "$TEST_PROJECT"
    echo "REQ-AUTH-001 User login" > SPEC.md
    mkdir -p apps/auth
    echo '# REQ-AUTH-001 code' > apps/auth/models.py
    run bash "$FORGE_DIR/scripts/forge-triangle.sh" check-req REQ-AUTH-001
    assert_output --partial "REQ-AUTH-001"
    assert_output --partial "SPEC"
}

@test "triangle tdd-check fails without test file" {
    cd "$TEST_PROJECT"
    mkdir -p apps/auth
    run bash "$FORGE_DIR/scripts/forge-triangle.sh" tdd-check auth
    assert_failure
    assert_output --partial "No test file"
}

@test "triangle tdd-check passes with test file" {
    cd "$TEST_PROJECT"
    mkdir -p apps/auth
    echo 'def test_something(): pass' > apps/auth/tests.py
    run bash "$FORGE_DIR/scripts/forge-triangle.sh" tdd-check auth
    assert_success
    assert_output --partial "PASS"
}
