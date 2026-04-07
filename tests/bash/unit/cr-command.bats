#!/usr/bin/env bats
# Tests for /cr — CodeRabbit integration command

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    FORGE_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
    export FORGE_DIR
    CR_CMD="$FORGE_DIR/commands/cr.md"
}

teardown() {
    _common_teardown
}

# ─── FILE EXISTS ───

@test "/cr command file exists" {
    assert [ -f "$CR_CMD" ]
}

@test "/cr has heading" {
    run grep "^# /cr" "$CR_CMD"
    assert_success
}

# ─── SUBCOMMANDS ───

@test "/cr has review subcommand" {
    run grep -i "review.*Trigger.*incremental\|@coderabbitai review" "$CR_CMD"
    assert_success
}

@test "/cr has full-review subcommand" {
    run grep -i "full.review.*from scratch\|@coderabbitai full review" "$CR_CMD"
    assert_success
}

@test "/cr has plan subcommand" {
    run grep -i "plan.*implementation\|@coderabbitai plan" "$CR_CMD"
    assert_success
}

@test "/cr has tests subcommand" {
    run grep -i "generate unit tests\|@coderabbitai generate unit tests" "$CR_CMD"
    assert_success
}

@test "/cr has diagram subcommand" {
    run grep -i "sequence diagram\|@coderabbitai generate sequence diagram" "$CR_CMD"
    assert_success
}

@test "/cr has autofix subcommand" {
    run grep -i "autofix\|@coderabbitai autofix" "$CR_CMD"
    assert_success
}

@test "/cr has resolve subcommand" {
    run grep -i "resolve.*comments\|@coderabbitai resolve" "$CR_CMD"
    assert_success
}

@test "/cr has check subcommand" {
    run grep -i "pre-merge check\|evaluate custom" "$CR_CMD"
    assert_success
}

@test "/cr has status subcommand" {
    run grep -i "status.*review state\|APPROVED\|CHANGES_REQUESTED" "$CR_CMD"
    assert_success
}

@test "/cr has approve subcommand" {
    run grep -i "approve.*exit code\|Exit 0.*APPROVED" "$CR_CMD"
    assert_success
}

# ─── INTEGRATION ───

@test "/cr has gate integration" {
    run grep -i "/gate.*cr approve\|gate.*block.*CR" "$CR_CMD"
    assert_success
}

@test "/cr has forge flow diagram" {
    run grep -i "push.*cr review.*fix.*resolve.*approve.*gate.*merge" "$CR_CMD"
    assert_success
}

@test "/cr has system-reminder for mandatory review" {
    run grep "MANDATORY.*reviewer\|NEVER merge without CR" "$CR_CMD"
    assert_success
}

@test "/cr has custom pre-merge checks with forge rules" {
    run grep -i "HANDOFF METRIC\|valid JSON\|PLACEHOLDERS\|300 lines" "$CR_CMD"
    assert_success
}

# ─── SAFETY ───

@test "/cr checks for PR existence before running" {
    run grep "No PR found\|Create one first" "$CR_CMD"
    assert_success
}

@test "/cr waits for CR response" {
    run grep -i "Wait.*30.*60.*second\|processing time" "$CR_CMD"
    assert_success
}
