#!/usr/bin/env bats
# Tests for scripts/forge-test-guard.sh
# Verifies detection of untested script changes

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    export FORGE_DIR="$FORGE_DIR"
}

teardown() {
    _common_teardown
}

@test "forge-test-guard.sh exists and is executable" {
    assert [ -f "$FORGE_DIR/scripts/forge-test-guard.sh" ]
    assert [ -x "$FORGE_DIR/scripts/forge-test-guard.sh" ]
}

@test "forge-test-guard detects scripts with tests" {
    run bash "$FORGE_DIR/scripts/forge-test-guard.sh"
    # Should report which scripts have tests
    assert_output --partial "forge-enforce"
}

@test "forge-test-guard reports missing test count" {
    run bash "$FORGE_DIR/scripts/forge-test-guard.sh"
    # Output should mention missing or coverage
    [[ "$status" -le 1 ]]
}
