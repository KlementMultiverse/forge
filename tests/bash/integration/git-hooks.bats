#!/usr/bin/env bats
# Integration tests for git hooks (commit-msg, pre-commit)
# These tests create real git repos and test actual hook behavior

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    setup_mock_git_repo

    # Install hooks
    cp "$FORGE_DIR/templates/commit-msg" "$TEST_PROJECT/.git/hooks/commit-msg"
    chmod +x "$TEST_PROJECT/.git/hooks/commit-msg"
    if [ -f "$FORGE_DIR/templates/pre-commit" ]; then
        cp "$FORGE_DIR/templates/pre-commit" "$TEST_PROJECT/.git/hooks/pre-commit"
        chmod +x "$TEST_PROJECT/.git/hooks/pre-commit"
    fi
}

teardown() {
    _common_teardown
}

# ─── commit-msg hook ───

@test "commit-msg allows merge commits" {
    cd "$TEST_PROJECT"
    echo "test" > file.txt && git add file.txt
    run git commit -m "Merge branch 'feature'"
    assert_success
}

@test "commit-msg allows initial commit" {
    cd "$TEST_PROJECT"
    echo "test" > file.txt && git add file.txt
    run git commit -m "initial commit"
    assert_success
}

@test "commit-msg blocks commit without issue reference" {
    cd "$TEST_PROJECT"
    echo "test" > file.txt && git add file.txt
    run git commit -m "feat(scripts): add something"
    assert_failure
    assert_output --partial "BLOCKED"
    assert_output --partial "issue"
}

@test "commit-msg allows commit with issue reference" {
    cd "$TEST_PROJECT"
    echo "test" > file.txt && git add file.txt
    run git commit -m "feat(scripts): add something #1"
    assert_success
}

@test "commit-msg blocks commit without scope" {
    cd "$TEST_PROJECT"
    echo "test" > file.txt && git add file.txt
    run git commit -m "feat: add something #1"
    assert_failure
    assert_output --partial "BLOCKED"
    assert_output --partial "scope"
}

@test "commit-msg allows conventional commit with scope and issue" {
    cd "$TEST_PROJECT"
    echo "test" > file.txt && git add file.txt
    run git commit -m "feat(scripts): add retry tracking #14"
    assert_success
}

@test "commit-msg allows breaking change with !" {
    cd "$TEST_PROJECT"
    echo "test" > file.txt && git add file.txt
    run git commit -m "feat(commands)!: breaking change #1"
    assert_success
}

@test "commit-msg rejects invalid type" {
    cd "$TEST_PROJECT"
    echo "test" > file.txt && git add file.txt
    run git commit -m "yolo(scripts): bad type #1"
    assert_failure
}

@test "commit-msg rejects invalid scope" {
    cd "$TEST_PROJECT"
    echo "test" > file.txt && git add file.txt
    run git commit -m "feat(invalid): bad scope #1"
    assert_failure
}

# ─── install.sh integration ───

@test "install.sh runs successfully" {
    run bash "$FORGE_DIR/install.sh"
    assert_success
    assert_output --partial "Forge installed"
}

@test "install.sh --help shows usage" {
    run bash "$FORGE_DIR/install.sh" --help
    assert_success
    assert_output --partial "Usage"
}
