#!/usr/bin/env bats
# Master test matrix for Phase A — comprehensive coverage (#68)
# Tests file structure, content integrity, cross-references, and split consistency

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    FORGE_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
    export FORGE_DIR
    PA_DIR="$FORGE_DIR/commands/forge-phases"
    PA_MAIN="$PA_DIR/phase-a-setup.md"
    PA_S2="$PA_DIR/phase-a-s2-discovery.md"
    PA_S3="$PA_DIR/phase-a-s3-s5-specs.md"
    PA_S6="$PA_DIR/phase-a-s6-s8-scaffold.md"
    PA_S9="$PA_DIR/phase-a-s9-s10-review.md"
    LOOP="$FORGE_DIR/rules/universal-agent-loop.md"
    ALL_PA="$PA_MAIN $PA_S2 $PA_S3 $PA_S6 $PA_S9 $LOOP"
}

teardown() {
    _common_teardown
}

# ─── FILE STRUCTURE ───

@test "Phase A: main routing file exists" {
    assert [ -f "$PA_MAIN" ]
}

@test "Phase A: S2 discovery file exists" {
    assert [ -f "$PA_S2" ]
}

@test "Phase A: S3-S5 specs file exists" {
    assert [ -f "$PA_S3" ]
}

@test "Phase A: S6-S8 scaffold file exists" {
    assert [ -f "$PA_S6" ]
}

@test "Phase A: S9-S10 review file exists" {
    assert [ -f "$PA_S9" ]
}

@test "Phase A: universal loop file exists" {
    assert [ -f "$LOOP" ]
}

# ─── FILE SIZE LIMITS ───

@test "Phase A: main file under 300 lines" {
    run wc -l < "$PA_MAIN"
    [ "$output" -lt 300 ]
}

@test "Phase A: S2 file under 700 lines" {
    run wc -l < "$PA_S2"
    [ "$output" -lt 700 ]
}

@test "Phase A: S3-S5 file under 300 lines" {
    run wc -l < "$PA_S3"
    [ "$output" -lt 300 ]
}

@test "Phase A: S6-S8 file under 300 lines" {
    run wc -l < "$PA_S6"
    [ "$output" -lt 300 ]
}

@test "Phase A: S9-S10 file under 300 lines" {
    run wc -l < "$PA_S9"
    [ "$output" -lt 300 ]
}

@test "Phase A: universal loop under 300 lines" {
    run wc -l < "$LOOP"
    [ "$output" -lt 300 ]
}

# ─── ROUTING TABLE ───

@test "Phase A: main has routing table" {
    run grep -i "Step Routing\|Sub-file\|phase-a-s2" "$PA_MAIN"
    assert_success
}

@test "Phase A: main references all sub-files" {
    run grep "phase-a-s2-discovery" "$PA_MAIN"
    assert_success
    run grep "phase-a-s3-s5" "$PA_MAIN"
    assert_success
    run grep "phase-a-s6-s8" "$PA_MAIN"
    assert_success
    run grep "phase-a-s9-s10" "$PA_MAIN"
    assert_success
}

# ─── S1 PREPARE ───

@test "Phase A: S1 prepare has git init" {
    run grep "git init" "$PA_MAIN"
    assert_success
}

@test "Phase A: S1 has partial setup detection" {
    run grep -i "partial setup\|resume" "$PA_MAIN"
    assert_success
}

# ─── S2 DISCOVERY ───

@test "Phase A: S2 has all 7 questions (Q1-Q7)" {
    for q in "Q1:" "Q2:" "Q3:" "Q3.5:" "Q4:" "Q5:" "Q6:" "Q7:"; do
        run grep "$q" "$PA_S2"
        assert_success
    done
}

@test "Phase A: S2 has Q4.5 design decisions" {
    run grep "Q4.5" "$PA_S2"
    assert_success
}

@test "Phase A: S2 has 8-part protocol definition" {
    run grep -i "8 parts" "$PA_S2"
    assert_success
}

@test "Phase A: S2 has variable chain" {
    run grep "VARIABLE CHAIN" "$PA_S2"
    assert_success
}

@test "Phase A: S2 has discovery notes schema" {
    run grep "Discovery Notes Schema" "$PA_S2"
    assert_success
}

@test "Phase A: S2 has completion gate" {
    run grep "S2 COMPLETION GATE" "$PA_S2"
    assert_success
}

@test "Phase A: S2 has FINAL DIMENSIONS with Q4.5 outputs" {
    for dim in PROJECT USERS PROBLEM SUCCESS STACK_BACKEND ARCH_PATTERN AUTH_STRATEGY FEATURES COMPLIANCE EXCLUDED; do
        run grep "$dim:" "$PA_S2"
        assert_success
    done
}

@test "Phase A: S2 Q4 has shopping cart format" {
    run grep -i "SHOPPING CART\|top 3" "$PA_S2"
    assert_success
}

@test "Phase A: S2 Q4 has incompatibility warnings" {
    run grep -i "INCOMPATIBILITY\|conflict" "$PA_S2"
    assert_success
}

@test "Phase A: S2 Q4 has cost estimates" {
    run grep -i "COST_ESTIMATE\|cost.*month" "$PA_S2"
    assert_success
}

@test "Phase A: S2 has internet-first research (no registry bias)" {
    run grep -i "NEVER default.*registry\|internet.*FIRST\|internet research" "$PA_S2"
    assert_success
}

@test "Phase A: S2 has deep-dive trigger for AI+people-affecting" {
    run grep -i "people-affecting\|AI.*regulated\|hiring.*HR.*lending" "$PA_S2"
    assert_success
}

# ─── S3-S5 SPECS ───

@test "Phase A: S3 has HANDOFF METRIC" {
    run grep "HANDOFF METRIC" "$PA_S3"
    assert_success
}

@test "Phase A: S3 spawns system-architect" {
    run grep 'subagent_type="system-architect"' "$PA_S3"
    assert_success
}

@test "Phase A: S3 has 3-type rule generation" {
    run grep -i "DYNAMIC\|UNIVERSAL SAFETY\|FEATURE-CONDITIONAL" "$PA_S3"
    assert_success
}

@test "Phase A: S3 requires context-loader before spawn" {
    run grep -i "context-loader-agent.*MANDATORY" "$PA_S3"
    assert_success
}

@test "Phase A: S4 has HANDOFF METRIC" {
    run grep -i "HANDOFF METRIC.*S4\|HANDOFF METRIC" "$PA_S3"
    assert_success
}

@test "Phase A: S4 has anti-scope enforcement" {
    run grep -i "NEVER generate.*EXCLUDED\|anti.scope" "$PA_S3"
    assert_success
}

@test "Phase A: S4 spawns requirements-analyst" {
    run grep 'subagent_type="requirements-analyst"' "$PA_S3"
    assert_success
}

@test "Phase A: S5 has HANDOFF METRIC" {
    run grep -c "HANDOFF METRIC" "$PA_S3"
    assert_success
    [ "$output" -ge 3 ]
}

# ─── S6-S8 SCAFFOLD ───

@test "Phase A: S6 has open agent selection (no bias)" {
    run grep -i "NEVER force.*stack-specific\|open.*not biased" "$PA_S6"
    assert_success
}

@test "Phase A: S6 has agent-factory for missing agents" {
    run grep "agent-factory" "$PA_S6"
    assert_success
}

@test "Phase A: S7 has HANDOFF METRIC" {
    run grep -c "HANDOFF METRIC" "$PA_S6"
    assert_success
    [ "$output" -ge 3 ]
}

@test "Phase A: S7 spawns devops-architect" {
    run grep 'subagent_type="devops-architect"' "$PA_S6"
    assert_success
}

@test "Phase A: S8 has HANDOFF METRIC" {
    # S6-S8 file should have at least 3 HANDOFF METRIC sections (S6, S7, S8)
    run grep -c "HANDOFF METRIC" "$PA_S6"
    assert_success
    [ "$output" -ge 3 ]
}

@test "Phase A: S8 copies handoff-check script" {
    run grep "forge-handoff-check" "$PA_S6"
    assert_success
}

# ─── S9-S10 REVIEW ───

@test "Phase A: S9 is MANDATORY" {
    run grep "MANDATORY.*DO NOT SKIP" "$PA_S9"
    assert_success
}

@test "Phase A: S9 spawns reviewer agent" {
    run grep 'subagent_type="reviewer"' "$PA_S9"
    assert_success
}

@test "Phase A: S9 has HANDOFF METRIC" {
    run grep "HANDOFF METRIC" "$PA_S9"
    assert_success
}

@test "Phase A: S10 is MANDATORY" {
    run grep "MANDATORY.*DO NOT SKIP" "$PA_S9"
    assert_success
}

@test "Phase A: S10 does NOT use bare git add -A (only in comments)" {
    # Should not have "git add -A" as an actual command (comments mentioning it are ok)
    run grep "^git add -A\|^  *git add -A" "$PA_S9"
    assert_failure
}

# ─── UNIVERSAL LOOP ───

@test "Universal loop: has 12 steps" {
    run grep -c "^[0-9]\+\." "$LOOP"
    [ "$output" -ge 10 ]
}

@test "Universal loop: has BOUNDED autoresearch" {
    run grep -i "BOUNDED\|SINGLE SOURCE OF TRUTH" "$LOOP"
    assert_success
}

@test "Universal loop: has INVENTED check" {
    run grep "INVENTED" "$LOOP"
    assert_success
}

@test "Universal loop: has REVERSE ENGINEER" {
    run grep "REVERSE ENGINEER" "$LOOP"
    assert_success
}

@test "Universal loop: has ESCALATE path" {
    run grep -i "ESCALATE" "$LOOP"
    assert_success
}

@test "Universal loop: has RAISE QUESTION" {
    run grep -i "RAISE QUESTION" "$LOOP"
    assert_success
}

# ─── CROSS-FILE CONSISTENCY ───

@test "Phase A: no hardcoded Django Ninja bias" {
    run grep -i "Django Ninja for ALL API\|NEVER import rest_framework" $PA_S3 $PA_S6
    assert_failure
}

@test "Phase A: no hardcoded uv bias" {
    run grep -i "uv for packages\|NEVER pip install" $PA_S3 $PA_S6
    assert_failure
}

@test "Phase A: domain-inference-rules has REGULATED column" {
    run grep "REGULATED" "$FORGE_DIR/docs/domain-inference-rules.md"
    assert_success
}

@test "Phase A: domain-inference-rules has EEOC" {
    run grep "EEOC" "$FORGE_DIR/docs/domain-inference-rules.md"
    assert_success
}

# ─── AGENT CONTRACTS ───

@test "Agent contract: system-architect has Input Contract" {
    run grep "Input Contract" "$FORGE_DIR/agents/universal/system-architect.md"
    assert_success
}

@test "Agent contract: system-architect has Quality Tiers" {
    run grep "Quality Tiers" "$FORGE_DIR/agents/universal/system-architect.md"
    assert_success
}

@test "Agent contract: requirements-analyst has Input Contract" {
    run grep "Input Contract" "$FORGE_DIR/agents/universal/requirements-analyst.md"
    assert_success
}

@test "Agent contract: devops-architect has Input Contract" {
    run grep "Input Contract" "$FORGE_DIR/agents/universal/devops-architect.md"
    assert_success
}

@test "Agent contract: reviewer has Input Contract" {
    run grep "Input Contract" "$FORGE_DIR/agents/universal/reviewer.md"
    assert_success
}

# ─── HOOKS ───

@test "Hooks: PostToolUse Agent has handoff check" {
    run grep "forge-handoff-check" "$FORGE_DIR/templates/hooks.json"
    assert_success
}

@test "Hooks: Stop has S9 gate" {
    run grep "S9 review" "$FORGE_DIR/templates/hooks.json"
    assert_success
}

@test "Hooks: pre-commit has registry auto-regeneration" {
    run grep "forge-registry" "$FORGE_DIR/templates/pre-commit"
    assert_success
}

# ─── SCRIPTS ───

@test "Script: forge-handoff-check.sh exists" {
    assert [ -f "$FORGE_DIR/scripts/forge-handoff-check.sh" ]
    assert [ -x "$FORGE_DIR/scripts/forge-handoff-check.sh" ]
}

@test "Script: handoff check uses fixed-string grep" {
    run grep "grep -qFi" "$FORGE_DIR/scripts/forge-handoff-check.sh"
    assert_success
}

@test "Script: handoff check fails closed on no dimensions" {
    run grep "FAIL CLOSED\|No dimensions found" "$FORGE_DIR/scripts/forge-handoff-check.sh"
    assert_success
}
