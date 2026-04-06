#!/usr/bin/env bats
# Tests for scripts/forge-ownership.sh
# Verifies code ownership management

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    export PROJECT_ROOT="$TEST_PROJECT"
    export D="$TEST_PROJECT"
}

teardown() {
    _common_teardown
}

@test "ownership help shows commands" {
    run bash "$FORGE_DIR/scripts/forge-ownership.sh" help
    assert_output --partial "check"
    assert_output --partial "orphans"
    assert_output --partial "who"
    assert_output --partial "reqs"
    assert_output --partial "create"
}

@test "ownership check runs with no OWNERS files" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-ownership.sh" check
    assert_success
    assert_output --partial "OWNERS files: 0"
}

@test "ownership create makes OWNERS file" {
    cd "$TEST_PROJECT"
    mkdir -p apps/auth
    run bash "$FORGE_DIR/scripts/forge-ownership.sh" create apps/auth @backend-coder REQ-AUTH-001
    assert_success
    assert [ -f "$TEST_PROJECT/apps/auth/OWNERS" ]
}

@test "ownership create writes correct agent" {
    cd "$TEST_PROJECT"
    mkdir -p apps/auth
    bash "$FORGE_DIR/scripts/forge-ownership.sh" create apps/auth @backend-coder REQ-AUTH-001
    run grep "agent:" "$TEST_PROJECT/apps/auth/OWNERS"
    assert_output --partial "@backend-coder"
}

@test "ownership create writes correct requirements" {
    cd "$TEST_PROJECT"
    mkdir -p apps/auth
    bash "$FORGE_DIR/scripts/forge-ownership.sh" create apps/auth @backend-coder REQ-AUTH-001,REQ-AUTH-002
    run grep "requirements:" "$TEST_PROJECT/apps/auth/OWNERS"
    assert_output --partial "REQ-AUTH-001"
    assert_output --partial "REQ-AUTH-002"
}

@test "ownership who finds owner from OWNERS file" {
    cd "$TEST_PROJECT"
    mkdir -p apps/auth
    bash "$FORGE_DIR/scripts/forge-ownership.sh" create apps/auth @backend-coder REQ-AUTH-001
    echo "# code" > apps/auth/models.py
    run bash "$FORGE_DIR/scripts/forge-ownership.sh" who apps/auth/models.py
    assert_success
    assert_output --partial "@backend-coder"
}

@test "ownership who reports NONE for unowned file" {
    cd "$TEST_PROJECT"
    mkdir -p apps/ghost
    echo "# code" > apps/ghost/models.py
    run bash "$FORGE_DIR/scripts/forge-ownership.sh" who apps/ghost/models.py
    assert_failure
    assert_output --partial "NONE"
}

@test "ownership check shows created OWNERS" {
    cd "$TEST_PROJECT"
    mkdir -p apps/auth
    bash "$FORGE_DIR/scripts/forge-ownership.sh" create apps/auth @backend-coder REQ-AUTH-001
    run bash "$FORGE_DIR/scripts/forge-ownership.sh" check
    assert_output --partial "OWNERS files: 1"
    assert_output --partial "@backend-coder"
}

@test "ownership reqs shows REQs for agent" {
    cd "$TEST_PROJECT"
    mkdir -p apps/auth
    bash "$FORGE_DIR/scripts/forge-ownership.sh" create apps/auth @backend-coder REQ-AUTH-001,REQ-AUTH-002
    run bash "$FORGE_DIR/scripts/forge-ownership.sh" reqs @backend-coder
    assert_output --partial "REQ-AUTH-001"
}
