#!/usr/bin/env bats
# Tests that all protocol documents exist and have proper structure

setup() {
    load '../../test_helper/common-setup'
    _common_setup
}

teardown() {
    _common_teardown
}

@test "component-creation protocol exists" {
    assert [ -f "$FORGE_DIR/docs/protocols/component-creation.md" ]
}

@test "error-handling protocol exists" {
    assert [ -f "$FORGE_DIR/docs/protocols/error-handling.md" ]
}

@test "component-creation has all 6 protocol sections" {
    local file="$FORGE_DIR/docs/protocols/component-creation.md"
    run grep -c "## Protocol:" "$file"
    [[ "$output" -ge 6 ]]
}

@test "component-creation has anti-patterns section" {
    run grep "Anti-Patterns" "$FORGE_DIR/docs/protocols/component-creation.md"
    assert_success
}

@test "component-creation has verification section" {
    run grep "Verification" "$FORGE_DIR/docs/protocols/component-creation.md"
    assert_success
}
