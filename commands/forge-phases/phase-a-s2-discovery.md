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
Q4.5 inputs: ALL Q4 outputs + COMPLIANCE[] + SCALE_TIER + DOMAIN
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
DATA_MODEL:
AI_PATTERN:
REALTIME_PATTERN:
DEPLOY_STRATEGY:
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
    → Stack registry: auto-create entry (`forge-stack.sh create {STACK_BACKEND} --auto`) for FUTURE reference only

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
    - HIPAA/GDPR/PCI-DSS/SOC2/EEOC confirmed in Part A
    - AI + people-affecting domain (hiring/HR/lending/insurance/criminal justice)
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
