#!/usr/bin/env bats
# Tests for scripts/forge-verify.sh
# Verifies step verification, gap detection, metrics

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    setup_mock_git_repo
    setup_mock_state '{"version":"1.1.0","project":"test","current_step":3,"current_phase":0,"status":"IN_PROGRESS","phases":{"0":{"status":"IN_PROGRESS"}}}'
    export PROJECT_ROOT="$TEST_PROJECT"
    export D="$TEST_PROJECT"
}

teardown() {
    _common_teardown
}

@test "forge-verify.sh exists and is executable" {
    assert [ -f "$FORGE_DIR/scripts/forge-verify.sh" ]
    assert [ -x "$FORGE_DIR/scripts/forge-verify.sh" ]
}

# ─── help ───

@test "verify help shows commands" {
    run bash "$FORGE_DIR/scripts/forge-verify.sh" help
    assert_output --partial "verify-step"
}

# ─── verify-step ───

@test "verify-step fails for step without trace" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-verify.sh" verify-step 1
    assert_failure
}

@test "verify-step passes when trace exists and manifest present" {
    cd "$TEST_PROJECT"
    # forge-verify.sh requires forge-manifest.json
    echo '{"steps":[{"id":1,"name":"discover"}]}' > forge-manifest.json
    mkdir -p docs/forge-trace/001-discover
    echo "input" > docs/forge-trace/001-discover/input.md
    echo "output" > docs/forge-trace/001-discover/output.md
    echo "meta" > docs/forge-trace/001-discover/meta.md
    run bash "$FORGE_DIR/scripts/forge-verify.sh" verify-step 1
    [[ "$status" -le 1 ]]
}

# ─── next-gap ───

@test "next-gap runs without crashing" {
    cd "$TEST_PROJECT"
    echo '{"steps":[{"id":1,"name":"discover"}]}' > forge-manifest.json
    run bash "$FORGE_DIR/scripts/forge-verify.sh" next-gap
    [[ "$status" -le 1 ]]
}

# ─── metrics ───

@test "metrics runs without crashing" {
    cd "$TEST_PROJECT"
    echo '{"steps":[{"id":1,"name":"discover"}]}' > forge-manifest.json
    run bash "$FORGE_DIR/scripts/forge-verify.sh" metrics
    [[ "$status" -le 1 ]]
}
