#!/usr/bin/env bats
# Integration tests for the 4 enforcement flow chains
# Tests the full chain, not individual pieces

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    setup_mock_git_repo
    setup_mock_spec
    setup_mock_code "auth" "REQ-AUTH-001"
    setup_mock_test "auth" "REQ-AUTH-001"
    export PROJECT_ROOT="$TEST_PROJECT"
    export D="$TEST_PROJECT"
    export FORGE_DIR="$FORGE_DIR"
}

teardown() {
    _common_teardown
}

# ═══════════════════════════════════════
# WRITE CHAIN: write → validator → sync queue
# ═══════════════════════════════════════

@test "write chain: post-edit runs on forge component file" {
    cd "$TEST_PROJECT"
    echo "# new script" > scripts/test-new.sh
    run bash "$FORGE_DIR/scripts/forge-change-validator.sh" post-edit "$TEST_PROJECT/scripts/test-new.sh"
    assert_success
    assert_output --partial "Post-edit"
}

@test "write chain: post-edit detects missing test for new script" {
    cd "$TEST_PROJECT"
    mkdir -p scripts
    echo "# new" > scripts/untested.sh
    run env FORGE_DIR="$TEST_PROJECT" bash "$FORGE_DIR/scripts/forge-change-validator.sh" post-edit "$TEST_PROJECT/scripts/untested.sh"
    assert_output --partial "No test found"
}

@test "write chain: auto-sync queues sync for component write" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-auto-sync.sh" queue "$FORGE_DIR/scripts/forge-enforce.sh"
    assert_success
    assert [ -f "$TEST_PROJECT/docs/.forge-sync-pending" ]
    run cat "$TEST_PROJECT/docs/.forge-sync-pending"
    assert_output --partial "readme_sync"
}

@test "write chain: auto-sync queues triangle for REQ-linked file" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-auto-sync.sh" queue "$TEST_PROJECT/apps/auth/models.py"
    assert_success
    run cat "$TEST_PROJECT/docs/.forge-sync-pending"
    assert_output --partial "triangle_check"
}

# ═══════════════════════════════════════
# EDIT CHAIN: pre-edit → impact → ownership → REQs → suspects
# ═══════════════════════════════════════

@test "edit chain: pre-edit shows REQ tags for REQ-linked file" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-change-validator.sh" pre-edit "$TEST_PROJECT/apps/auth/models.py"
    assert_output --partial "REQ"
}

@test "edit chain: pre-edit runs without error on non-REQ file" {
    cd "$TEST_PROJECT"
    echo "# no reqs" > "$TEST_PROJECT/config.py"
    run bash "$FORGE_DIR/scripts/forge-change-validator.sh" pre-edit "$TEST_PROJECT/config.py"
    assert_success
}

@test "edit chain: pre-edit checks suspects" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-change-validator.sh" pre-edit "$TEST_PROJECT/apps/auth/models.py"
    # Should mention suspect check (even if no suspects)
    assert_output --partial "FORGE-VALIDATE"
}

# ═══════════════════════════════════════
# COMMIT CHAIN: auto-sync → REQ check → test-guard → commit-msg
# ═══════════════════════════════════════

@test "commit chain: auto-sync run clears pending before commit" {
    cd "$TEST_PROJECT"
    bash "$FORGE_DIR/scripts/forge-auto-sync.sh" queue "$FORGE_DIR/scripts/forge-enforce.sh"
    run bash "$FORGE_DIR/scripts/forge-auto-sync.sh" run
    assert_success
    assert_output --partial "FORGE-SYNC"
    # Pending cleared
    run bash "$FORGE_DIR/scripts/forge-auto-sync.sh" status
    assert_output --partial "No pending"
}

@test "commit chain: commit-msg blocks without issue reference" {
    cd "$TEST_PROJECT"
    cp "$FORGE_DIR/templates/commit-msg" .git/hooks/commit-msg
    chmod +x .git/hooks/commit-msg
    echo "test" > newfile.txt && git add newfile.txt
    run git commit -m "feat(scripts): no issue ref"
    assert_failure
    assert_output --partial "BLOCKED"
}

@test "commit chain: commit-msg blocks without scope" {
    cd "$TEST_PROJECT"
    cp "$FORGE_DIR/templates/commit-msg" .git/hooks/commit-msg
    chmod +x .git/hooks/commit-msg
    echo "test" > newfile.txt && git add newfile.txt
    run git commit -m "feat: no scope #1"
    assert_failure
    assert_output --partial "BLOCKED"
}

@test "commit chain: commit-msg allows valid conventional commit" {
    cd "$TEST_PROJECT"
    cp "$FORGE_DIR/templates/commit-msg" .git/hooks/commit-msg
    chmod +x .git/hooks/commit-msg
    echo "test" > newfile.txt && git add newfile.txt
    run git commit -m "feat(scripts): valid commit #1"
    assert_success
}

# ═══════════════════════════════════════
# GATE CHAIN: triangle + suspects + review-guard
# ═══════════════════════════════════════

@test "gate chain: triangle check shows SYNCED for complete REQs" {
    cd "$TEST_PROJECT"
    # Create a clean spec with only one REQ that has code+test
    echo "REQ-AUTH-001 User login" > SPEC.md
    run bash "$FORGE_DIR/scripts/forge-triangle.sh" check
    assert_success
    assert_output --partial "SYNCED"
}

@test "gate chain: triangle check fails with broken REQ" {
    cd "$TEST_PROJECT"
    # Add REQ to spec but not to code/test
    echo "REQ-NEW-001 New requirement" >> SPEC.md
    run bash "$FORGE_DIR/scripts/forge-triangle.sh" check
    assert_failure
}

@test "gate chain: suspect check passes with no suspects" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-enforce.sh" check-suspect
    assert_success
}

@test "gate chain: suspect check fails with unverified suspect" {
    cd "$TEST_PROJECT"
    mkdir -p docs
    echo '{"version":"1.0.0","suspect_reqs":{"REQ-AUTH-001":{"reason":"test","verified":false}}}' > docs/suspect-reqs.json
    run bash "$FORGE_DIR/scripts/forge-enforce.sh" check-suspect
    assert_failure
}

@test "gate chain: review-guard blocks gate without review" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-review-guard.sh" check-for-gate
    assert_failure
}

@test "gate chain: review-guard passes after mark-reviewed" {
    cd "$TEST_PROJECT"
    bash "$FORGE_DIR/scripts/forge-review-guard.sh" mark-reviewed
    run bash "$FORGE_DIR/scripts/forge-review-guard.sh" check-for-gate
    assert_success
}

@test "gate chain: full validator check runs all checks" {
    cd "$TEST_PROJECT"
    run bash "$FORGE_DIR/scripts/forge-change-validator.sh" full-check
    assert_output --partial "README Sync"
    assert_output --partial "Test Coverage"
    assert_output --partial "Suspect REQs"
}
