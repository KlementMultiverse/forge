#!/usr/bin/env bash
# Common setup for all BATS tests
# Provides: temp dirs, mock state files, mock git repos, shared helpers

# Resolve forge root directory
FORGE_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
export FORGE_DIR

# Load BATS helpers using absolute paths
load "${FORGE_DIR}/tests/test_helper/bats-support/load"
load "${FORGE_DIR}/tests/test_helper/bats-assert/load"

_common_setup() {
    # Create isolated test environment
    export TEST_PROJECT="$(mktemp -d)"
    export PROJECT_ROOT="$TEST_PROJECT"
    export D="$TEST_PROJECT"

    # Create standard forge directory structure
    mkdir -p "$TEST_PROJECT/docs/forge-trace"
    mkdir -p "$TEST_PROJECT/docs/.approvals"
    mkdir -p "$TEST_PROJECT/.forge/playbook"
    mkdir -p "$TEST_PROJECT/.claude/rules"
    mkdir -p "$TEST_PROJECT/apps"
    mkdir -p "$TEST_PROJECT/scripts"

    # Copy scripts to test project (so they can find each other via source)
    cp "$FORGE_DIR/scripts/"*.sh "$TEST_PROJECT/scripts/" 2>/dev/null || true
    cp "$FORGE_DIR/scripts/"*.py "$TEST_PROJECT/scripts/" 2>/dev/null || true
    chmod +x "$TEST_PROJECT/scripts/"* 2>/dev/null || true
}

_common_teardown() {
    rm -rf "$TEST_PROJECT"
}

# ─── Helpers ───

# Create a mock forge-state.json
setup_mock_state() {
    local json="${1:-'{}'}"
    echo "$json" > "$TEST_PROJECT/docs/forge-state.json"
}

# Create a mock SPEC.md with REQ tags
setup_mock_spec() {
    cat > "$TEST_PROJECT/SPEC.md" << 'EOF'
# Test Spec

## Requirements

[REQ-AUTH-001] User must login with email and password
[REQ-AUTH-002] Failed login locks account after 3 attempts
[REQ-UI-001] Dashboard shows user stats

## Models

| Model | Fields | REQ |
|-------|--------|-----|
| User | email, password | [REQ-AUTH-001] |
EOF
}

# Create a mock git repo
setup_mock_git_repo() {
    cd "$TEST_PROJECT"
    git init -q -b main
    git config user.email "test@forge.dev"
    git config user.name "Forge Test"
    echo "# Test" > README.md
    git add -A && git commit -q -m "init: test project"
}

# Create a mock CLAUDE.md
setup_mock_claude_md() {
    cat > "$TEST_PROJECT/CLAUDE.md" << 'EOF'
# Test Project

## Tech Stack
| Layer | Technology |
|-------|-----------|
| Backend | Python/Django |

## Architecture Rules
1. MUST use Django Ninja for API
2. NEVER hardcode credentials
EOF
}

# Create mock code file with REQ tags
setup_mock_code() {
    local app="${1:-auth}"
    local req="${2:-REQ-AUTH-001}"
    mkdir -p "$TEST_PROJECT/apps/$app"
    cat > "$TEST_PROJECT/apps/$app/models.py" << EOF
# [$req] User model
class User:
    email = "test@test.com"
    password = "hashed"
EOF
}

# Create mock test file with REQ tags
setup_mock_test() {
    local app="${1:-auth}"
    local req="${2:-REQ-AUTH-001}"
    mkdir -p "$TEST_PROJECT/apps/$app"
    cat > "$TEST_PROJECT/apps/$app/tests.py" << EOF
def test_user_login():
    """[$req] Verify user can login"""
    assert True
EOF
}
