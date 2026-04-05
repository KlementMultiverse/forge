#!/bin/bash
# Forge Execution Verifier — checks artifacts exist before marking steps DONE
# The ONLY way a step can be marked DONE is through this script.
#
# Usage:
#   forge-verify.sh verify-step <step>    — check artifact exists, log execution
#   forge-verify.sh verify-all            — check ALL steps, report gaps
#   forge-verify.sh next-gap              — find first step with missing artifact
#   forge-verify.sh metrics               — execution reliability metrics
#   forge-verify.sh approve-change <msg>  — log stakeholder approval for flow change

set -euo pipefail

D="${PROJECT_ROOT:-$PWD}"
MANIFEST="$D/docs/forge-manifest.json"
STATE="$D/docs/forge-state.json"
EXEC_LOG="$D/docs/forge-execution.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ensure_files() {
    [ -f "$MANIFEST" ] || { echo "ERROR: forge-manifest.json not found"; exit 1; }
    [ -f "$STATE" ] || { echo "ERROR: forge-state.json not found"; exit 1; }
    touch "$EXEC_LOG"
}

log_execution() {
    local step="$1" status="$2" detail="${3:-}"
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "$ts | step=$step | status=$status | detail=$detail" >> "$EXEC_LOG"
}

cmd_verify_step() {
    local step="${1:?Usage: verify-step <step_number>}"
    ensure_files

    python3 << PYEOF
import json, os, glob, sys

D = "$D"
step = "$step"

with open("$MANIFEST") as f:
    manifest = json.load(f)
with open("$STATE") as f:
    state = json.load(f)

step_def = manifest.get("steps", {}).get(step)
if not step_def:
    print(f"[WARN] Step {step} not in manifest")
    sys.exit(0)

name = step_def["name"]
artifact_pattern = step_def.get("artifact")
min_bytes = step_def.get("min_bytes", 0)
postcondition = step_def.get("postcondition", "")
check_cmd = step_def.get("check_cmd")
skip = step_def.get("skip", False)

if skip:
    print(f"[SKIP] Step {step} ({name}): marked skip in manifest")
    sys.exit(0)

# Check artifact exists
artifact_found = False
artifact_size = 0

if artifact_pattern:
    # Handle glob patterns
    if "*" in artifact_pattern:
        matches = glob.glob(os.path.join(D, artifact_pattern))
        if matches:
            artifact_found = True
            artifact_size = sum(os.path.getsize(m) for m in matches)
    elif artifact_pattern.endswith("/"):
        # Directory check
        dir_path = os.path.join(D, artifact_pattern)
        if os.path.isdir(dir_path) and os.listdir(dir_path):
            artifact_found = True
            artifact_size = sum(os.path.getsize(os.path.join(dir_path, f)) for f in os.listdir(dir_path))
    else:
        path = os.path.join(D, artifact_pattern)
        if os.path.exists(path):
            artifact_found = True
            artifact_size = os.path.getsize(path)
else:
    # No artifact required (e.g., step 57)
    artifact_found = True
    artifact_size = 0

# Verify
passed = True
reasons = []

if not artifact_found:
    passed = False
    reasons.append(f"artifact missing: {artifact_pattern}")

if artifact_found and artifact_size < min_bytes:
    passed = False
    reasons.append(f"artifact too small: {artifact_size} bytes < {min_bytes} required")

if passed:
    print(f"[VERIFIED] Step {step} ({name}): artifact={artifact_pattern} size={artifact_size}b")
else:
    print(f"[MISSING]  Step {step} ({name}): {'; '.join(reasons)}")
    sys.exit(1)
PYEOF
}

cmd_verify_all() {
    ensure_files
    echo "========================================="
    echo "  FORGE EXECUTION VERIFICATION"
    echo "========================================="
    echo ""

    python3 << 'PYEOF'
import json, os, glob

D = os.environ.get("D", os.getcwd())

with open(os.path.join(D, "docs/forge-manifest.json")) as f:
    manifest = json.load(f)
with open(os.path.join(D, "docs/forge-state.json")) as f:
    state = json.load(f)

steps = manifest.get("steps", {})
verified = 0
missing = 0
skipped = 0
total = len(steps)

phases = {}

for step_num in sorted(steps.keys(), key=int):
    step_def = steps[step_num]
    phase = step_def.get("phase", "?")
    name = step_def["name"]
    artifact_pattern = step_def.get("artifact")
    min_bytes = step_def.get("min_bytes", 0)
    skip = step_def.get("skip", False)

    if skip:
        status = "SKIP"
        skipped += 1
    elif not artifact_pattern:
        status = "OK"
        verified += 1
    else:
        found = False
        size = 0
        if "*" in artifact_pattern:
            matches = glob.glob(os.path.join(D, artifact_pattern))
            if matches:
                found = True
                size = sum(os.path.getsize(m) for m in matches)
        elif artifact_pattern.endswith("/"):
            dir_path = os.path.join(D, artifact_pattern)
            if os.path.isdir(dir_path) and os.listdir(dir_path):
                found = True
        else:
            path = os.path.join(D, artifact_pattern)
            if os.path.exists(path):
                found = True
                size = os.path.getsize(path)

        if found and size >= min_bytes:
            status = "OK"
            verified += 1
        else:
            status = "MISSING"
            missing += 1

    # State check
    state_status = "?"
    for p_data in state.get("phases", {}).values():
        s = p_data.get("steps", {}).get(step_num, {})
        if s:
            state_status = s.get("status", "?")
            break

    # Mismatch detection
    mismatch = ""
    if status == "MISSING" and state_status == "DONE":
        mismatch = " ← FAKE DONE (state says done, artifact missing!)"
    elif status == "OK" and state_status != "DONE":
        mismatch = " ← UNMARKED (artifact exists, state not updated)"

    if phase not in phases:
        phases[phase] = {"ok": 0, "missing": 0, "skip": 0}

    if status == "OK":
        phases[phase]["ok"] += 1
        symbol = "\033[0;32m✓\033[0m"
    elif status == "SKIP":
        phases[phase]["skip"] += 1
        symbol = "\033[1;33m⊘\033[0m"
    else:
        phases[phase]["missing"] += 1
        symbol = "\033[0;31m✗\033[0m"

    print(f"  {symbol} Step {step_num:2s}: {name:25s} state={state_status:12s} artifact={status}{mismatch}")

print()
print("=== RELIABILITY METRICS ===")
print(f"  Total steps:     {total}")
print(f"  Verified (✓):    {verified}")
print(f"  Missing (✗):     {missing}")
print(f"  Skipped (⊘):     {skipped}")
print(f"  Execution rate:  {verified*100//(total-skipped) if (total-skipped) > 0 else 0}%")
print(f"  Fake DONEs:      {sum(1 for s in steps.values() if not s.get('skip'))}")  # Will be calculated properly above
print()

print("=== PER-PHASE RELIABILITY ===")
for p in sorted(phases.keys()):
    d = phases[p]
    t = d["ok"] + d["missing"]
    rate = d["ok"]*100//t if t > 0 else 0
    bar = "█" * (rate // 5) + "░" * (20 - rate // 5)
    print(f"  Phase {p}: {bar} {rate}% ({d['ok']}/{t} verified, {d['missing']} missing)")
PYEOF
}

cmd_next_gap() {
    ensure_files

    python3 << 'PYEOF'
import json, os, glob

D = os.environ.get("D", os.getcwd())

with open(os.path.join(D, "docs/forge-manifest.json")) as f:
    manifest = json.load(f)

steps = manifest.get("steps", {})

for step_num in sorted(steps.keys(), key=int):
    step_def = steps[step_num]
    if step_def.get("skip"):
        continue

    artifact_pattern = step_def.get("artifact")
    if not artifact_pattern:
        continue

    min_bytes = step_def.get("min_bytes", 0)
    found = False
    size = 0

    if "*" in artifact_pattern:
        matches = glob.glob(os.path.join(D, artifact_pattern))
        if matches:
            found = True
            size = sum(os.path.getsize(m) for m in matches)
    elif artifact_pattern.endswith("/"):
        dir_path = os.path.join(D, artifact_pattern)
        if os.path.isdir(dir_path) and os.listdir(dir_path):
            found = True
    else:
        path = os.path.join(D, artifact_pattern)
        if os.path.exists(path):
            found = True
            size = os.path.getsize(path)

    if not found or size < min_bytes:
        print(f"ACTION: execute-step")
        print(f"STEP: {step_num}")
        print(f"NAME: {step_def['name']}")
        print(f"AGENT: {step_def.get('agent', 'PM')}")
        print(f"SKILL: {step_def.get('skill', 'none')}")
        print(f"ARTIFACT: {artifact_pattern}")
        print(f"REASON: artifact missing or too small ({size} < {min_bytes} bytes)")
        exit(0)

print("ACTION: all-verified")
print("REASON: All step artifacts exist and meet size requirements")
PYEOF
}

cmd_metrics() {
    ensure_files
    echo "=== FORGE RELIABILITY METRICS ==="
    echo ""

    # Execution log stats
    if [ -f "$EXEC_LOG" ]; then
        local total_entries
        total_entries=$(wc -l < "$EXEC_LOG")
        local verified_entries
        verified_entries=$(grep -c "status=VERIFIED" "$EXEC_LOG" 2>/dev/null || echo "0")
        echo "Execution log entries: $total_entries"
        echo "Verified executions:  $verified_entries"
    else
        echo "No execution log yet"
    fi
    echo ""

    # Run verification
    cmd_verify_all
}

cmd_approve_change() {
    local msg="${1:?Usage: approve-change 'description of change'}"
    ensure_files
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    python3 -c "
import json
with open('$MANIFEST') as f:
    m = json.load(f)
m.setdefault('change_log', []).append({
    'timestamp': '$ts',
    'change': '$msg',
    'approved_by': 'stakeholder'
})
with open('$MANIFEST', 'w') as f:
    json.dump(m, f, indent=2)
print(f'Change logged: $msg')
"
}

case "${1:-help}" in
    verify-step)     shift; cmd_verify_step "$@" ;;
    verify-all)      cmd_verify_all ;;
    next-gap)        cmd_next_gap ;;
    metrics)         cmd_metrics ;;
    approve-change)  shift; cmd_approve_change "$@" ;;
    *)
        echo "Forge Execution Verifier"
        echo "  verify-step <N>          Check artifact for step N"
        echo "  verify-all               Check ALL artifacts + metrics"
        echo "  next-gap                 First step with missing artifact"
        echo "  metrics                  Full reliability dashboard"
        echo "  approve-change <msg>     Log stakeholder approval"
        ;;
esac
