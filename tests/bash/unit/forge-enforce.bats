#!/usr/bin/env bats
# Tests for scripts/forge-enforce.sh
# Verifies state management, gate checking, step updates

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    setup_mock_git_repo
}

teardown() {
    _common_teardown
}

# ─── init ───

@test "init creates forge-state.json" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-enforce.sh" init test-project
    assert_success
    assert [ -f "$TEST_PROJECT/docs/forge-state.json" ]
}

@test "init sets project name" {
    cd "$TEST_PROJECT"
    bash "$FORGE_DIR/scripts/forge-enforce.sh" init my-app
    run python3 -c "import json; d=json.load(open('docs/forge-state.json')); print(d['project'])"
    assert_output "my-app"
}

@test "init sets version 1.1.0" {
    cd "$TEST_PROJECT"
    bash "$FORGE_DIR/scripts/forge-enforce.sh" init test
    run python3 -c "import json; d=json.load(open('docs/forge-state.json')); print(d['version'])"
    assert_output "1.1.0"
}

@test "init creates session_id" {
    cd "$TEST_PROJECT"
    bash "$FORGE_DIR/scripts/forge-enforce.sh" init test
    run python3 -c "import json; d=json.load(open('docs/forge-state.json')); print(len(d.get('session_id',''))>0)"
    assert_output "True"
}

# ─── check-state ───

@test "check-state shows current state" {
    cd "$TEST_PROJECT"
    bash "$FORGE_DIR/scripts/forge-enforce.sh" init test
    run bash "$FORGE_DIR/scripts/forge-enforce.sh" check-state
    assert_success
    assert_output --partial "test"
}

@test "check-state fails without state file" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-enforce.sh" check-state
    assert_failure
}

# ─── update-step ───

@test "update-step marks step as DONE" {
    cd "$TEST_PROJECT"
    bash "$FORGE_DIR/scripts/forge-enforce.sh" init test
    run bash "$FORGE_DIR/scripts/forge-enforce.sh" update-step 1 DONE
    assert_success
    # Verify step is recorded
    run python3 -c "import json; d=json.load(open('docs/forge-state.json')); print(d['current_step'])"
    assert_output "1"
}

@test "update-step never regresses step number" {
    cd "$TEST_PROJECT"
    bash "$FORGE_DIR/scripts/forge-enforce.sh" init test
    bash "$FORGE_DIR/scripts/forge-enforce.sh" update-step 5 DONE
    bash "$FORGE_DIR/scripts/forge-enforce.sh" update-step 3 DONE
    # Step should still be 5, not 3
    run python3 -c "import json; d=json.load(open('docs/forge-state.json')); print(d['current_step'])"
    assert_output "5"
}

# ─── check-gate ───

@test "check-gate fails when gate not passed" {
    cd "$TEST_PROJECT"
    bash "$FORGE_DIR/scripts/forge-enforce.sh" init test
    run bash "$FORGE_DIR/scripts/forge-enforce.sh" check-gate 0
    assert_failure
}

@test "check-gate passes after update-gate" {
    cd "$TEST_PROJECT"
    bash "$FORGE_DIR/scripts/forge-enforce.sh" init test
    bash "$FORGE_DIR/scripts/forge-enforce.sh" update-gate 0
    run bash "$FORGE_DIR/scripts/forge-enforce.sh" check-gate 0
    assert_success
}

# ─── check-agent ───

@test "check-agent blocks app code files" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-enforce.sh" check-agent "apps/auth/models.py"
    assert_failure
    assert_output --partial "BLOCKED"
}

@test "check-agent allows docs files" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-enforce.sh" check-agent "docs/design-doc.md"
    assert_success
}

# ─── check-suspect ───

@test "check-suspect passes with no suspect file" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-enforce.sh" check-suspect
    assert_success
}

@test "check-suspect fails with unverified suspects" {
    cd "$TEST_PROJECT"
    mkdir -p docs
    cat > docs/suspect-reqs.json << 'EOF'
{
    "version": "1.0.0",
    "suspect_reqs": {
        "REQ-AUTH-001": {
            "reason": "code modified",
            "verified": false
        }
    }
}
EOF
    run bash "$FORGE_DIR/scripts/forge-enforce.sh" check-suspect
    assert_failure
    assert_output --partial "REQ-AUTH-001"
}

@test "check-suspect --clear-all clears all suspects" {
    cd "$TEST_PROJECT"
    mkdir -p docs
    cat > docs/suspect-reqs.json << 'EOF'
{
    "version": "1.0.0",
    "suspect_reqs": {
        "REQ-AUTH-001": {"reason": "test", "verified": false}
    },
    "suspect_history": []
}
EOF
    run bash "$FORGE_DIR/scripts/forge-enforce.sh" check-suspect --clear-all
    assert_success
    # Verify suspects cleared
    run bash "$FORGE_DIR/scripts/forge-enforce.sh" check-suspect
    assert_success
}
