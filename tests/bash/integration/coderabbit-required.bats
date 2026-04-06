#!/usr/bin/env bats
# Tests: CodeRabbit is required, not optional

setup() {
    load '../../test_helper/common-setup'
    _common_setup
}

teardown() {
    _common_teardown
}

@test "README lists CodeRabbit as Required not Optional" {
    run grep -i "required.*coderabbit\|coderabbit.*required" "$FORGE_DIR/README.md"
    assert_success
}

@test "README does NOT say CodeRabbit is Optional" {
    run grep -i "optional.*coderabbit" "$FORGE_DIR/README.md"
    assert_failure
}

@test "gate command checks CodeRabbit approval" {
    run grep -i "coderabbit\|CodeRabbit" "$FORGE_DIR/commands/gate.md"
    assert_success
}

@test "SessionStart hook mentions CodeRabbit setup" {
    run grep -i "coderabbit\|code.rabbit" "$FORGE_DIR/templates/hooks.json"
    assert_success
}
