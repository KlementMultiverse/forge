#!/usr/bin/env bats
# Tests for scripts/forge-deps.sh
# Verifies dependency checking for forge scripts

setup() {
    load '../../test_helper/common-setup'
    _common_setup
}

teardown() {
    _common_teardown
}

@test "forge-deps.sh exists and is executable" {
    assert [ -f "$FORGE_DIR/scripts/forge-deps.sh" ]
    assert [ -x "$FORGE_DIR/scripts/forge-deps.sh" ]
}

@test "forge-deps.sh defines check_forge_deps function" {
    source "$FORGE_DIR/scripts/forge-deps.sh"
    run type check_forge_deps
    assert_success
    assert_output --partial "function"
}

@test "check_forge_deps passes when deps are present" {
    source "$FORGE_DIR/scripts/forge-deps.sh"
    run check_forge_deps
    assert_success
}
