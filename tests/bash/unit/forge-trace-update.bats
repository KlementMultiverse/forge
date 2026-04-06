#!/usr/bin/env bats
# Tests for scripts/forge-trace-update.sh
# Verifies in-file FORGE TRACE block management

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    export PROJECT_ROOT="$TEST_PROJECT"
    export D="$TEST_PROJECT"
}

teardown() {
    _common_teardown
}

@test "trace-update help shows all commands" {
    run bash "$FORGE_DIR/scripts/forge-trace-update.sh" help
    assert_output --partial "add"
    assert_output --partial "init"
    assert_output --partial "show"
    assert_output --partial "check"
    assert_output --partial "split"
    assert_output --partial "archive"
}

@test "trace init creates trace block in .py file" {
    echo "# code" > "$TEST_PROJECT/test.py"
    run bash "$FORGE_DIR/scripts/forge-trace-update.sh" init "$TEST_PROJECT/test.py" REQ-AUTH-001 @backend-coder
    assert_success
    run grep "FORGE TRACE" "$TEST_PROJECT/test.py"
    assert_success
}

@test "trace init creates sidecar for .json file" {
    echo '{}' > "$TEST_PROJECT/config.json"
    run bash "$FORGE_DIR/scripts/forge-trace-update.sh" init "$TEST_PROJECT/config.json" REQ-CFG-001 @devops
    assert_success
    assert [ -f "$TEST_PROJECT/config.json.forge-trace" ]
}

@test "trace init creates sidecar for .yaml file" {
    echo 'key: val' > "$TEST_PROJECT/config.yaml"
    run bash "$FORGE_DIR/scripts/forge-trace-update.sh" init "$TEST_PROJECT/config.yaml" REQ-CFG-001 @devops
    assert_success
    assert [ -f "$TEST_PROJECT/config.yaml.forge-trace" ]
}

@test "trace add appends entry to existing block" {
    echo "# code" > "$TEST_PROJECT/test.py"
    bash "$FORGE_DIR/scripts/forge-trace-update.sh" init "$TEST_PROJECT/test.py" REQ-AUTH-001 @coder
    run bash "$FORGE_DIR/scripts/forge-trace-update.sh" add "$TEST_PROJECT/test.py" REQ-AUTH-001 @reviewer "#5" "reviewed"
    assert_success
    run grep -c "REQ-AUTH-001" "$TEST_PROJECT/test.py"
    assert_output "2"
}

@test "trace check passes with trace block" {
    echo "# code" > "$TEST_PROJECT/test.py"
    bash "$FORGE_DIR/scripts/forge-trace-update.sh" init "$TEST_PROJECT/test.py" REQ-AUTH-001 @coder
    run bash "$FORGE_DIR/scripts/forge-trace-update.sh" check "$TEST_PROJECT/test.py"
    assert_success
    assert_output --partial "PASS"
}

@test "trace check fails without trace block" {
    echo "# no trace" > "$TEST_PROJECT/test.py"
    run bash "$FORGE_DIR/scripts/forge-trace-update.sh" check "$TEST_PROJECT/test.py"
    assert_failure
    assert_output --partial "FAIL"
}

@test "trace show displays trace block" {
    echo "# code" > "$TEST_PROJECT/test.py"
    bash "$FORGE_DIR/scripts/forge-trace-update.sh" init "$TEST_PROJECT/test.py" REQ-AUTH-001 @coder
    run bash "$FORGE_DIR/scripts/forge-trace-update.sh" show "$TEST_PROJECT/test.py"
    assert_output --partial "FORGE TRACE"
    assert_output --partial "REQ-AUTH-001"
}

@test "trace add-multi adds multiple REQs" {
    echo "# code" > "$TEST_PROJECT/test.py"
    run bash "$FORGE_DIR/scripts/forge-trace-update.sh" add-multi "$TEST_PROJECT/test.py" "REQ-AUTH-001,REQ-AUTH-002" @coder "#10" "multi"
    assert_success
    run grep -c "REQ-AUTH" "$TEST_PROJECT/test.py"
    assert_output "2"
}

@test "trace uses // comments for .js files" {
    echo "// code" > "$TEST_PROJECT/test.js"
    bash "$FORGE_DIR/scripts/forge-trace-update.sh" init "$TEST_PROJECT/test.js" REQ-UI-001 @frontend
    run grep "//" "$TEST_PROJECT/test.js"
    assert_success
}
