#!/usr/bin/env bats
# Tests for scripts/forge-readme-sync.sh

setup() {
    load '../../test_helper/common-setup'
    _common_setup
}

teardown() {
    _common_teardown
}

@test "forge-readme-sync.sh exists and is executable" {
    assert [ -f "$FORGE_DIR/scripts/forge-readme-sync.sh" ]
    assert [ -x "$FORGE_DIR/scripts/forge-readme-sync.sh" ]
}

@test "forge-readme-sync reports counts" {
    run bash "$FORGE_DIR/scripts/forge-readme-sync.sh"
    assert_output --partial "Agents"
    assert_output --partial "Commands"
    assert_output --partial "Scripts"
}

@test "forge-readme-sync passes when README is in sync" {
    run bash "$FORGE_DIR/scripts/forge-readme-sync.sh"
    assert_success
    assert_output --partial "PASS"
}
