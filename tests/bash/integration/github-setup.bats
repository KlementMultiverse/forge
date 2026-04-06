#!/usr/bin/env bats
# Tests for GitHub setup guidance in SessionStart hook

setup() {
    load '../../test_helper/common-setup'
    _common_setup
}

teardown() {
    _common_teardown
}

@test "SessionStart hook checks for gh CLI availability" {
    run grep -E "command -v gh|which gh|gh.*not found|gh.*install" "$FORGE_DIR/templates/hooks.json"
    assert_success
}

@test "SessionStart hook checks for gh authentication" {
    run grep -E "gh auth|auth.*status|authenticated|login" "$FORGE_DIR/templates/hooks.json"
    assert_success
}

@test "SessionStart hook provides install link for gh CLI" {
    run grep "cli.github.com" "$FORGE_DIR/templates/hooks.json"
    assert_success
}
