#!/usr/bin/env bats
# Tests for all 7 rule files — auto-load safety validation

setup() {
    load '../../test_helper/common-setup'
    _common_setup
}

teardown() {
    _common_teardown
}

@test "rule count is 7" {
    local count
    count=$(ls "$FORGE_DIR"/rules/*.md 2>/dev/null | wc -l)
    [ "$count" -eq 7 ]
}

@test "all rules are valid markdown" {
    local bad=0
    for rule in "$FORGE_DIR"/rules/*.md; do
        if [ ! -s "$rule" ]; then
            echo "EMPTY: $(basename "$rule")"
            bad=$((bad + 1))
        fi
    done
    [ "$bad" -eq 0 ]
}

@test "no rule has raw template placeholders (context poisoning)" {
    local unsafe=0
    for rule in "$FORGE_DIR"/rules/*.md; do
        if grep -q '{{' "$rule" 2>/dev/null; then
            echo "CONTEXT POISON: $(basename "$rule") has {{ }}"
            unsafe=$((unsafe + 1))
        fi
    done
    [ "$unsafe" -eq 0 ]
}

@test "security.md rule exists" {
    assert [ -f "$FORGE_DIR/rules/security.md" ]
}

@test "universal.md rule exists" {
    assert [ -f "$FORGE_DIR/rules/universal.md" ]
}

@test "forge-enforcement.md rule exists" {
    assert [ -f "$FORGE_DIR/rules/forge-enforcement.md" ]
}

@test "all rules have a heading" {
    local missing=0
    for rule in "$FORGE_DIR"/rules/*.md; do
        if ! grep -q "^# " "$rule" 2>/dev/null; then
            echo "NO HEADING: $(basename "$rule")"
            missing=$((missing + 1))
        fi
    done
    [ "$missing" -eq 0 ]
}
