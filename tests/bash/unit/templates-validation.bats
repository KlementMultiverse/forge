#!/usr/bin/env bats
# Tests for all template files — Pipe 1/2 safety validation

setup() {
    load '../../test_helper/common-setup'
    _common_setup
}

teardown() {
    _common_teardown
}

@test "template count is at least 15" {
    local count
    count=$(find "$FORGE_DIR/templates" -type f -not -name "*.pyc" | wc -l)
    [ "$count" -ge 15 ]
}

@test "CLAUDE.template.md exists" {
    assert [ -f "$FORGE_DIR/templates/CLAUDE.template.md" ]
}

@test "SPEC.template.md exists" {
    assert [ -f "$FORGE_DIR/templates/SPEC.template.md" ]
}

@test "hooks.json is valid JSON" {
    run python3 -c "import json; json.load(open('$FORGE_DIR/templates/hooks.json'))"
    assert_success
}

@test "hooks.json has all 4 event types" {
    local hooks_file="$FORGE_DIR/templates/hooks.json"
    run python3 -c "
import json
with open('$hooks_file') as f:
    d = json.load(f)
events = list(d.get('hooks', {}).keys())
assert 'Stop' in events, 'Missing Stop'
assert 'UserPromptSubmit' in events, 'Missing UserPromptSubmit'
assert 'PreToolUse' in events, 'Missing PreToolUse'
assert 'PostToolUse' in events, 'Missing PostToolUse'
print('All 4 events present')
"
    assert_success
}

@test "auto-loadable templates have placeholders inside HTML comments only (Pipe 1 safety)" {
    # Only check templates that could be auto-loaded by Claude Code
    # Pipe 2 templates (read by agents) are allowed raw placeholders
    local pipe1_templates="CLAUDE.template.md FORGE.template.md forge-timeline.template.md"
    local unsafe=0
    for name in $pipe1_templates; do
        local tmpl="$FORGE_DIR/templates/$name"
        [ -f "$tmpl" ] || continue
        local raw_placeholders
        raw_placeholders=$(python3 -c "
import re
with open('$tmpl') as f:
    content = f.read()
cleaned = re.sub(r'<!--.*?-->', '', content, flags=re.DOTALL)
found = re.findall(r'\{\{[^}]+\}\}', cleaned)
if found:
    print('\n'.join(found))
" 2>/dev/null)
        if [ -n "$raw_placeholders" ]; then
            echo "UNSAFE: $name has raw {{ }} outside HTML comments: $raw_placeholders"
            unsafe=$((unsafe + 1))
        fi
    done
    [ "$unsafe" -eq 0 ]
}

@test "commit-msg hook template exists" {
    assert [ -f "$FORGE_DIR/templates/commit-msg" ]
}

@test "pre-commit hook template exists" {
    assert [ -f "$FORGE_DIR/templates/pre-commit" ]
}

@test "commit-msg hook is valid bash" {
    run bash -n "$FORGE_DIR/templates/commit-msg"
    assert_success
}

@test "pre-commit hook is valid bash" {
    run bash -n "$FORGE_DIR/templates/pre-commit"
    assert_success
}
