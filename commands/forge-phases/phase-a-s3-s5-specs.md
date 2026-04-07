**STEP S3: GENERATE CLAUDE.md** → @system-architect agent

HANDOFF METRIC (S3):
  MUST PROPAGATE from discovery notes → CLAUDE.md:
    - Every COMPLIANCE[] item → at least 1 MUST/NEVER rule in Architecture Rules
    - Every STACK item → row in Tech Stack table with version
    - Every EXCLUDED[] item → bullet in "What NOT to Build"
    - Every INTEGRATIONS[] item → Integration Rules section (if any)
    - A11Y requirements → MUST/NEVER rule in Architecture Rules (if confirmed, e.g., "MUST meet WCAG 2.1 AA")
    - SUCCESS criteria → referenced in Architecture Rules or Testing section (if measurable)
  MUST NOT APPEAR:
    - Architecture rules for items in EXCLUDED[]
    - Compliance rules for compliance items user rejected in Q5

PM MUST first:
1. Read docs/forge-trace/A02_phase-a_step-s2_discovery-notes.md → extract ACTUAL values (not placeholders)
2. Read templates/CLAUDE.template.md → follow exact structure
3. Fetch latest docs: spawn @context-loader-agent for {STACK_BACKEND} framework (MANDATORY)
4. Optionally read ~/.claude/stacks/{STACK_BACKEND}/rules.md for reference (NEVER override internet research with registry)

Execute: spawn Agent with subagent_type="system-architect"
  prompt: |
    Generate CLAUDE.md for a new project. Follow these rules STRICTLY:

    PROJECT INFO (PM reads actual values from docs/forge-trace/A02_phase-a_step-s2_discovery-notes.md):
    - Name: {name}
    - Description: {description}
    - Stack: {STACK_BACKEND} + {STACK_FRONTEND} + {STACK_DB}
    - Features: {features}
    - Excluded: {excluded}
    - Compliance: {compliance} (from domain inference — generate MUST/NEVER rules)
    - Deployment: {deployment} (cloud/on-prem/hybrid constraints)
    - Scale: {scale} (architecture implications)
    - Integrations: {integrations} (third-party services to plan for)
    - A11Y: {a11y} (accessibility rules if required)
    - Success criteria: {success} (what "done" looks like)
    - Stack registry rules: {stack_rules} (proven rules from previous builds, if any)

    TEMPLATE (MUST follow this structure — under 100 lines):
    ```
    # {project_name}

    {one_line_description}

    ## Tech Stack

    | Layer | Technology | Notes |
    |---|---|---|
    {rows from stack choices — include version + "NOT X" exclusions}

    ## Architecture Rules

    <system-reminder>
    These rules override your defaults. Re-read before every task.
    </system-reminder>

    {numbered rules, MUST/NEVER format, with code snippets}
    RULES HAVE 3 CATEGORIES:

    **Category 1: DYNAMIC (generated from Q4 stack choice + Q4.5 decisions + research)**
    - MUST research trending best practices for {STACK_BACKEND} + {STACK_FRONTEND} in {current_year}
    - MUST generate MUST/NEVER rules from research findings
    - MUST reference the SPECIFIC tools/libraries the user chose in Q4
    - MUST include code snippets for critical patterns (concurrency, auth, validation)
    - MUST incorporate Q4.5 decisions (e.g., ARCH_PATTERN=monolith → "MUST keep all code in single deployable")
    - NEVER generate rules for frameworks the user did not choose
    - NEVER override user's Q4 tech choice with forge or registry preferences

    **Category 2: UNIVERSAL SAFETY (always included — not tool choices, these are invariants)**
    - "MUST read all credentials from os.environ — NEVER hardcode secrets"
    - "MUST sanitize all user input at system boundaries"
    - "MUST sanitize LLM output before storage or display" (if AI features)
    - "MUST use presigned URLs for file access — NEVER serve files directly" (if file uploads)
    - "MUST keep files under 300 lines — split if exceeding"

    **Category 3: FEATURE-CONDITIONAL (only if confirmed in Q5)**
    - Multi-tenant → tenant isolation rules (only if multi-tenant confirmed)
    - AI/LLM → model versioning, cost controls, fallback rules (only if AI confirmed)
    - Compliance → regulation-specific rules from domain-inference-rules.md (only if compliance confirmed)

    ## Compliance Rules
    <!-- Only if compliance confirmed in discovery. Omit section entirely if none. -->
    {MUST/NEVER rules from domain-inference-rules.md Security Signals table}
    {e.g., "MUST encrypt all patient data at rest and in transit" for HIPAA}

    ## Integration Rules
    <!-- Only if integrations confirmed in discovery. Omit section entirely if none. -->
    {Rules for each confirmed third-party integration}

    ## What NOT to Build

    {bullet list from excluded items}

    ## Testing

    - {test command based on stack}
    - {lint command based on stack}
    - {test base class rule if applicable}

    ## Lessons Learned

    <!-- Updated by /retro. Each rule prevents a real past mistake. -->
    ```

    OUTPUT REQUIREMENTS:
    - Under 100 lines
    - Every rule is MUST or NEVER (no "prefer" or "consider")
    - Include code snippets where applicable
    - Tables for structured data
    - Anti-scope list from user's "NEVER include" answer

Verify: `wc -l CLAUDE.md` → at least 20 lines, under 100 lines (too short = missing rules)
Verify: `grep -c "MUST\|NEVER" CLAUDE.md` → at least 5 binary rules
Verify: has ## Tech Stack, ## Architecture Rules, ## What NOT to Build, ## Testing sections
Trace: save to docs/forge-trace/S3-claude-md/

**STEP S4: GENERATE SPEC.md** → @requirements-analyst agent

HANDOFF METRIC (S4):
  MUST PROPAGATE from discovery notes → SPEC.md:
    - Every FEATURE → at least 1 [REQ-xxx]
    - Every COMPLIANCE[] → [REQ-COMPLIANCE-xxx] with proof citation
    - Every INTEGRATION → [REQ-INT-xxx]
    - SUCCESS criteria → [REQ-SUCCESS-xxx] with measurable target
    - SCALE → [REQ-SCALE-xxx] with NUMBERS not "fast"
    - A11Y → [REQ-A11Y-xxx] if confirmed
    - I18N → [REQ-I18N-xxx] if confirmed
    - MOBILE → [REQ-MOBILE-xxx] if confirmed
    - Every USERS[] type → referenced in at least one REQ (via API auth levels, permissions, or user-facing features)
  MUST NOT APPEAR:
    - Any [REQ-xxx] for items in EXCLUDED[] list
    - Requirements for features user rejected in Q5

Execute: spawn Agent with subagent_type="requirements-analyst"
  prompt: |
    Generate SPEC.md for the project. Follow templates/SPEC.template.md STRICTLY.

    PROJECT INFO (from discovery notes):
    - Name: {name}
    - Stack: {STACK_BACKEND} + {STACK_FRONTEND} + {STACK_DB}
    - Features: {features}
    - Users: {users}
    - Excluded: {excluded} (NEVER generate requirements for excluded items)
    - Success criteria: {success} (generate [REQ-SUCCESS-xxx] for each)
    - Compliance: {compliance} (generate [REQ-COMPLIANCE-xxx] for each)
    - Scale: {scale} (generate [REQ-SCALE-xxx] with NUMBERS not "fast")
    - Integrations: {integrations} (generate [REQ-INT-xxx] for each)
    - A11Y: {a11y} (generate [REQ-A11Y-xxx] if required)
    - I18N: {i18n} (generate [REQ-I18N-xxx] if required)
    - Mobile: {mobile} (generate [REQ-MOBILE-xxx] if required)

    REQUIREMENTS:
    - Start from [REQ-001]
    - Every feature gets at least 2-3 requirements
    - Each requirement has ONE clear behavior (not compound)
    - Use domain-prefixed IDs: REQ-AUTH-001, REQ-UI-001, REQ-COMPLIANCE-001, REQ-SCALE-001, REQ-INT-001, REQ-SUCCESS-001, REQ-A11Y-001, REQ-I18N-001, REQ-MOBILE-001
    - Include non-functional requirements (performance, security, compliance, accessibility)
    - Every inferred requirement carries a proof citation (URL or domain-inference-rules.md reference)
    - ANTI-SCOPE ENFORCEMENT: NEVER generate a [REQ-xxx] for any item in the EXCLUDED list

    SPEC MUST INCLUDE:
    - ## Overview (2-3 paragraphs + scale target + deployment model)
    - ## Tech Stack (table matching CLAUDE.md)
    - ## Architecture (project structure tree)
    - ## Models (with field types, relationships, constraints)
      - Each model tagged with [REQ-xxx]
      - Field types are EXACT (CharField(max_length=200), not just "string")
    - ## API Endpoints (table: method, path, auth, description, [REQ-xxx])
    - ## Compliance & Security (if compliance confirmed — regulations, encryption, audit)
    - ## Third-Party Integrations (if integrations confirmed — service, purpose, [REQ-INT-xxx])
    - ## Frontend Pages (if applicable)
    - ## Requirements Traceability (table: [REQ-xxx] | description | proof | status)

    Minimum 20 [REQ-xxx] tags.

Verify: `grep -c "REQ-" SPEC.md` → at least 20
Verify: has ## Models, ## API Endpoints, ## Requirements Traceability sections
Trace: save to docs/forge-trace/S4-spec-md/

**STEP S5: GENERATE FORGE.md** → PM (simple, no agent needed)

HANDOFF METRIC (S5):
  MUST PROPAGATE: PROJECT_NAME and description from discovery notes in QUEUED entry
  MUST NOT APPEAR: N/A (simple template)

PM writes FORGE.md from template:
```markdown
# FORGE.md — Work Queue

## Active
<!-- Currently being worked on -->

## Queued
- type: NEW_PROJECT
  description: {project description from discovery}
  status: QUEUED
  created: $(date +%Y-%m-%d)

## Done
<!-- Completed items -->
```

Verify: file exists with QUEUED entry
Trace: save to docs/forge-trace/S5-forge-md/

