#!/bin/bash
# Forge State Sync — fixes stale forge-state.json by reading actual git history
# Called by UserPromptSubmit hook to auto-fix state on every /forge
#
# Usage: forge-state-sync.sh

set -uo pipefail

D="${PROJECT_ROOT:-$PWD}"
STATE="$D/docs/forge-state.json"
[ -f "$STATE" ] || exit 0

ENFORCE="$D/scripts/forge-enforce.sh"
[ -f "$ENFORCE" ] || ENFORCE="$HOME/.claude/scripts/forge-enforce.sh"
[ -f "$ENFORCE" ] || exit 0

# Read current state
current_step=$(python3 -c "import json; print(json.load(open('$STATE')).get('current_step',0))" 2>/dev/null || echo 0)

# Detect actual progress from git and files
has_spec=$([ -f "$D/SPEC.md" ] && grep -c "REQ-" "$D/SPEC.md" 2>/dev/null || echo 0)
has_design=$([ -f "$D/docs/design-doc.md" ] && echo 1 || echo 0)
has_issues=$(ls "$D/docs/issues/"*.md 2>/dev/null | wc -l || echo 0)
has_app_code=$(find "$D/apps" -name "*.py" -not -name "__init__.py" -not -name "tests*.py" 2>/dev/null | wc -l || echo 0)
has_tests=$(find "$D/apps" -name "tests*.py" 2>/dev/null | wc -l || echo 0)
commit_count=$(git -C "$D" rev-list --count HEAD 2>/dev/null || echo 0)

# Determine actual phase from artifacts
actual_phase=0
actual_step=0

if [ "$has_spec" -gt 0 ]; then
    actual_step=4  # At least through generate-spec
fi
if [ "$has_design" -eq 1 ]; then
    actual_step=14  # Through design-doc
fi
if [ "$has_issues" -gt 0 ]; then
    actual_step=19  # Through plan-tasks + gate
    actual_phase=2
fi
if [ "$has_app_code" -gt 3 ]; then
    actual_step=39  # Through implementation
    actual_phase=3
fi

# Check phase gates from state
phases_done=$(python3 -c "
import json
d = json.load(open('$STATE'))
phases = d.get('phases', {})
done = 0
for p in ['0','1','2','3','4','5']:
    phase = phases.get(p, {})
    if phase.get('status') == 'DONE' or phase.get('gate_passed'):
        done = int(p) + 1
print(done)
" 2>/dev/null || echo 0)

if [ "$phases_done" -gt "$actual_phase" ]; then
    actual_phase=$phases_done
    # Map phase to step
    case "$actual_phase" in
        1) [ "$actual_step" -lt 8 ] && actual_step=8 ;;
        2) [ "$actual_step" -lt 11 ] && actual_step=11 ;;
        3) [ "$actual_step" -lt 19 ] && actual_step=19 ;;
        4) [ "$actual_step" -lt 39 ] && actual_step=39 ;;
        5) [ "$actual_step" -lt 46 ] && actual_step=46 ;;
    esac
fi

# If state is behind reality, fix it
if [ "$actual_step" -gt "$current_step" ]; then
    echo "[FORGE-SYNC] State stale: was step $current_step, actual progress is step $actual_step (phase $actual_phase)"
    python3 -c "
import json
d = json.load(open('$STATE'))
d['current_step'] = $actual_step
d['current_phase'] = $actual_phase
d['status'] = 'IN_PROGRESS'
json.dump(d, open('$STATE', 'w'), indent=2)
"
    echo "[FORGE-SYNC] Updated to step $actual_step, phase $actual_phase"
    echo "[FORGE-SYNC] Artifacts: spec=$has_spec REQs, design=$has_design, issues=$has_issues, code=$has_app_code files, tests=$has_tests files, commits=$commit_count"
else
    echo "[FORGE-SYNC] State OK: step $current_step, phase $(python3 -c "import json; print(json.load(open('$STATE')).get('current_phase',0))" 2>/dev/null)"
fi
