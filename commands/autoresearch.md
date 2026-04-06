# /autoresearch — Improve Agent Prompts from Build Learnings

Research how agents performed during this build and improve their prompts for next time.

<system-reminder>
This command runs AFTER /retro (step 49) and BEFORE /sc:save (step 55).
It uses the retrospective findings to enhance agent definitions.
</system-reminder>

## What It Does

1. Read `docs/retrospectives/*.md` for this build's lessons
2. Read `docs/.builder-activity.log` for agent performance data
3. For each agent that participated in this build:
   - Check: did it produce output rated >= 4 by @reviewer?
   - Check: did it require retries? How many?
   - Check: did it follow the spec correctly?
4. For agents that struggled:
   - Research better prompt patterns via web search
   - Suggest prompt improvements
   - Update agent .md file with improved instructions
5. For agents that excelled:
   - Extract what worked well
   - Add to playbook as a proven pattern

## Output

- Modified agent files (with improved prompts)
- Summary of changes made
- Log entry in docs/forge-timeline.md

## Rules

- NEVER remove existing agent capabilities
- Only ADD or REFINE instructions
- Every change must reference the retro finding that motivated it
- Changes are reviewed by @reviewer before commit
