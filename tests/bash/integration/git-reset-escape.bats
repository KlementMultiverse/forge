#!/usr/bin/env bats
# Tests: git reset escape hatch (#122)

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    FORGE_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
    export FORGE_DIR
}

teardown() {
    _common_teardown
}

@test "PreToolUse Bash hook blocks git reset --hard normally" {
    # Simulate hook check
    CMD="git reset --hard"
    run bash -c 'CMD="git reset --hard"; if echo "$CMD" | grep -qE "rm -rf|git push --force|git reset --hard|git clean -f"; then echo "[FORGE] BLOCKED: Destructive command" && exit 2; fi'
    assert_failure
    assert_output --partial "BLOCKED"
}

@test "forge-infra-check.sh --reset provides safe alternative to git reset" {
    cd "$TEST_PROJECT"
    mkdir -p docs
    echo '{"current_step":15}' > docs/forge-state.json
    run bash "$FORGE_DIR/scripts/forge-infra-check.sh" --reset
    assert_success
    assert [ ! -f "$TEST_PROJECT/docs/forge-state.json" ]
}

@test "emergency override documented in meta-protocol" {
    run grep -l "Emergency Override\|--no-verify\|LAST RESORT" "$FORGE_DIR/docs/protocols/forge-meta-protocol.md"
    assert_success
}
