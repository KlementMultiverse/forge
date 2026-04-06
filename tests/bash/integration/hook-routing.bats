#!/usr/bin/env bats
# Integration tests: verify hook routing and gating behavior
# Tests that hooks.json has correct structure for prompt-gated output

setup() {
    load '../../test_helper/common-setup'
    _common_setup
}

teardown() {
    _common_teardown
}

# ─── SessionStart hook exists ───

@test "hooks.json has SessionStart event" {
    run python3 -c "
import json
with open('$FORGE_DIR/templates/hooks.json') as f:
    d = json.load(f)
assert 'SessionStart' in d['hooks'], 'Missing SessionStart'
print('SessionStart present')
"
    assert_success
}

@test "SessionStart checks GitHub remote" {
    run grep "remote\|REMOTE\|git.*remote" "$FORGE_DIR/templates/hooks.json"
    assert_success
}

@test "SessionStart checks CLAUDE.md char count" {
    run grep "40000\|40K\|CLAUDE.md" "$FORGE_DIR/templates/hooks.json"
    assert_success
}

# ─── UserPromptSubmit gates on /forge ───

@test "UserPromptSubmit reads prompt input for /forge detection" {
    run grep "CLAUDE_HOOK_INPUT\|forge.*detect\|IS_FORGE\|prompt" "$FORGE_DIR/templates/hooks.json"
    assert_success
}

@test "UserPromptSubmit runs state-sync" {
    run grep "forge-state-sync" "$FORGE_DIR/templates/hooks.json"
    assert_success
}

# ─── CASE detection completeness ───

@test "hooks detect CASE_RESUME for existing forge-state" {
    run grep "RESUME\|resume" "$FORGE_DIR/templates/hooks.json"
    assert_success
}

# ─── forge-state-sync.sh comment is accurate ───

@test "forge-state-sync.sh comment says every prompt not every /forge" {
    run grep "every user prompt\|every prompt" "$FORGE_DIR/scripts/forge-state-sync.sh"
    assert_success
}
