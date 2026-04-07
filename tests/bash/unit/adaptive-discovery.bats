#!/usr/bin/env bats
# Tests for adaptive discovery implementation (#178)

setup() {
    load '../../test_helper/common-setup'
    _common_setup
    FORGE_DIR="$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)"
    export FORGE_DIR
    PHASE_A_DIR="$FORGE_DIR/commands/forge-phases"
    # Search all Phase A files (main + sub-files)
    PHASE_A_FILES="$PHASE_A_DIR/phase-a-setup.md $PHASE_A_DIR/phase-a-s2-discovery.md $PHASE_A_DIR/phase-a-s3-s5-specs.md $PHASE_A_DIR/phase-a-s6-s8-scaffold.md $PHASE_A_DIR/phase-a-s9-s10-review.md"
    PHASE_A="$PHASE_A_DIR/phase-a-s2-discovery.md"
}

teardown() {
    _common_teardown
}

# ─── domain-inference-rules.md ───

@test "domain-inference-rules.md exists" {
    assert [ -f "$FORGE_DIR/docs/domain-inference-rules.md" ]
}

@test "domain-inference-rules has healthcare domain" {
    run grep -i "healthcare\|clinic\|medical" "$FORGE_DIR/docs/domain-inference-rules.md"
    assert_success
}

@test "domain-inference-rules has HIPAA for healthcare" {
    run grep "HIPAA" "$FORGE_DIR/docs/domain-inference-rules.md"
    assert_success
}

@test "domain-inference-rules has ecommerce domain" {
    run grep -i "ecommerce\|shop\|store" "$FORGE_DIR/docs/domain-inference-rules.md"
    assert_success
}

@test "domain-inference-rules has fintech domain" {
    run grep -i "fintech\|banking\|payments" "$FORGE_DIR/docs/domain-inference-rules.md"
    assert_success
}

@test "domain-inference-rules has deep-dive triggers" {
    run grep -i "deep.dive\|trigger" "$FORGE_DIR/docs/domain-inference-rules.md"
    assert_success
}

@test "domain-inference-rules has confidence levels" {
    run grep -i "confidence\|95%\|80%" "$FORGE_DIR/docs/domain-inference-rules.md"
    assert_success
}

@test "domain-inference-rules has security signals" {
    run grep -i "security signal\|MUST encrypt\|NEVER store" "$FORGE_DIR/docs/domain-inference-rules.md"
    assert_success
}

# ─── S2 adaptive discovery in phase-a-setup.md ───

@test "S2 has discovery notes artifact reference" {
    run grep "A02_phase-a_step-s2_discovery-notes" "$PHASE_A"
    assert_success
}

@test "S2 has Q3.5 success criteria question" {
    run grep -i "success.*look.*like\|success.*6 months\|Q3.5" "$PHASE_A"
    assert_success
}

@test "S2 has smart two-part Q5" {
    run grep -i "Part A.*Inferred\|Part B.*Additional" "$PHASE_A"
    assert_success
}

@test "S2 has deep-dive trigger conditions" {
    run grep -i "DEEP.DIVE TRIGGER\|HIGH_RISK.*confirmed" "$PHASE_A"
    assert_success
}

@test "S2 has 14 dimensions in Q7 summary" {
    for dim in PROJECT USERS PROBLEM SUCCESS STACK FEATURES COMPLIANCE SCALE DEPLOYMENT INTEGRATIONS A11Y I18N MOBILE EXCLUDED; do
        run grep "$dim:" "$PHASE_A"
        assert_success
    done
}

@test "S2 has completion gate" {
    run grep -i "S2 COMPLETION GATE\|must exist.*before S3" "$PHASE_A"
    assert_success
}

@test "S2 references domain-inference-rules.md" {
    run grep "domain-inference-rules" "$PHASE_A"
    assert_success
}

@test "S2 writes proof citations" {
    run grep -iE "proof citation|proof:|sources captured|research result" "$PHASE_A"
    assert_success
}

# ─── S2 inference chain — explicit INPUTS/OUTPUTS per question ───

@test "S2 has variable chain reference card" {
    run grep -i "VARIABLE CHAIN\|Q1.*outputs.*INTENT_SEED\|Q1.*INTENT_SEED.*PROJECT_NAME" "$PHASE_A"
    assert_success
}

@test "S2 has per-question protocol definition" {
    run grep -c "INPUTS:" "$PHASE_A"
    # Q1-Q7 = 7 questions, each with INPUTS
    assert_success
    [ "$output" -ge 7 ]
}

@test "S2 has per-question OUTPUTS" {
    run grep -c "OUTPUTS:" "$PHASE_A"
    assert_success
    [ "$output" -ge 7 ]
}

@test "S2 Q2 declares inputs from Q1" {
    run grep -i "INPUTS:.*INTENT_SEED\|INPUTS:.*DOMAIN" "$PHASE_A"
    assert_success
}

@test "S2 Q3 declares inputs from Q1+Q2" {
    run grep -i "INPUTS:.*USERS" "$PHASE_A"
    assert_success
}

# ─── S2 accumulated context — user sees their words reflected ───

@test "S2 has accumulated context sections" {
    run grep -c "ACCUMULATED CONTEXT" "$PHASE_A"
    assert_success
    # Q2-Q7 = 6 questions have accumulated context (Q1 has none — first question)
    [ "$output" -ge 6 ]
}

# ─── S2 hints for unsure users ───

@test "S2 has hints for every question" {
    run grep -c "HINTS:" "$PHASE_A"
    assert_success
    [ "$output" -ge 7 ]
}

@test "S2 hints reference domain context" {
    run grep -i "Not sure.*domain\|Not sure.*for.*project" "$PHASE_A"
    assert_success
}

# ─── S2 fallback for unclear answers ───

@test "S2 has fallback for every question" {
    run grep -c "FALLBACK:" "$PHASE_A"
    assert_success
    [ "$output" -ge 7 ]
}

@test "S2 fallback handles I don't know" {
    run grep -i "don.t know\|I don.t know" "$PHASE_A"
    assert_success
}

# ─── S2 dynamic search — uses accumulated variables ───

@test "S2 has dynamic search sections" {
    run grep -c "DYNAMIC SEARCH" "$PHASE_A"
    assert_success
    [ "$output" -ge 7 ]
}

@test "S2 dynamic search uses accumulated variables" {
    # Q3 search should reference DOMAIN + INTENT_SEED + USERS (accumulated from Q1+Q2)
    run grep -i "DOMAIN.*INTENT_SEED\|INTENT_SEED.*DOMAIN" "$PHASE_A"
    assert_success
}

# ─── S2 option explanations — WHY + proof ───

@test "S2 options have WHY explanations with proof" {
    run grep -i "required.*proof:\|recommended.*proof:" "$PHASE_A"
    assert_success
}

# ─── S2 transition statements ───

@test "S2 has transition after each question" {
    run grep -c "TRANSITION:" "$PHASE_A"
    assert_success
    [ "$output" -ge 7 ]
}

# ─── S3 has new variables ───

@test "S3 prompt has compliance variable" {
    run grep "Compliance:.*{compliance}" $PHASE_A_FILES
    assert_success
}

@test "S3 prompt has deployment variable" {
    run grep "Deployment:.*{deployment}" $PHASE_A_FILES
    assert_success
}

# ─── S4 has fixed {excluded} + new variables ───

@test "S4 prompt has {excluded} variable" {
    run grep "Excluded:.*{excluded}" $PHASE_A_FILES
    assert_success
}

@test "S4 prompt has anti-scope enforcement" {
    run grep -i "NEVER generate.*EXCLUDED\|anti.scope" $PHASE_A_FILES
    assert_success
}

@test "S4 generates proof-backed REQ types" {
    run grep "REQ-COMPLIANCE\|REQ-SCALE\|REQ-INT\|REQ-SUCCESS" $PHASE_A_FILES
    assert_success
}

@test "S4 has 4-column traceability table" {
    run grep "proof.*status\|REQ.*description.*proof" $PHASE_A_FILES
    assert_success
}

# ─── S9 review has new sections ───

@test "S9 reviews discovery notes" {
    run grep -i "Discovery Notes.*exists\|discovery.*notes.*14" $PHASE_A_FILES
    assert_success
}

@test "S9 checks anti-scope enforcement" {
    run grep -i "EXCLUDED.*accidentally\|anti.scope.*present" $PHASE_A_FILES
    assert_success
}

# ─── Templates updated ───

@test "SPEC template has compliance section" {
    run grep "COMPLIANCE_REQUIREMENTS" "$FORGE_DIR/templates/SPEC.template.md"
    assert_success
}

@test "SPEC template has integrations section" {
    run grep "Third-Party Integrations\|INTEGRATION" "$FORGE_DIR/templates/SPEC.template.md"
    assert_success
}

@test "SPEC template has scale section" {
    run grep "SCALE_REQUIREMENTS\|DEPLOYMENT_TARGET" "$FORGE_DIR/templates/SPEC.template.md"
    assert_success
}

@test "CLAUDE template has compliance rules section" {
    run grep "Compliance Rules\|COMPLIANCE_RULES" "$FORGE_DIR/templates/CLAUDE.template.md"
    assert_success
}

@test "CLAUDE template has integration rules section" {
    run grep "Integration Rules\|INTEGRATION_RULES" "$FORGE_DIR/templates/CLAUDE.template.md"
    assert_success
}

# ─── Design doc checklist updated ───

@test "checklist has discovery notes check" {
    run grep "discovery-notes\|A02_phase-a" "$FORGE_DIR/templates/design-doc-completeness-checklist.md"
    assert_success
}

@test "checklist has REQ-COMPLIANCE check" {
    run grep "REQ-COMPLIANCE" "$FORGE_DIR/templates/design-doc-completeness-checklist.md"
    assert_success
}

@test "checklist has anti-scope final check" {
    run grep "EXCLUDED.*anti-scope\|anti-scope.*list" "$FORGE_DIR/templates/design-doc-completeness-checklist.md"
    assert_success
}

@test "checklist has proof chain check" {
    run grep "proof chain\|proof.*citation\|traceable.*URL" "$FORGE_DIR/templates/design-doc-completeness-checklist.md"
    assert_success
}

# ─── Manifesto exists ───

@test "manifesto.md exists" {
    assert [ -f "$FORGE_DIR/docs/manifesto.md" ]
}

@test "manifesto mentions safety layers" {
    run grep "Safety Layers" "$FORGE_DIR/docs/manifesto.md"
    assert_success
}

