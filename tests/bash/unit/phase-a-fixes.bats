#!/usr/bin/env bats
# Tests for Phase A fixes — one test per CR finding
# Each test verifies the fix is present in phase-a-setup.md

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    FORGE_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
    export FORGE_DIR
    PHASE_A="$FORGE_DIR/commands/forge-phases/phase-a-setup.md"
}

teardown() {
    _common_teardown
}

# ─── #129: git init guard in S1 ───

@test "Phase A S1 has git init guard" {
    run grep "git init" "$PHASE_A"
    assert_success
}

@test "Phase A S1 does NOT re-detect project type" {
    run grep -iE "already done|NOT re-detect|hook.*before|UserPromptSubmit" "$PHASE_A"
    assert_success
}

@test "Phase A S1 creates directories for S3-S9" {
    run grep "mkdir.*docs/forge-trace" "$PHASE_A"
    assert_success
}

# ─── Batch 1: S2 Question Fixes ───

# #135: Q7 'change' branch defined
@test "Phase A Q7 has change flow defined" {
    run grep -iE "change.*flow|change.*re-ask|change.*which|modify.*answer|On.*change.*ask" "$PHASE_A"
    assert_success
}

# #138: Credential discovery in Q5
@test "Phase A has credential/API key question" {
    run grep -iE "credential|API.key|api.secret|OPENAI|AWS.*KEY|env.*key" "$PHASE_A"
    assert_success
}

# #146: Q4 forge-stack.sh fallback
@test "Phase A Q4 has fallback if forge-stack.sh absent" {
    run grep -E "2>/dev/null.*||.*No stack|stack.*not found|fallback" "$PHASE_A"
    assert_success
}

# #147: Q3 web search fallback
@test "Phase A Q3 has fallback if web search returns nothing" {
    run grep -iE "no competitor|nothing found|skip competitor|no result" "$PHASE_A"
    assert_success
}

# ─── Batch 2: S3-S5 Generation Fixes ───

# #131: System-reminder allows PM to write FORGE.md
@test "Phase A system-reminder does NOT forbid FORGE.md" {
    # Should say "NEVER writes CLAUDE.md or SPEC.md" not "FORGE.md"
    run grep "NEVER writes CLAUDE.md, SPEC.md, or FORGE.md" "$PHASE_A"
    assert_failure  # This old text should NOT exist
}

# #133: Stack learnings injected into agent prompts
@test "Phase A S3 prompt includes stack learnings" {
    run grep -iE "STACK_LEARNINGS|stack.*learnings|learnings.*apply|past.*build.*lessons" "$PHASE_A"
    assert_success
}

# #139: Stack rules flexible not Django-only
@test "Phase A S3 has rules for multiple stacks not just Django" {
    run grep -iE "For FastAPI|For Next|For Go|For any|stack-specific|based on stack" "$PHASE_A"
    assert_success
}

# #140: CLAUDE.md has minimum line count
@test "Phase A S3 verifies CLAUDE.md has minimum content" {
    run grep -iE "at least.*lines|minimum.*lines|min.*line|too short" "$PHASE_A"
    assert_success
}

# #143: S5 uses real date not literal
@test "Phase A S5 uses date command not literal {today}" {
    # Should NOT have literal {today's date}
    run grep "{today's date}" "$PHASE_A"
    assert_failure  # This literal should NOT exist
}

# ─── Batch 3: S6-S8 Infrastructure Fixes ───

# #136: S6 uses real variable not literal {stack}
@test "Phase A S6 stack check uses variable not literal {stack}" {
    # Should use $STACK or actual variable, not literal {stack}
    run grep -c 'STACK_DIR=.*\$' "$PHASE_A"
    [[ "$output" -gt 0 ]]
}

# #137: S8 hook path correct
@test "Phase A S8 copies hooks from correct path" {
    run grep "templates/hooks.json\|settings.json" "$PHASE_A"
    assert_success
}

# #145: S8 has JSON validation command
@test "Phase A S8 validates JSON after copy" {
    run grep -iE "jq.*settings|python.*json.*settings|valid.*JSON|json\.tool" "$PHASE_A"
    assert_success
}

# #157: S6 sdlc-flow has fill instructions
@test "Phase A S6 has sdlc-flow fill instructions" {
    run grep -iE "sdlc.*flow.*fill|sdlc.*template|project.*specific.*stages" "$PHASE_A"
    assert_success
}

# #158: S9 checks for 9 hooks not 8
@test "Phase A S9 checks for correct hook count" {
    # Should NOT say "8 hooks" — we have 9
    run grep "all 8 hooks\|Has all 8" "$PHASE_A"
    assert_failure
}

# ─── Batch 4: S9 + State Fixes ───

# #132: Phase A state persistence
@test "Phase A has state persistence for context limit recovery" {
    run grep -iE "phase-a.*json|phase.a.*progress|phase.a.*state|S[0-9].*DONE|resume.*Phase A" "$PHASE_A"
    assert_success
}

# #156: S1 partial setup detection
@test "Phase A S1 checks for partial setup" {
    run grep -iE "partial|incomplete|missing.*scaffold|SPEC.*but.*no|CLAUDE.*but.*no.*forge" "$PHASE_A"
    assert_success
}

# #159: S9 fix path defined
@test "Phase A S9 has defined fix path with agent and max retries" {
    run grep -iE "fix.*re-review|retry.*review|max.*iteration|agent.*fix|who.*fix" "$PHASE_A"
    assert_success
}

# ─── From closed PR #167 — missing tests ───

# #144: Scaffold files — check individually
@test "Phase A S7 mentions conftest" {
    run grep -i "conftest" "$PHASE_A"
    assert_success
}

@test "Phase A S7 mentions .env.example" {
    run grep -i ".env.example" "$PHASE_A"
    assert_success
}

# #153: Multi-stack support
@test "Phase A Q4 supports backend + frontend stacks" {
    run grep -iE "backend.*frontend|full.stack|EACH stack" "$PHASE_A"
    assert_success
}

# #154: Recovery path
@test "Phase A has failure recovery with full path" {
    run grep "forge-infra-check.sh --reset" "$PHASE_A"
    assert_success
}
