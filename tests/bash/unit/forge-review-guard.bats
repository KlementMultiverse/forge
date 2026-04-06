#!/usr/bin/env bats
# Tests for scripts/forge-review-guard.sh
# Verifies review-before-gate enforcement

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    setup_mock_git_repo
    export PROJECT_ROOT="$TEST_PROJECT"
    export D="$TEST_PROJECT"
}

teardown() {
    _common_teardown
}

@test "review-guard help shows commands" {
    run bash "$FORGE_DIR/scripts/forge-review-guard.sh" help
    assert_output --partial "mark-reviewed"
    assert_output --partial "check-reviewed"
}

@test "review-guard check-for-gate fails without review" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-review-guard.sh" check-for-gate
    assert_failure
}

@test "review-guard mark-reviewed creates marker" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-review-guard.sh" mark-reviewed
    assert_success
}

@test "review-guard status shows current state" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-review-guard.sh" status
    assert_success
}

@test "review-guard check-for-gate passes after mark-reviewed" {
    cd "$TEST_PROJECT"
    bash "$FORGE_DIR/scripts/forge-review-guard.sh" mark-reviewed
    run bash "$FORGE_DIR/scripts/forge-review-guard.sh" check-for-gate
    assert_success
}

@test "review-guard reset clears review status" {
    cd "$TEST_PROJECT"
    bash "$FORGE_DIR/scripts/forge-review-guard.sh" mark-reviewed
    bash "$FORGE_DIR/scripts/forge-review-guard.sh" reset
    run bash "$FORGE_DIR/scripts/forge-review-guard.sh" check-for-gate
    assert_failure
}
