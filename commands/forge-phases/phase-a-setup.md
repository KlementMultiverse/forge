### CASE 1: NEW PROJECT (no CLAUDE.md or placeholder CLAUDE.md)

#### Phase A — Setup (Session 1: creates all files agents need)

<!-- Architecture: PM behaviors (self-correction, anti-patterns, confidence routing,
     chaos resilience) are auto-loaded from rules/pm-behaviors.md via Pipe 1.
     This file contains only the TASK STEPS (what to do), not PM behaviors (how to behave). -->

<system-reminder>
SESSION 1 RULES:
- PM behaviors auto-loaded from rules/pm-behaviors.md (self-correction, anti-patterns, handoff protocol)
- PM orchestrates but NEVER writes CLAUDE.md or SPEC.md directly (FORGE.md is simple enough for PM)
- Each file is built by a SPECIALIST AGENT following a TEMPLATE
- Every agent output is VERIFIED before proceeding (rate >= 4, retry if < 4, max 3)
- Session 1 ends with "Setup complete. Run forge again to build."
- NO CODE IS WRITTEN in Session 1 — only planning/spec/config files
</system-reminder>

---

**UNIVERSAL AGENT EXECUTION LOOP** (apply to EVERY agent spawn in ALL phases)

<system-reminder>
This loop is NON-OPTIONAL. Every agent spawn MUST follow it. Hooks report handoff status after each agent (advisory); PM MUST act on MISSING/INCOMPLETE reports.
Discovery notes = single source of truth. Autoresearch is BOUNDED — NEVER invents new requirements.
</system-reminder>

```text
1. PREPARE:
   PM reads input artifact (discovery notes / SPEC / previous step output)
   PM reads agent-specific context (stack registry, templates, prior traces)
   PM prepares prompt with ALL accumulated context

2. DEFINE HANDOFF METRIC (per-step — see each STEP below):
   MUST PROPAGATE: items from input that MUST appear in output
   MUST NOT APPEAR: items from EXCLUDED / rejected items

3. ATTEMPT 1:
   Spawn agent with prepared prompt → receive output

4. MEASURE (BOUNDED by discovery notes — NEVER invent):
   FOR EACH item in MUST PROPAGATE:
     Present in output? → COVERED
     Missing?           → MISSING
     Partial?           → INCOMPLETE
   FOR EACH item in output not traceable to input:
     → INVENTED (flag for removal — agent hallucinated this)
   SCORE = COVERED / (COVERED + MISSING + INCOMPLETE + INVENTED)
   Note: INVENTED items reduce the score — hallucinations are failures too

5. IF SCORE < 100%:
   AUTORESEARCH (BOUNDED enhancement — ADD context, NEVER remove):
     - List MISSING items with exact quotes from discovery notes
     - List INCOMPLETE items with what needs more detail
     - List INVENTED items to remove
     - ENHANCE prompt: keep ALL of previous prompt + append:
       "YOU MISSED: [exact items from discovery notes]"
       "REMOVE: [invented items not in discovery notes]"
       "INCOMPLETE: [items needing more detail]"
   → ATTEMPT 2 with enhanced prompt → MEASURE again

6. IF STILL < 100%: further enhance → ATTEMPT 3 → MEASURE

7. IF ALL 3 ATTEMPTS < 100%:
   ESCALATE to user: "After 3 attempts, best score is {SCORE}%. Missing: [list]. Should I proceed with best output or do you want to adjust discovery notes?"
   User decides: proceed with best (accept gaps) OR update discovery notes → re-run

8. IF CRITICAL GAP FOUND (agent discovers something missing from input):
   RAISE QUESTION to user: "I found a gap: {gap}. Should I add {X}?"
   User answers → update discovery notes → re-run with updated input
   This is the ONLY way new info enters (via user, not agent invention)

9. PICK BEST output (highest SCORE from 3 attempts)

10. REVERSE ENGINEER + CROSS-VERIFY (bidirectional):
    FORWARD:  Does previous step output data appear in current output?
    BACKWARD: Does current output data trace back to previous step?
    Mismatch → flag and fix or raise question to user

11. RATE: spawn @reviewer (1-5, must be >= 4)
    Rating uses a SEPARATE retry budget (max 2 re-reviews, independent of the 3 prompt attempts)
    If < 4 after 2 re-reviews: escalate to user

12. PROCEED to next step with verified output
```

**BOUNDED AUTORESEARCH RULES:**
- Discovery notes are the SINGLE SOURCE OF TRUTH
- NEVER invent requirements not in discovery notes
- NEVER override user decisions from S2
- NEVER add compliance user explicitly rejected
- Enhance = ADD more context from discovery notes, NEVER remove existing prompt
- The ONLY way new info enters is via user answering a RAISED QUESTION

---

**STEP S1: PREPARE** (PM prepares workspace — no agents)

NOTE: Project type detection (GREENFIELD/BROWNFIELD/EXISTING) was already done by the UserPromptSubmit hook before reaching this file. S1 does NOT re-detect — it only prepares the workspace.

```bash
# 1. Ensure git repo (user may have forgotten git init)
if [ ! -d ".git" ]; then
    git init -b main
    echo "[FORGE] Initialized git repository"
fi

# 2. Create directories needed by S3-S9
mkdir -p docs/forge-trace docs/proposals docs/retrospectives

# 3. Check for partial setup (Phase A was interrupted previously)
# If CLAUDE.md exists but SPEC.md or .forge/ is missing → resume from missing step
```

Based on partial setup check:
- Nothing exists → continue to STEP S2 (full setup)
- CLAUDE.md exists but no SPEC.md → resume at S4
- CLAUDE.md + SPEC.md but no scaffold → resume at S7
- Incomplete setup (CLAUDE.md but missing .forge/) → resume from missing step
- Everything exists → "Setup already complete. Run /forge again to build."

**STEP S2: ADAPTIVE DISCOVERY** (PM only — gathers information with research + proof)

<system-reminder>
S2 ARTIFACT: docs/forge-trace/A02_phase-a_step-s2_discovery-notes.md
This file captures EVERY research result, inference, and user decision as proof.
S3 is GATED on this file existing and being complete (all dimensions resolved).
PM must NOT exit S2 until discovery notes have all 14 fields filled.
</system-reminder>

PM asks questions ONE AT A TIME. Each question follows the **Per-Question Protocol**:

**Per-Question Protocol (8 parts — ALL mandatory):**
1. INPUTS: variables from previous questions this one depends on
2. OUTPUTS: new variables this question produces
3. ACCUMULATED CONTEXT: restate what PM knows from all previous answers (spoken TO the user — they see their words reflected)
4. DYNAMIC SEARCH: web search queries built from ALL accumulated variables (not static templates)
5. QUESTION + OPTIONS: the question, with options that each have WHY explanations and proof citations
6. HINTS: domain-specific suggestions for unsure users ("Not sure? Here's what's typical...")
7. FALLBACK: if user says "I don't know" → PM suggests domain defaults; if vague → PM asks ONE clarifying follow-up (max 1)
8. TRANSITION: PM tells user what was inferred + what comes next (visible inference chain)

**Inference Chain Rule:** Every question MUST reference its input variables when framing the question, search queries, and options. The user must see HOW previous answers shaped the current question.

**VARIABLE CHAIN (reference card — PM consults this before each question):**
```text
Q1 outputs:  INTENT_SEED, PROJECT_NAME, DOMAIN, COMPLIANCE[], HIGH_RISK
Q2 inputs:   INTENT_SEED + DOMAIN
   outputs:  USERS[], SCALE_TIER, A11Y_REQUIRED, I18N_REQUIRED, DEPLOYMENT_HINTS[]
Q3 inputs:   INTENT_SEED + DOMAIN + USERS[]
   outputs:  PROBLEM, CURRENT_SOLUTION, COMPETITORS[], MOBILE_REQUIRED, INTEGRATIONS[]
Q3.5 inputs: INTENT_SEED + DOMAIN + USERS[] + PROBLEM + COMPETITORS[]
   outputs:  SUCCESS_CRITERIA[], SCALE_UPDATE
Q4 inputs:   INTENT_SEED + DOMAIN + SCALE_TIER + COMPLIANCE[] + MOBILE_REQUIRED + SUCCESS_CRITERIA[]
   outputs:  STACK_BACKEND, STACK_FRONTEND, STACK_DB, STACK_AI, CLOUD_PROVIDER, HOSTING_MODEL
Q4.5 inputs: ALL Q4 outputs + COMPLIANCE[] + SCALE_TIER + FEATURES_HINTED
   outputs:  ARCH_PATTERN, AUTH_STRATEGY, API_PATTERN, DATA_MODEL, AI_PATTERN, REALTIME_PATTERN, DEPLOY_STRATEGY
   derived:  COST_ESTIMATE (shown to user, not a mutable input)
Q5 inputs:   ALL accumulated variables (including Q4.5)
   outputs:  FEATURES_CONFIRMED[], FEATURES_REJECTED[], FEATURES_ADDITIONAL[], DEEP_DIVE_TRIGGERED
Q6 inputs:   FEATURES_CONFIRMED[] + COMPETITORS[] + DOMAIN
   outputs:  EXCLUDED[]
Q7 inputs:   ALL 14 DIMENSIONS
   outputs:  CONFIRMED or CHANGE_LIST
```

**Discovery Notes Schema** (created at start of S2):
```markdown
# Discovery Notes — {project_name}
# Auto-generated during Phase A Step S2
# Every inference has a proof citation (URL or domain-inference-rules.md row)

## Q1: What are you building?
User input:
Domain detected:
Research:
  - Searched: "" → [URL]
  - Domain rules match: [row from domain-inference-rules.md]
Inferred:
  DOMAIN_CATEGORY:
  COMPLIANCE: [] (confidence: %)
  HIGH_RISK: true/false

## Q2: Who uses it?
Options presented: [from research]
User selected:
User added:
Research:
  - Searched: "" → [URL]
Inferred:
  SCALE_TIER: low/medium/high
  DEPLOYMENT_HINTS: []
  A11Y_REQUIRED: true/false
  I18N_REQUIRED: true/false

## Q3: What problem does it solve?
User input:
Research:
  - Searched: "" → [URL]
  - Competitors found: []
Inferred:
  COMPETITOR_INTEGRATIONS: []
  MOBILE_REQUIRED: true/false

## Q3.5: What does success look like in 6 months?
User input:
Research:
  - Searched: "" → [URL]
  - Industry benchmarks:
Inferred:
  SUCCESS_CRITERIA: []
  SCALE_UPDATE: (if success implies different scale)

## Q4: Tech stack
User choice:
Stack registry: found/created
Backend:
Frontend:

## Q5: Features (inferred + manual)
Part A — Inferred (confirmed/rejected):
  [] — confirmed/rejected (proof: )
Part B — Additional selected:
  []
Deep-dive triggered: yes/no
Deep-dive answers:

## Q4.5: Architecture decisions
ARCH_PATTERN:
AUTH_STRATEGY:
API_PATTERN:
DATA_MODEL:
AI_PATTERN: (if AI features)
REALTIME_PATTERN: (if realtime features)
DEPLOY_STRATEGY:
COST_ESTIMATE: $/month

## Q6: Anti-scope
EXCLUDED: []

## Q7: Summary confirmed
All dimensions verified: yes
User changes: none / [list]

## FINAL DIMENSIONS
PROJECT:
USERS: []
PROBLEM:
SUCCESS:
STACK_BACKEND:
STACK_FRONTEND:
STACK_DB:
STACK_AI:
CLOUD_PROVIDER:
ARCH_PATTERN:
AUTH_STRATEGY:
API_PATTERN:
FEATURES: []
COMPLIANCE: []
SCALE:
DEPLOYMENT:
INTEGRATIONS: []
A11Y:
I18N:
MOBILE:
EXCLUDED:
COST_ESTIMATE:
```

---

Q1: "What are you building? Describe it in one sentence."
  INPUTS: none (first question)
  OUTPUTS: INTENT_SEED, PROJECT_NAME, DOMAIN, COMPLIANCE[], HIGH_RISK

  ACCUMULATED CONTEXT: (none — this is the first question)

  DYNAMIC SEARCH (after user answers — use ultrathink for domain classification):
    - "{user's exact sentence} software requirements"
    - "{detected DOMAIN} compliance regulations"
    - "{detected DOMAIN} software common features"
    - MUST use @deep-research-agent when: HIGH_RISK detected, OR compliance detected, OR AI + people-affecting domain
    - MUST research trending tech stacks for this SPECIFIC domain from internet (NEVER default to previous project stacks)

  QUESTION:
    "What are you building? Describe it in one sentence."
    (Free text — no options for Q1)

  HINTS:
    💡 Not sure how to describe it? Start with WHO it's for and WHAT they do:
       - "A clinic booking system for patients and doctors"
       - "An internal dashboard for sales team KPIs"
       - "A marketplace where artists sell prints"
       One sentence is enough — I'll ask details next.

  FALLBACK:
    If vague (e.g., "an app" or "a website"):
      → PM asks ONE follow-up: "What will people USE it for? What task does it help them do?"
    If still vague after follow-up:
      → PM picks closest DOMAIN match from domain-inference-rules.md with confidence noted
      → PM says: "Let me work with what you've given me. I'll infer what I can and you can correct in Q7."

  AFTER USER ANSWERS:
    → PM extracts INTENT_SEED (the core verb+noun: "booking appointments", "tracking sales")
    → PM reads docs/domain-inference-rules.md → finds matching domain row
    → PM web searches with dynamic queries above
    → PM sets: COMPLIANCE[] (from domain row, with confidence %), HIGH_RISK (from domain row)
    → PM WRITES to discovery notes: domain, compliance inferences, HIGH_RISK flag
    → ALL research sources captured with URLs as proof

  TRANSITION: "I see this as a {DOMAIN} project. That means {COMPLIANCE implications}. Let me ask about your users next."

---

Q2: "Who uses {PROJECT_NAME}?"
  INPUTS: INTENT_SEED, PROJECT_NAME, DOMAIN, COMPLIANCE[], HIGH_RISK
  OUTPUTS: USERS[], SCALE_TIER, A11Y_REQUIRED, I18N_REQUIRED, DEPLOYMENT_HINTS[]

  ACCUMULATED CONTEXT (state to user):
    "You're building {PROJECT_NAME} — a {DOMAIN} project for {INTENT_SEED}.
     Domain rules suggest {COMPLIANCE[]} compliance may apply."

  DYNAMIC SEARCH:
    - "{DOMAIN} {INTENT_SEED} user roles personas"
    - "{DOMAIN} software who uses it stakeholders"
    - "{DOMAIN} {INTENT_SEED} accessibility requirements"

  QUESTION + OPTIONS (each with WHY + proof):
    "Who uses {PROJECT_NAME}? Here's what I found for {DOMAIN} projects like yours:"
    ☑ [role1] (required — {DOMAIN} systems {REASON}; proof: domain-inference-rules.md {DOMAIN} row)
    ☑ [role2] (required — {REASON from web search}; proof: {URL})
    ☐ [role3] (recommended — {X}% of {DOMAIN} projects include this because {REASON}; proof: {URL})
    ☐ [role4] (optional — some {DOMAIN} projects include this when {CONDITION})
    📝 Other: ___________

  HINTS:
    💡 Not sure who uses it? For {DOMAIN} projects:
       - There's usually a "doer" (person doing the main task) and a "manager" (who oversees)
       - Most {DOMAIN} systems need at least 2-3 roles
       - If it's just for your team, say "internal users only" — that's fine
       Pick what fits — you can adjust in Q7.

  FALLBACK:
    If user says "just me" or "I don't know yet":
      → PM says: "For {DOMAIN} projects, the minimum is usually {default roles from domain research}. Let's start with those."
      → PM sets USERS[] to domain defaults, marks confidence 70%
    If too vague (e.g., "everyone"):
      → PM asks ONE follow-up: "Can you name 2-3 specific ROLES? Like 'admin', 'customer', 'manager'?"

  AFTER USER ANSWERS:
    → PM infers SCALE_TIER from user count/type (>3 roles → medium+; regulated → medium+)
    → PM infers A11Y_REQUIRED (public-facing → recommended; government/education → required per domain-inference-rules.md)
    → PM infers I18N_REQUIRED (multi-region users → yes; single org → usually no)
    → PM infers DEPLOYMENT_HINTS (regulated → private cloud; internal → on-prem option)
    → PM WRITES to discovery notes with proof citations

  TRANSITION: "Got it — {N} user types. That suggests {SCALE_TIER} scale. Moving to what problem this solves."

---

Q3: "What problem does {PROJECT_NAME} solve for {USERS[primary]}?"
  INPUTS: INTENT_SEED, PROJECT_NAME, DOMAIN, USERS[], SCALE_TIER, COMPLIANCE[]
  OUTPUTS: PROBLEM, CURRENT_SOLUTION, COMPETITORS[], COMPETITOR_GAPS[], MOBILE_REQUIRED, INTEGRATIONS[]

  ACCUMULATED CONTEXT (state to user):
    "You're building {PROJECT_NAME} ({DOMAIN}), used by {USERS[] as comma list}.
     Core intent: {INTENT_SEED}. Scale: {SCALE_TIER}."

  DYNAMIC SEARCH:
    - "{DOMAIN} {INTENT_SEED} existing solutions alternatives"
    - "{DOMAIN} software for {USERS[primary]} pain points"
    - "{DOMAIN} {INTENT_SEED} competitors comparison"
    - "{DOMAIN} {INTENT_SEED} mobile vs web usage patterns"

  QUESTION + OPTIONS:
    "What's the main problem {PROJECT_NAME} solves for {USERS[primary]}?
     How do they handle it today? (spreadsheet, phone calls, another tool, nothing?)"
    Common problems in {DOMAIN} (from research):
    - "{problem1}" (source: {URL})
    - "{problem2}" (source: {URL})
    "Does one of these match, or is it something different?"

  HINTS:
    💡 Not sure how to describe the problem? Think about:
       - What's the WORST part of how {USERS[primary]} do it today?
       - What takes too long, costs too much, or gets forgotten?
       - For {DOMAIN}: common pain points are {list from research}
       Even a rough answer helps — I'll research the details.

  FALLBACK:
    If user says "I don't know the problem, I just want to build it":
      → PM says: "Based on {DOMAIN} research, projects like yours typically solve {top problem from search}. Does that sound close?"
      → If user confirms → use that. If not → record "problem TBD", note lower confidence.
    If too vague (e.g., "make things easier"):
      → PM asks ONE follow-up: "Easier HOW? Faster? Fewer errors? Less manual work? Pick one."

  AFTER USER ANSWERS:
    → PM web searches for competitors: "{DOMAIN} {PROBLEM} software solutions"
    → If competitors found: PM presents: "I found {competitors}. Your differentiator seems to be {gap}. Sound right?"
    → If no competitors: "This looks novel in {DOMAIN}. I didn't find direct competitors."
    → PM infers MOBILE_REQUIRED from user types + problem (field workers → yes; desk workers → web fine)
    → PM infers INTEGRATIONS[] from competitor analysis (what do competitors integrate with?)
    → PM WRITES to discovery notes

  TRANSITION: "The core problem is {PROBLEM}. Found {N} competitors. Let me ask about your success metrics."

---

Q3.5: "What does success look like for {PROJECT_NAME} in 6 months?"
  INPUTS: INTENT_SEED, PROJECT_NAME, DOMAIN, USERS[], PROBLEM, COMPETITORS[], SCALE_TIER
  OUTPUTS: SUCCESS_CRITERIA[], SCALE_UPDATE

  ACCUMULATED CONTEXT (state to user):
    "You're building {PROJECT_NAME} ({DOMAIN}) for {USERS[]}.
     It solves: {PROBLEM}. Competitors: {COMPETITORS[] or 'none found'}.
     Current scale estimate: {SCALE_TIER}."

  DYNAMIC SEARCH:
    - "{DOMAIN} {INTENT_SEED} KPIs success metrics"
    - "{DOMAIN} software launch benchmarks first year"
    - "{COMPETITORS[0]} user numbers growth metrics" (if competitors found)

  QUESTION + OPTIONS (each with WHY + proof):
    "What does success look like for {PROJECT_NAME} in 6 months?
     Pick from these industry benchmarks, or add your own:"
    ☐ {metric1} (benchmark: {industry data}; proof: {URL})
    ☐ {metric2} (benchmark: {data}; proof: {URL})
    ☐ {metric3} (benchmark: {data}; proof: {URL})
    📝 Custom: ___________

  HINTS:
    💡 Not sure about success metrics? Think about:
       - How many {USERS[primary]} would PROVE this works? (10? 100? 1000?)
       - What number would make you confident it's worth continuing?
       - For {DOMAIN}: typical 6-month targets are {range from research}
       Pick a number that feels ambitious but reachable.

  FALLBACK:
    If user says "I don't know" or "just working":
      → PM says: "For {DOMAIN} projects solving {PROBLEM}, a reasonable 6-month target is {default from research}. Let's use that as a starting point."
      → PM sets SUCCESS_CRITERIA[] to research defaults, marks confidence 70%
    If non-measurable (e.g., "people like it"):
      → PM asks ONE follow-up: "How would you MEASURE that? Number of users? Revenue? Time saved?"

  AFTER USER ANSWERS:
    → PM validates against SCALE_TIER — if success implies higher scale, update SCALE_TIER
    → PM WRITES to discovery notes: SUCCESS_CRITERIA[], SCALE_UPDATE

  TRANSITION: "Success = {criteria summary}. Scale {updated or confirmed}. Now let's pick your tech stack."

---

Q4: "Tech Stack — let me research what's best for your project"
  INPUTS: INTENT_SEED, DOMAIN, USERS[], SCALE_TIER, COMPLIANCE[], MOBILE_REQUIRED, SUCCESS_CRITERIA[]
  OUTPUTS: STACK_BACKEND, STACK_FRONTEND, STACK_DB, STACK_AI, CLOUD_PROVIDER, HOSTING_MODEL

  ACCUMULATED CONTEXT (state to user):
    "You're building {PROJECT_NAME} ({DOMAIN}) for {USERS[]}.
     Problem: {PROBLEM}. Scale: {SCALE_TIER}. Compliance: {COMPLIANCE[]}.
     Mobile: {MOBILE_REQUIRED}. Success target: {SUCCESS_CRITERIA[0]}."

  DYNAMIC SEARCH (MANDATORY — always research from internet, NEVER default to registry):
    - "best tech stack for {DOMAIN} {INTENT_SEED} {current_year} production"
    - "{DOMAIN} software trending backend framework {current_year} comparison"
    - "best frontend framework for {INTENT_SEED} dashboard {current_year}"
    - "best database for {DOMAIN} {INTENT_SEED} {current_year}"
    - "{DOMAIN} cloud provider comparison cost {SCALE_TIER} scale {current_year}"
    - If AI features detected: "AI/LLM integration framework {DOMAIN} {current_year}"

  QUESTION: "Do you have tech preferences, or should I recommend based on research?"
    A) "I have preferences" → PM asks each layer separately
    B) "Recommend" → PM presents shopping cart comparison (below)

  **SHOPPING CART FORMAT** — present TOP 3 per layer from internet research:

  "Here's what {DOMAIN} teams are using in {current_year} (from research):"

  Backend:
  | # | Option | Performance | {DOMAIN} Fit | Built-in Features | Trending | Cost |
  |---|--------|-------------|--------------|-------------------|----------|------|
  | 1 | {opt1} | {stars}     | {stars}      | {details}         | {trend}  | Free |
  | 2 | {opt2} | {stars}     | {stars}      | {details}         | {trend}  | Free |
  | 3 | {opt3} | {stars}     | {stars}      | {details}         | {trend}  | Free |

  Frontend:
  | # | Option | Bundle Size | Ecosystem | Learning Curve | Trending | Cost |
  (same format, top 3 from research)

  Database:
  | # | Option | AI/Vector Support | Scaling | Managed Options | Cost/month at {SCALE_TIER} |
  (same format, top 3)

  AI/LLM (only if AI features detected):
  | # | Option | Models Supported | Cost per 1K calls | Explainability | Open Source |
  (same format, top 3)

  Cloud Provider:
  | # | Option | Free Tier | Cost at {SCALE_TIER}/month | {COMPLIANCE[]} Support | Region Coverage |
  (same format, top 3)

  Hosting Model:
  | # | Option | Cost/month | Scaling | Complexity | Best For |
  | 1 | Containers (Docker) | ${X} | Manual | Medium | {SCALE_TIER} teams |
  | 2 | Serverless | ${X} | Auto | Low | Spiky traffic |
  | 3 | VPS | ${X} | Manual | Low | Budget MVP |

  **INCOMPATIBILITY WARNINGS** (show before user picks):
  If user picks conflicting options (e.g., tRPC + Python backend):
    "⚠️ {option A} requires {constraint} — conflicts with your {option B} pick.
     Suggested fix: switch to {alternative}, or change {other pick}."

  **RECOMMENDED COMBO** (at bottom):
  "🏆 Best fit for YOUR project ({DOMAIN} + {SCALE_TIER} + {COMPLIANCE[]}):
   {BACKEND} + {FRONTEND} + {DB} + {CLOUD}
   WHY: {specific reasons tied to THEIR problem, scale, compliance, success criteria}
   Estimated monthly cost at {SCALE_TIER}: ${X}-${Y}/month
   Pick this combo, or select from each row above."

  HINTS:
    💡 Not sure? The recommended combo is based on what {DOMAIN} teams are actually using.
       - Tell me what languages you know and I'll adjust
       - Or just say "recommended" and I'll set it up
       These choices are reversible — but changing later costs time, not money.

  FALLBACK:
    If user says "I don't know" or "whatever works":
      → PM MUST present the recommended combo with cost estimate
      → NEVER default to forge registry — always from internet research
    If user picks something unexpected:
      → PM researches it: "Let me check how {choice} works for {DOMAIN} projects..."
      → Present pros/cons from research, let user confirm

  AFTER USER ANSWERS:
    → PM WRITES to discovery notes: all stack choices with research sources and cost estimates
    → Stack registry: auto-create entry (`forge-stack.sh create {stack} --auto`) for FUTURE reference only

  TRANSITION: "Stack set. Now let me check a few architecture decisions before we get to features."

---

Q4.5: "Architecture & Design Decisions — confirming the expensive-to-change stuff"
  INPUTS: STACK_BACKEND, STACK_FRONTEND, STACK_DB, STACK_AI, CLOUD_PROVIDER, COMPLIANCE[], SCALE_TIER, USERS[]
  OUTPUTS: ARCH_PATTERN, AUTH_STRATEGY, API_PATTERN, DATA_MODEL, AI_PATTERN, REALTIME_PATTERN, DEPLOY_STRATEGY
  DERIVED: COST_ESTIMATE (shown to user, not stored as mutable input)

  ACCUMULATED CONTEXT (state to user):
    "Stack confirmed: {STACK_BACKEND} + {STACK_FRONTEND} + {STACK_DB}.
     Before features, let me confirm a few architecture decisions that are expensive to change later."

  DYNAMIC SEARCH:
    - "{STACK_BACKEND} architecture patterns {DOMAIN} {current_year}"
    - "{STACK_BACKEND} authentication best practices {COMPLIANCE[]}"
    - "{STACK_BACKEND} {STACK_FRONTEND} API pattern REST vs GraphQL {current_year}"

  QUESTION: "I'm inferring these design decisions from your choices. Confirm or adjust:"

  Each decision presented as: INFERRED DEFAULT + WHY + alternatives

  1. **Architecture**: {monolith/modular-monolith/microservices}
     Default: {inferred from SCALE_TIER + team size}
     WHY: "{SCALE_TIER} scale with {team_size} → {pattern} is right because {reason}"
     Alternatives: {list with trade-offs}

  2. **Auth strategy**: {session/JWT/OAuth2}
     Default: {inferred from STACK_BACKEND + COMPLIANCE[]}
     WHY: "{STACK_BACKEND} with {COMPLIANCE[]} → {strategy} because {reason}"

  3. **API pattern**: {REST/GraphQL/tRPC}
     Default: {inferred from STACK_BACKEND + STACK_FRONTEND}
     WHY: "{STACK_BACKEND} + {STACK_FRONTEND} → {pattern} because {reason}"

  4. **Data model**: {single-tenant/multi-tenant, soft-delete/hard-delete}
     Default: {inferred from USERS[] + COMPLIANCE[]}
     (Only ask multi-tenant if multiple orgs detected; only ask soft-delete if compliance needs audit)

  5. **AI integration** (only if AI features): {sync/async, cost control}
     Default: {inferred from SCALE_TIER + expected volume}
     WHY: "{volume} candidates/month → {pattern} because {cost_reason}"
     "Cost per AI call: ~${X}. At {volume}/month = ~${Y}/month."

  6. **Realtime** (only if notifications/collab features): {WebSocket/SSE/polling/none}
     Default: {inferred from FEATURES_HINTED}
     (Skip if no realtime features detected)

  7. **Deployment strategy**: {single-server/load-balanced, managed-DB/self-hosted}
     Default: {inferred from SCALE_TIER + CLOUD_PROVIDER}

  **COST ESTIMATE** (derived — shown after all decisions confirmed):
  "Based on your choices, estimated monthly cost at {SCALE_TIER}:
   - Cloud hosting: ${X}/month
   - Database (managed): ${X}/month
   - AI/LLM calls ({volume}/month): ${X}/month
   - Storage: ${X}/month
   - Total: ~${TOTAL}/month
   This is an estimate — actual costs depend on usage."

  HINTS:
    💡 Not sure? The defaults are based on your scale and compliance needs.
       - For MVP: the defaults are almost always right
       - Only change if you have specific experience or requirements
       "Confirm all" is a valid answer.

  FALLBACK:
    If user says "confirm all" or "defaults are fine":
      → PM uses all inferred defaults → fast path
    If user wants to change one:
      → PM explains trade-offs for that specific decision
      → Only re-ask that one, not all 7

  AFTER USER ANSWERS:
    → PM WRITES to discovery notes: all decisions with reasoning
    → These feed directly into CLAUDE.md Architecture Rules and design doc

  TRANSITION: "Architecture locked. Now let me suggest features based on everything."

---

Q5: Features — SMART TWO-PART (adaptive based on ALL Q1-Q4.5 variables)
  INPUTS: INTENT_SEED, PROJECT_NAME, DOMAIN, USERS[], PROBLEM, COMPETITORS[], COMPLIANCE[],
          SCALE_TIER, STACK_BACKEND, STACK_FRONTEND, STACK_DB, STACK_AI, MOBILE_REQUIRED,
          INTEGRATIONS[], SUCCESS_CRITERIA[], ARCH_PATTERN, AUTH_STRATEGY, API_PATTERN, AI_PATTERN
  OUTPUTS: FEATURES_CONFIRMED[], FEATURES_REJECTED[], FEATURES_ADDITIONAL[], DEEP_DIVE_TRIGGERED

  ACCUMULATED CONTEXT (state to user):
    "Here's what I know about {PROJECT_NAME}:
     - Domain: {DOMAIN} | Users: {USERS[]} | Problem: {PROBLEM}
     - Scale: {SCALE_TIER} | Stack: {STACK_BACKEND} + {STACK_FRONTEND}
     - Compliance: {COMPLIANCE[]} | Mobile: {MOBILE_REQUIRED}
     - Success: {SUCCESS_CRITERIA[0]}
     Based on ALL of this, here are the features I'm inferring:"

  DYNAMIC SEARCH:
    - "{DOMAIN} {INTENT_SEED} must-have features"
    - "{COMPETITORS[0]} features list" (if competitors found)
    - "{STACK_BACKEND} {DOMAIN} common integrations"
    - "{DOMAIN} {COMPLIANCE[0]} required features" (if compliance applies)

  Part A — "Based on your answers, I'm inferring these. Confirm or adjust:"
    (Generated from domain-inference-rules.md + ALL Q1-Q4 research)
    Each item has: status + WHY + proof source:
    ☑ {compliance_feature} (REQUIRED — {COMPLIANCE[0]} mandates this: {specific clause}; proof: domain-inference-rules.md {DOMAIN} row + {URL})
    ☑ {integration_feature} (REQUIRED — competitors {COMPETITORS[]} all support this, your {USERS[]} expect it; proof: {URL})
    ☐ {useful_feature} (RECOMMENDED — {X}% of {DOMAIN} projects include this because {REASON tied to PROBLEM}; proof: {URL})
    ☐ {nice_feature} (OPTIONAL — useful when {CONDITION from their answers}; proof: {URL})
    User confirms, rejects, or adjusts EACH item.
    On reject: PM asks "Why not? (helps me calibrate)" — records reason.

  Part B — "Any additional features not covered above?"
    ☐ Multi-tenant — needed if {PROJECT_NAME} serves multiple organizations
    ☐ AI/LLM features — useful for {PROBLEM} automation
    ☐ File uploads — common when {USERS[]} need to share documents
    ☐ Real-time features — important if {USERS[]} collaborate simultaneously
    ☐ Background jobs — needed for {SCALE_TIER} scale data processing
    ☐ Authentication — always needed unless purely public; {COMPLIANCE[]} requires {auth pattern from domain-inference-rules.md}
    📝 Other: ___________

  HINTS:
    💡 Not sure what features you need? For {DOMAIN} projects solving {PROBLEM}:
       - Start with the minimum: {3 must-haves based on domain research}
       - {COMPETITORS[0]} has {feature list} — you don't need all of them
       - Your {USERS[primary]} definitely need: {feature tied to PROBLEM}
       Less is more for v1 — you can always add features later.

  FALLBACK:
    If user confirms all without reviewing:
      → PM says: "Just to be sure — I'm including {HIGH_IMPACT_FEATURE}. This means {implication}. Still good?"
    If user rejects everything:
      → PM says: "What features DO you want? Let me start fresh with your list."

  AFTER USER ANSWERS:
    → PM merges confirmed inferences + additional selections
    → PM WRITES to discovery notes

  DEEP-DIVE TRIGGER (after Q5, only if needed):
  If ANY of these are true:
    - HIGH_RISK domain confirmed
    - HIPAA/GDPR/PCI-DSS/SOC2 confirmed in Part A
    - Multi-tenant selected in Part B
    - AI/LLM features selected in Part B
    - >3 user types identified in Q2
  → PM says: "Because {TRIGGER_REASON}, I need to ask 2-3 more specific questions:"
  → PM asks domain-specific follow-up questions (from domain-inference-rules.md triggers)
  → Max 1 deep-dive triggered per session
  → User can skip: "Answer or skip? (skipping uses safe defaults)"
  → PM WRITES answers to discovery notes

  TRANSITION: "Features locked: {N} confirmed, {M} rejected. {Deep-dive status}. Now let me ask what to EXCLUDE."

---

Q6: "What should {PROJECT_NAME} NEVER include?"
  INPUTS: FEATURES_CONFIRMED[], COMPETITORS[], DOMAIN, INTENT_SEED, USERS[]
  OUTPUTS: EXCLUDED[]

  ACCUMULATED CONTEXT (state to user):
    "Features confirmed: {FEATURES_CONFIRMED[] as list}.
     Based on {DOMAIN} competitors, some common scope-creep areas are..."

  DYNAMIC SEARCH:
    - "{DOMAIN} {INTENT_SEED} scope creep common additions"
    - "{COMPETITORS[0]} features users complain about" (if competitors found)

  QUESTION + OPTIONS (each with WHY it's a common trap):
    "What should {PROJECT_NAME} NEVER include? This protects scope.
     Here are common scope-creep items for {DOMAIN} projects:"
    ☐ {scope_creep_1} — "common request but {WHY out of scope for INTENT_SEED}"
    ☐ {scope_creep_2} — "{COMPETITORS[0]} has this but it's not core to {PROBLEM}"
    ☐ {scope_creep_3} — "sounds useful but adds {COMPLEXITY_REASON} for {SCALE_TIER} scale"
    📝 Other: ___________

  HINTS:
    💡 Not sure what to exclude? Think about:
       - Features people will ASK for that distract from {PROBLEM}
       - Things {COMPETITORS[]} do that you deliberately DON'T want
       - If in doubt, exclude it — you can always add later but removing is hard.

  FALLBACK:
    If user says "nothing" or "I don't know":
      → PM says: "For {DOMAIN} projects, common exclusions are: {list from research}. At minimum, I'd suggest excluding {obvious_one}. Want to add that?"
    If user says "everything not in features":
      → PM says: "Good instinct. I'll record: 'Only features in the confirmed list. Everything else is out of scope.'"

  AFTER USER ANSWERS:
    → PM WRITES to discovery notes: EXCLUDED[]

  TRANSITION: "Excluded: {list}. Let me show you the full summary for confirmation."

---

Q7: "Confirm everything — all 14 dimensions:"
  INPUTS: ALL accumulated variables
  OUTPUTS: CONFIRMED or CHANGE_LIST

  ACCUMULATED CONTEXT:
    (This IS the context — the full summary table below)

  DYNAMIC SEARCH: (none needed — all research already done)

  QUESTION:
    "Here's the complete picture for {PROJECT_NAME}. Every item was either:
     ✓ You told me directly
     🔍 Inferred from research (proof in discovery notes)
     📋 Domain default from domain-inference-rules.md"

```text
PROJECT:      {PROJECT_NAME} — {INTENT_SEED}                    [source: Q1]
USERS:        {USERS[] with access levels}                       [source: Q2]
PROBLEM:      {PROBLEM}                                          [source: Q3]
SUCCESS:      {SUCCESS_CRITERIA[]}                               [source: Q3.5]
STACK:        {STACK_BACKEND} + {STACK_FRONTEND}                 [source: Q4]
FEATURES:     {FEATURES_CONFIRMED[]}                             [source: Q5]
COMPLIANCE:   {COMPLIANCE[] or 'none'} (confidence: {%})         [source: Q1 inference]
SCALE:        {SCALE_TIER} — {numbers if available}              [source: Q2 + Q3.5]
DEPLOYMENT:   {DEPLOYMENT_HINTS[]}                               [source: Q2 inference]
INTEGRATIONS: {INTEGRATIONS[]}                                   [source: Q3 + Q5]
A11Y:         {A11Y_REQUIRED — level}                            [source: Q2 inference]
I18N:         {I18N_REQUIRED — languages}                        [source: Q2 inference]
MOBILE:       {MOBILE_REQUIRED — type}                           [source: Q3 inference]
EXCLUDED:     {EXCLUDED[]}                                       [source: Q6]
```
"Correct? (yes / change)"

  HINTS:
    💡 Check especially:
       - COMPLIANCE — this affects architecture rules in CLAUDE.md
       - SCALE — this affects infrastructure decisions
       - FEATURES — this becomes your SPEC.md scope
       Changing now is free. Changing after architecture is expensive.

  FALLBACK:
    If user says "looks fine" or "sure" without reviewing:
      → PM says: "Just to confirm — {COMPLIANCE[]} compliance means {specific implication}. And {SCALE_TIER} scale means {specific implication}. Still good?"
      → If user confirms again → proceed

  On "change" → "Which dimension? (1-14 or name)" → re-ask that question with full protocol (search + options + hints) → update discovery notes → re-present summary
  On confirm → PM WRITES final dimensions to discovery notes → proceed to STEP S3

  TRANSITION: "All 14 dimensions confirmed. Discovery notes saved. Starting CLAUDE.md generation."

S2 COMPLETION GATE: docs/forge-trace/A02_phase-a_step-s2_discovery-notes.md must exist with all 14 FINAL DIMENSIONS filled before S3 can start.

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
3. Fetch latest docs: spawn @context-loader-agent for {stack} framework (MANDATORY)
4. Optionally read ~/.claude/stacks/{stack}/rules.md for reference (NEVER override internet research with registry)

Execute: spawn Agent with subagent_type="system-architect"
  prompt: |
    Generate CLAUDE.md for a new project. Follow these rules STRICTLY:

    PROJECT INFO (PM reads actual values from docs/forge-trace/A02_phase-a_step-s2_discovery-notes.md):
    - Name: {name}
    - Description: {description}
    - Stack: {stack}
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
    - Stack: {stack}
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

**STEP S6: GENERATE .claude/rules/** → PM + @system-architect agent

HANDOFF METRIC (S6):
  MUST PROPAGATE:
    - STACK → agent-routing.md has correct agent mappings for this stack
    - FEATURES → agent-routing.md covers all feature domains (auth, API, infra, etc.)
    - Stack registry rules → copied to .claude/rules/{stack}-rules.md (if exists)
  MUST NOT APPEAR:
    - Agent mappings for EXCLUDED features

```bash
mkdir -p .claude/rules/
```

**STACK REGISTRY CHECK** (do this FIRST):
```bash
STACK_DIR="$HOME/.claude/stacks/{stack}"  # e.g., django, fastapi, nextjs
if [ -d "$STACK_DIR" ]; then
  # Copy stack rules into project
  cp "$STACK_DIR/rules.md" .claude/rules/{stack}-rules.md
  # Use stack agent routing as base for agent-routing.md
  STACK_AGENTS=$(cat "$STACK_DIR/agents.md")
  # Read stack learnings — include in all agent prompts this build
  STACK_LEARNINGS=$(cat "$STACK_DIR/learnings.md")
  # Read stack scaffold instructions for Step S7
  STACK_SCAFFOLD=$(cat "$STACK_DIR/scaffold.md")
fi
```

If stack registry exists: use agents.md as the base for agent-routing.md (customize for this project's specific apps).
If no registry: fall back to @system-architect generating from scratch (below).

For sdlc-flow.md: PM fills the template with project-specific stages.

For agent-routing.md: If stack registry provided agents.md, adapt it to this project's app structure.
Otherwise, @system-architect fills the agent matrix based on stack:

Execute: spawn Agent with subagent_type="system-architect"
  prompt: |
    Create .claude/rules/agent-routing.md for this project.

    Stack: {stack}
    Features: {features}

    IMPORTANT: Check if ~/.claude/stacks/{stack}/agents.md exists.
    If YES: use it as the BASE template, adapt for this project's specific apps/folders.
    If NO: create from scratch using the mappings below.

    Fill the agent matrix table:
    | Domain | Files | Agent | context7 Libraries |

    Default mappings (only if no stack registry):
    - Django models → @django-tenants-agent (if multi-tenant) or @backend-architect
    - Django API → @django-ninja-agent
    - FastAPI → @backend-architect (or @agent-factory creates one)
    - S3/Lambda → @s3-lambda-agent
    - AI/LLM → @llm-integration-agent
    - Frontend templates → /sc:implement
    - React/Next.js → @frontend-architect
    - Auth → @django-ninja-agent or stack-specific agent
    - Infrastructure → @devops-architect
    - AWS → @aws-setup-agent
    - GCP → @gcp-setup-agent

Verify: agent-routing.md has at least 3 rows in table
Trace: save to docs/forge-trace/S6-rules/

**STEP S7: GENERATE scaffold** → @devops-architect agent

HANDOFF METRIC (S7):
  MUST PROPAGATE:
    - STACK → correct project structure for this stack
    - DEPLOYMENT → Dockerfile + docker-compose match deployment target
    - COMPLIANCE[] → .env.example includes compliance-related vars (e.g., ENCRYPTION_KEY for HIPAA)
  MUST NOT APPEAR:
    - Files for EXCLUDED features or stacks not chosen

Execute: spawn Agent with subagent_type="devops-architect"
  prompt: |
    Create project scaffold for {stack}.
    Read CLAUDE.md for rules. Read ~/.claude/rules/docker.md for Docker rules.
    Follow the Docker rules file — it covers volume mounts, dev vs prod, .dockerignore.
    Generate REAL files:

    For Django:
    - pyproject.toml (all deps from CLAUDE.md tech stack)
    - Dockerfile (Python 3.12, multi-stage, uv — production with gunicorn)
    - docker-compose.yml (PostgreSQL + Redis + Django — DEVELOPMENT with volume mount + runserver)
    - .dockerignore (.venv, __pycache__, .git, *.pyc)
    - config/settings.py (full Django settings)
    - config/urls.py
    - config/wsgi.py
    - manage.py
    - apps/__init__.py
    - conftest.py (test configuration)
    - .env.example
    - .gitignore

    For FastAPI:
    - pyproject.toml
    - Dockerfile
    - docker-compose.yml (with volume mount + uvicorn --reload for dev)
    - .dockerignore
    - app/main.py
    - app/config.py
    - .env.example
    - .gitignore

    For Next.js:
    - package.json
    - Dockerfile
    - docker-compose.yml (with volume mount + next dev for dev)
    - .dockerignore
    - next.config.js
    - tsconfig.json (TypeScript config)
    - .env.example
    - .gitignore

Verify: key files exist (pyproject.toml OR package.json, Dockerfile, docker-compose.yml)
Trace: save to docs/forge-trace/S7-scaffold/

**STEP S8: GENERATE project infrastructure** → PM (no agent needed)

HANDOFF METRIC (S8):
  MUST PROPAGATE:
    - hooks.json → all 8 hook groups present
    - playbook structure → 3 files exist
    - forge-timeline.md → project name from discovery notes
    - git hooks → commit-msg + pre-commit installed
  MUST NOT APPEAR: N/A (infrastructure, not content)

PM creates all project infrastructure that /forge needs to operate:

```bash
# 1. Hooks (ALL 8 — auto-continue, state tracking, safety, linting)
mkdir -p .claude
cp ~/.claude/templates/hooks.json .claude/settings.json

# 2. Forge local directory (playbook, rules, agents, checkpoints)
mkdir -p .forge/playbook .forge/rules .forge/agents .forge/checkpoints

# 3. Playbook files
cat > .forge/playbook/strategies.md << 'EOF'
# Playbook — Strategies & Insights
# Format: [str-NNN] helpful=N harmful=N :: insight text
## STRATEGIES & INSIGHTS
## COMMON MISTAKES TO AVOID
## DOMAIN-SPECIFIC
EOF

cat > .forge/playbook/mistakes.md << 'EOF'
# Playbook — Mistakes
# Format: [mis-NNN] :: description + root cause + prevention
EOF

cat > .forge/playbook/archived.md << 'EOF'
# Playbook — Archived
# Pruned entries (harmful > helpful) are moved here.
EOF

# 4. Project-specific rules
cat > .forge/rules/project.md << 'EOF'
# Project-Specific Rules
# Rules that apply ONLY to this project. Global rules are in ~/.claude/rules/
EOF

# 5. Forge local gitignore
cat > .forge/.gitignore << 'EOF'
checkpoints/
EOF

# 6. Docs structure
mkdir -p docs/forge-trace docs/proposals docs/retrospectives docs/checkpoints docs/issues

# 7. Forge timeline
cat > docs/forge-timeline.md << EOF
# Forge Timeline -- $(basename "$PWD")
This file tracks every step of the development process.
Updated automatically by /forge and all Forge commands.

## Legend
- DONE -- step completed successfully
- NEEDS_REVIEW -- output needs human review
- BLOCKED -- step failed, needs attention
- IN_PROGRESS -- currently running

---
<!-- Timeline entries appear below, newest first -->
EOF

# 8. Copy utility scripts
mkdir -p scripts
cp ~/.claude/scripts/traceability.sh scripts/ 2>/dev/null || true
cp ~/.claude/scripts/sync-report.sh scripts/ 2>/dev/null || true
cp ~/.claude/scripts/forge-handoff-check.sh scripts/ 2>/dev/null || true
chmod +x scripts/*.sh 2>/dev/null || true

# 9. Install git hooks (enforces issue-first workflow + REQ impact analysis)
cp ~/.claude/templates/commit-msg .git/hooks/commit-msg 2>/dev/null || true
cp ~/.claude/templates/pre-commit .git/hooks/pre-commit 2>/dev/null || true
chmod +x .git/hooks/commit-msg .git/hooks/pre-commit 2>/dev/null || true
```

Verify: .claude/settings.json exists and is valid JSON
Verify: .forge/playbook/ exists with 3 files
Verify: docs/forge-timeline.md exists
Trace: save to docs/forge-trace/S8-infrastructure/

<!-- HARD GATE: PM MUST NOT skip S9 or S10. Phase A is NOT complete without both. -->
<system-reminder>
S9 and S10 are MANDATORY. Do NOT say "Phase A complete" until BOTH have executed.
S9 must spawn @self-review agent. S10 must git commit. Skipping either is a VIOLATION.
</system-reminder>

**STEP S9: REVIEW all generated files** → @reviewer agent (MANDATORY — DO NOT SKIP)

HANDOFF METRIC (S9):
  MUST VERIFY:
    - ALL S3-S8 handoff metrics pass (run forge-handoff-check.sh for each)
    - Every rating >= 4
    - Discovery notes 14 dimensions ALL represented across CLAUDE.md + SPEC.md
    - Anti-scope: no EXCLUDED item appears in any [REQ-xxx]
  ESCALATE: any rating < 4 → fix → re-review (max 2)

Execute: spawn Agent with subagent_type="reviewer"
  prompt: |
    Review all generated files for this new project:
    1. CLAUDE.md — at least 20 lines, under 100? Real rules? MUST/NEVER format? Code snippets?
    2. SPEC.md — at least 20 [REQ-xxx]? Models have field types? API endpoints listed?
    3. FORGE.md — has QUEUED entry?
    4. .claude/rules/ — SDLC flow complete? Agent routing filled?
    5. Scaffold — settings.py valid? Dependencies listed? Dockerfile works?
    6. .claude/settings.json — valid JSON? Has all 9 hook groups (SessionStart, Stop, UserPromptSubmit, PreToolUse x2, PostToolUse x4)?
    7. .forge/playbook/ — strategies.md, mistakes.md, archived.md exist?
    8. docs/forge-timeline.md — exists with project name?
    9. Discovery Notes — docs/forge-trace/A02_phase-a_step-s2_discovery-notes.md exists?
       All 14 FINAL DIMENSIONS filled? Every inference has proof citation?
    10. SPEC Traceability — does SPEC.md Requirements Traceability table have 4 columns (REQ | description | proof | status)?
        Are there [REQ-COMPLIANCE-xxx] if compliance was confirmed? [REQ-SUCCESS-xxx]?
    11. CLAUDE.md Security — if HIPAA confirmed, does "PHI" appear in rules?
        If GDPR, does "consent" or "erasure" appear? If PCI, does "tokenisation" appear?
    12. Anti-scope — are any items from EXCLUDED list accidentally present as [REQ-xxx]?

    Rate each 1-5. Report any issues.

Verify: all ratings >= 4
If any < 4 → fix → re-review
Trace: save to docs/forge-trace/S9-review/

**STEP S10: COMMIT + DONE** (MANDATORY — DO NOT SKIP)

```bash
# Add specific files — NEVER git add -A (could include .env or credentials)
git add CLAUDE.md SPEC.md FORGE.md .claude/ .forge/ docs/ scripts/ \
  pyproject.toml Dockerfile docker-compose.yml .dockerignore .gitignore \
  .env.example config/ apps/ manage.py conftest.py 2>/dev/null || true
git commit -m "init: scaffold project with forge"
```

Output to user:
```
Setup complete!

Created:
  CLAUDE.md           — {N} lines, {N} architecture rules
  SPEC.md             — {N} [REQ-xxx] requirements
  FORGE.md            — 1 QUEUED item ready
  .claude/rules/      — SDLC flow + agent routing
  .claude/settings.json — hooks for lint + safety + flow detection
  Scaffold            — {list of files}

Next: exit Claude Code, then run `forge` again in this folder.
Session 2 will load CLAUDE.md and start building.
```

**FAILURE RECOVERY:** If Phase A fails mid-way:
- Run `bash ~/.claude/scripts/forge-infra-check.sh --reset` to clear state and restart fresh
- Or fix the issue and run `/forge` again — S1 will detect partial setup and resume

---

**STEP S5-BROWNFIELD: REVERSE-ENGINEER** (when code exists, no CLAUDE.md)

<system-reminder>
This project has code but was NOT built with Forge. Do NOT create requirements from scratch.
The requirements ALREADY EXIST in the code. You must DISCOVER them first.
NEVER ask "what are you building?" — the code TELLS you what was built.
</system-reminder>

Execute: spawn Agent with subagent_type="repo-index"
  prompt: "Index {project folder}. Report: language, framework, file count, models found, endpoints found, tests found."
Verify: index report exists

Execute: spawn Agent with subagent_type="requirements-analyst"
  prompt: "Reverse-engineer requirements from existing code. Read models → data requirements. Read API → functional requirements. Read tests → verified behaviors. Output [REQ-xxx] tags."
Verify: at least 10 [REQ-xxx] from existing code

Execute: spawn Agent with subagent_type="system-architect"
  prompt: "Generate CLAUDE.md from existing codebase. Read pyproject.toml/package.json for stack. Read config for settings. Extract patterns as rules."
Verify: CLAUDE.md has real stack, real rules

If repo-index detects multiple frameworks (e.g., Django backend + React frontend):
  → PM asks: "I found both [X] and [Y]. Which should I focus on?"
  → User picks → agent-routing.md targets that framework

Then → STEP S5 (FORGE.md) → S6 → S7 (brownfield: skip scaffold but check for missing Dockerfile/docker-compose — add only missing infra files) → S8 → S9 → S10

#### Phase B -- Full SDLC (CHAINED EXECUTION — each step MUST complete before next)

<system-reminder>
CHAINED EXECUTION PROTOCOL — ENFORCED BY HOOKS AND SCRIPTS:

BEFORE ANYTHING: Run `bash scripts/forge-enforce.sh check-state` to load current state.
BEFORE ANYTHING: Run `bash scripts/forge-enforce.sh check-continuation` to find the NEXT step.
BEFORE ANYTHING: Run `bash scripts/docker-state.sh` to capture Docker state.

RESUME LOGIC — CRITICAL:
  Read docs/forge-state.json. For each step:
  - If status = "DONE" → SKIP IT. Do not re-run completed steps.
  - If status = "SKIPPED" → Note as historical violation. Do not re-run unless user asks.
  - If status = "NOT_STARTED" → EXECUTE this step.
  - If status = "IN_PROGRESS" → RESUME this step.
  The check-continuation command tells you the EXACT next step. Start there.

RETROACTIVE GATES — When phases are DONE but gates never ran:
  The gate only needs to VERIFY (run checks), not REDO work.
  Run: tests pass + lint clean + traceability pass + Docker healthy + no secrets.
  If all pass → mark gate passed with `forge-enforce.sh update-gate <N>`.
  Do NOT re-run the phase's work steps.

Each step below MUST be executed using the Skill tool (for commands) or Agent tool (for agents).
After EACH step:
  1. VERIFY the output file exists (use Read or Bash ls)
  2. VERIFY it has real content (not empty, not placeholder)
  3. LOG to docs/forge-trace/{NNN}-{step}/ — ALL 3 FILES: input.md + output.md + meta.md
  4. VERIFY trace: `bash scripts/forge-enforce.sh check-trace <STEP_NUMBER>`
  5. LOG to docs/forge-timeline.md
  6. UPDATE state: `bash scripts/forge-enforce.sh update-step <STEP_NUMBER> DONE`
  7. ONLY THEN proceed to next step

PHASE TRANSITIONS — HARD GATE:
  Before starting Phase N, you MUST verify Phase N-1 gate passed:
  `bash scripts/forge-enforce.sh check-gate <N-1>`
  If NOT passed → run /gate phase-<N-1> → verify → THEN proceed.
  NEVER skip a gate. NEVER proceed without a passing gate.

AGENT SEPARATION — ENFORCED:
  PM (you) NEVER writes to apps/**/*.py or templates/**/*.html
  Always spawn the specialist agent from .claude/rules/agent-routing.md
  Hook will warn if you attempt to write app code directly.

AUTO-CONTINUATION — MANDATORY:
  NEVER stop to ask "should I continue?" — always continue.
  NEVER ask which agent to use — consult agent-routing.md.
  ONLY stop for: gate BLOCKED, /challenge RETHINK, missing credentials, 3 failed retries.

If verification FAILS → retry the step (max 2) → still fails → STOP and report.
If a step produces no output file → the step did NOT run → DO NOT PROCEED.

You are EXECUTING these commands, not describing them.
Use the Skill tool: `skill: "discover"` or `skill: "requirements"` etc.
Use the Agent tool for specialist agents: `subagent_type: "security-engineer"` etc.

ON CONTEXT LIMIT: Save state with forge-enforce.sh, summarize in timeline, continue immediately.
ON SESSION RESTART: Run `bash scripts/forge-enforce.sh check-continuation` to find next step.
</system-reminder>

