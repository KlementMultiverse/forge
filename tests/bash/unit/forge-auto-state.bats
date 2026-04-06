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
    # forge-auto-state.sh takes positional args: $1=skill $2=agent
    bash "$FORGE_DIR/scripts/forge-auto-state.sh" "discover" "" 2>/dev/null || true
    run python3 -c "import json; d=json.load(open('docs/forge-state.json')); print(d.get('current_step', 0))"
    assert_output "1"
}

@test "auto-state maps gate skill to step 8" {
    cd "$TEST_PROJECT"
    bash "$FORGE_DIR/scripts/forge-auto-state.sh" "gate" "" "phase-0" 2>/dev/null || true
    run python3 -c "import json; d=json.load(open('docs/forge-state.json')); print(d.get('current_step', 0))"
    assert_output "8"
}
