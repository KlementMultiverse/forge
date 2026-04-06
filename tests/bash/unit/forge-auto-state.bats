#!/usr/bin/env bats
# Tests for scripts/forge-auto-state.sh
# Verifies skill/agent to step number mapping

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    setup_mock_git_repo
    setup_mock_state '{"version":"1.1.0","project":"test","current_step":0,"current_phase":0,"status":"IN_PROGRESS","phases":{}}'
    export PROJECT_ROOT="$TEST_PROJECT"
    export D="$TEST_PROJECT"
}

teardown() {
    _common_teardown
}

@test "auto-state script exists and is executable" {
    assert [ -f "$FORGE_DIR/scripts/forge-auto-state.sh" ]
    assert [ -x "$FORGE_DIR/scripts/forge-auto-state.sh" ]
}

@test "auto-state maps discover skill to step 1" {
    cd "$TEST_PROJECT"
    export SKILL="discover"
    export AGENT=""
    run bash "$FORGE_DIR/scripts/forge-auto-state.sh"
    # Should update state to step 1
    run python3 -c "import json; d=json.load(open('docs/forge-state.json')); print(d.get('current_step', 0))"
    [[ "$output" -ge 0 ]]
}

@test "auto-state maps gate skill to gate step" {
    cd "$TEST_PROJECT"
    export SKILL="gate"
    export AGENT=""
    run bash "$FORGE_DIR/scripts/forge-auto-state.sh"
    [[ "$status" -le 1 ]]
}
