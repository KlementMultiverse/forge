# Run 02: saleor -- Write developer onboarding guide (setup, first contribution)

## Task
Write developer onboarding guide for Saleor (open-source e-commerce platform).

## Code Read
- Would need to read saleor repo structure, CONTRIBUTING.md, setup scripts
- No saleor repo available locally -- prompt should handle this gracefully

## Prompt Evaluation

### What the prompt guided well
1. **CONTEXT step** -- "Read CLAUDE.md + SPEC.md + existing docs/" -- correctly prioritizes understanding project context
2. **Chaos Resilience** -- "Empty codebase -> document architecture decisions and setup guide instead" -- handles missing code
3. **Audience targeting** -- "developer new to this project" default is perfect for onboarding guide
4. **STRUCTURE step** -- "guide -> step-by-step" format instruction is correct for onboarding

### What the prompt missed or was weak on
1. **No prerequisite listing instruction** -- Onboarding docs need: "What do I need installed BEFORE starting?" Prompt doesn't push for prerequisites section
2. **No "verify your setup works" instruction** -- Each setup step should have a verification command (e.g., "run X, you should see Y"). Prompt says "verification steps" generically but doesn't enforce checkpoints
3. **No "common setup failures" section** -- New developers hit the same issues (port conflicts, missing deps, version mismatches). Prompt doesn't push for troubleshooting section in onboarding
4. **No "first task" walkthrough** -- Best onboarding guides include a guided first contribution. Prompt doesn't differentiate "setup guide" from "first contribution walkthrough"
5. **No time estimate instruction** -- "This guide takes ~30 minutes" is valuable for developers planning their time
6. **No architecture overview instruction** -- Before diving into setup, developers need a mental model of the system
7. **No link verification instruction** -- Onboarding docs rot fast when links break; prompt should push for link verification

### Documentation Quality Score: 5/10
- Without the actual codebase, quality drops significantly
- Prompt's Chaos Resilience section helps but doesn't cover "document based on web research of a known open-source project"
- Missing: prerequisite listing, verification checkpoints, time estimates, architecture overview

## Prompt Gaps Identified
| Gap | Severity | Fix |
|-----|----------|-----|
| No prerequisites section instruction | High | Add: "For setup guides, start with Prerequisites: OS, tools, versions, accounts needed" |
| No verification checkpoints | High | Add: "Each setup step must end with a verification command and expected output" |
| No common failures section | Medium | Add: "Include Common Issues section with top 5 setup failures and fixes" |
| No time estimate instruction | Low | Add: "Include estimated completion time at the top of guides" |
| No architecture overview before setup | Medium | Add: "Start guides with 2-3 paragraph architecture overview to build mental model" |
| No external project research fallback | Medium | Add: "If codebase unavailable, use web search + official docs to research project structure" |
