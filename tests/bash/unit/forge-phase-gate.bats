#!/usr/bin/env bats
# Tests for scripts/forge-phase-gate.sh
# Verifies gate checking, approval status, circuit breaker

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    setup_mock_git_repo
    # Create forge-state.json for gate script
    mkdir -p "$TEST_PROJECT/docs/.approvals"
    setup_mock_state '{"version":"1.1.0","project":"test","current_step":8,"current_phase":0,"phases":{"0":{"status":"IN_PROGRESS"}},"gate_circuit":{"state":"CLOSED","poll_count":0,"cooldown_count":0,"last_poll_at":null,"cooldown_until":null,"last_response":null}}'
    export PROJECT_ROOT="$TEST_PROJECT"
    export D="$TEST_PROJECT"
}

teardown() {
    _common_teardown
}

# ─── status command ───

@test "phase-gate status runs without error" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-phase-gate.sh" status
    # May fail due to no gh CLI but should not crash
    [[ "$status" -le 1 ]]
}

@test "phase-gate status shows current phase" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-phase-gate.sh" status
    assert_output --partial "phase"
}

# ─── check command — circuit breaker ───

@test "phase-gate check outputs gate status" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-phase-gate.sh" check
    # Will return 1 (WAIT) since no approvals exist
    [ "$status" -le 2 ]
    assert_output --partial "PHASE-GATE"
}

@test "phase-gate increments poll count on check" {
    cd "$TEST_PROJECT"
    bash "$FORGE_DIR/scripts/forge-phase-gate.sh" check 2>/dev/null || true
    # Poll count should have incremented
    run python3 -c "import json; d=json.load(open('docs/forge-state.json')); print(d['gate_circuit']['poll_count'])"
    assert_output "1"
}

@test "phase-gate circuit opens after 5 polls" {
    cd "$TEST_PROJECT"
    # Set poll_count to 4
    python3 -c "
import json
with open('docs/forge-state.json') as f:
    d = json.load(f)
d['gate_circuit']['poll_count'] = 4
with open('docs/forge-state.json', 'w') as f:
    json.dump(d, f)
"
    run bash "$FORGE_DIR/scripts/forge-phase-gate.sh" check
    assert_output --partial "CIRCUIT"
}

# ─── clear command ───

@test "phase-gate clear creates approval file" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-phase-gate.sh" clear
    assert_success
    assert_output --partial "Manually cleared"
}
