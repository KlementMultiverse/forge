#!/usr/bin/env bats
# Tests: forge infrastructure bootstrap for cloned/forked repos (#118)
# Also tests: wrong directory guard (#120), reset capability (#121)

setup() {
    load '../../test_helper/common-setup'
    FORGE_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
    export FORGE_DIR
    export TEST_PROJECT="$(mktemp -d)"
    export PROJECT_ROOT="$TEST_PROJECT"
    export D="$TEST_PROJECT"
    mkdir -p "$TEST_PROJECT/docs"
}

teardown() {
    rm -rf "$TEST_PROJECT"
}

# ═══════════════════════════════════════
# #118: Cloned repo infra bootstrap
# ═══════════════════════════════════════

@test "forge-infra-check.sh exists and is executable" {
    assert [ -f "$FORGE_DIR/scripts/forge-infra-check.sh" ]
    assert [ -x "$FORGE_DIR/scripts/forge-infra-check.sh" ]
}

@test "infra-check detects missing .claude/settings.json" {
    cd "$TEST_PROJECT"
    echo "# Project" > CLAUDE.md
    run bash "$FORGE_DIR/scripts/forge-infra-check.sh" check
    assert_failure
    assert_output --partial "missing"
}

@test "infra-check passes when all infrastructure exists" {
    cd "$TEST_PROJECT"
    echo "# Project" > CLAUDE.md
    mkdir -p .claude .forge/playbook docs
    echo '{}' > .claude/settings.json
    echo '{}' > docs/forge-state.json
    touch .forge/playbook/strategies.md
    run bash "$FORGE_DIR/scripts/forge-infra-check.sh" check
    assert_success
}

@test "infra-check --fix installs missing infrastructure" {
    cd "$TEST_PROJECT"
    echo "# Project" > CLAUDE.md
    mkdir -p .git  # pretend it's a git repo
    run bash "$FORGE_DIR/scripts/forge-infra-check.sh" --fix
    assert_success
    assert [ -f "$TEST_PROJECT/.claude/settings.json" ]
}

# ═══════════════════════════════════════
# #119: Observer fallback
# ═══════════════════════════════════════

@test "phase-gate handles missing observer gracefully" {
    cd "$TEST_PROJECT"
    echo '{"version":"1.1.0","current_step":8,"current_phase":0,"phases":{"0":{"status":"IN_PROGRESS"}},"gate_circuit":{"state":"CLOSED","poll_count":0,"cooldown_count":0,"last_poll_at":null,"cooldown_until":null,"last_response":null}}' > docs/forge-state.json
    # No .observer-reviews.log, no .observer-reviewing
    run bash "$FORGE_DIR/scripts/forge-phase-gate.sh" check
    # Should NOT hang — should indicate observer not configured
    [[ "$status" -le 2 ]]
}

# ═══════════════════════════════════════
# #120: Wrong directory guard
# ═══════════════════════════════════════

@test "infra-check warns about non-project directory" {
    run bash "$FORGE_DIR/scripts/forge-infra-check.sh" check-dir /tmp
    assert_failure
    assert_output --partial "not a project"
}

@test "infra-check accepts directory with .git" {
    cd "$TEST_PROJECT"
    mkdir -p .git
    run bash "$FORGE_DIR/scripts/forge-infra-check.sh" check-dir "$TEST_PROJECT"
    assert_success
}

# ═══════════════════════════════════════
# #121: Reset capability
# ═══════════════════════════════════════

@test "infra-check --reset clears forge state" {
    cd "$TEST_PROJECT"
    mkdir -p docs/forge-trace .forge
    echo '{"current_step":15}' > docs/forge-state.json
    echo "timeline" > docs/forge-timeline.md
    run bash "$FORGE_DIR/scripts/forge-infra-check.sh" --reset
    assert_success
    assert [ ! -f "$TEST_PROJECT/docs/forge-state.json" ]
}

# ═══════════════════════════════════════
# #123: forge-manifest.json
# ═══════════════════════════════════════

@test "forge-philosophy.md does not reference non-existent forge-manifest.json" {
    # Either forge-manifest.json exists OR the reference is removed
    if [ -f "$FORGE_DIR/forge-manifest.json" ]; then
        assert [ -f "$FORGE_DIR/forge-manifest.json" ]
    else
        run grep "forge-manifest.json" "$FORGE_DIR/rules/forge-philosophy.md"
        assert_failure  # Reference should be removed if file doesn't exist
    fi
}
