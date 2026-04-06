#!/bin/bash
# Forge Triangle Enforcer — SPEC ↔ TEST ↔ CODE per-REQ verification
# Every REQ must exist in all three: spec description, test docstring, code comment
#
# Usage:
#   forge-triangle.sh check              — full per-REQ triangle check
#   forge-triangle.sh check-req <REQ>    — check one REQ across all three
#   forge-triangle.sh sync-report        — human-readable sync matrix
#   forge-triangle.sh tdd-check <app>    — verify tests exist before code for app
#   forge-triangle.sh create-issue <REQ> <type> <desc> — create GitHub issue for broken triangle

set -euo pipefail

# Source shared phase mapping
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR
source "$SCRIPT_DIR/forge-phase-map.sh"

D="${PROJECT_ROOT:-$PWD}"
SPEC="$D/SPEC.md"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

cmd_check() {
    [ -f "$SPEC" ] || { echo "ERROR: SPEC.md not found"; exit 1; }

    python3 << 'PYEOF'
import os, re, glob

D = os.environ.get("D", os.getcwd())
SPEC = os.path.join(D, "SPEC.md")

# Extract all REQs from spec
spec_text = open(SPEC).read()
spec_reqs = set(re.findall(r'REQ-[A-Z]+-\d+', spec_text))

# Find REQs in test files
test_reqs = {}
for pattern in ["apps/*/tests.py", "apps/*/tests/*.py", "e2e/*.py", "tests/*.py"]:
    for f in glob.glob(os.path.join(D, pattern)):
        content = open(f).read()
        for req in re.findall(r'REQ-[A-Z]+-\d+', content):
            test_reqs.setdefault(req, []).append(os.path.relpath(f, D))

# Find REQs in code files (excluding tests and spec)
code_reqs = {}
for pattern in ["apps/**/*.py", "config/*.py", "templates/**/*.html", "static/**/*.js"]:
    for f in glob.glob(os.path.join(D, pattern), recursive=True):
        if "test" in f.lower() or "migration" in f.lower() or ".venv" in f:
            continue
        content = open(f).read()
        for req in re.findall(r'REQ-[A-Z]+-\d+', content):
            code_reqs.setdefault(req, []).append(os.path.relpath(f, D))

# Build triangle matrix
all_reqs = sorted(spec_reqs | set(test_reqs.keys()) | set(code_reqs.keys()))

broken = []
synced = []
orphans = []

print("=== SPEC ↔ TEST ↔ CODE Triangle ===")
print()
print(f"{'REQ':<20} {'SPEC':^6} {'TEST':^6} {'CODE':^6} {'STATUS':^10}")
print("-" * 55)

for req in all_reqs:
    in_spec = req in spec_reqs
    in_test = req in test_reqs
    in_code = req in code_reqs

    if in_spec and in_test and in_code:
        status = "\033[0;32mSYNCED\033[0m"
        synced.append(req)
    elif in_spec and not in_test and not in_code:
        status = "\033[1;33mSPEC-ONLY\033[0m"
        broken.append((req, "missing test + code"))
    elif not in_spec:
        status = "\033[1;33mORPHAN\033[0m"
        orphans.append(req)
    else:
        missing = []
        if not in_spec: missing.append("spec")
        if not in_test: missing.append("test")
        if not in_code: missing.append("code")
        status = f"\033[0;31mBROKEN\033[0m"
        broken.append((req, f"missing {'+'.join(missing)}"))

    s = "✓" if in_spec else "✗"
    t = "✓" if in_test else "✗"
    c = "✓" if in_code else "✗"
    # Print without color for the cells
    print(f"  {req:<18} {s:^6} {t:^6} {c:^6} {status}")

print()
print(f"=== Triangle Summary ===")
print(f"  Total REQs:  {len(all_reqs)}")
print(f"  Synced:      {len(synced)} (spec + test + code)")
print(f"  Broken:      {len(broken)} (missing at least one)")
print(f"  Orphans:     {len(orphans)} (in test/code but not spec)")
print(f"  Sync rate:   {len(synced)*100//len(all_reqs) if all_reqs else 0}%")

if broken:
    print()
    print("=== Broken REQs (need fixing) ===")
    for req, reason in broken:
        print(f"  {req}: {reason}")
        if req in test_reqs:
            print(f"    test: {', '.join(test_reqs[req])}")
        if req in code_reqs:
            print(f"    code: {', '.join(code_reqs[req])}")

if broken or orphans:
    exit(1)
else:
    print()
    print("PASS: Full triangle sync achieved")
    # Clear suspect REQs on successful full check
    import subprocess
    subprocess.run(["bash", os.path.join(os.environ.get("SCRIPT_DIR", "."), "forge-enforce.sh"), "check-suspect", "--clear-all"], capture_output=True)
    exit(0)
PYEOF
}

cmd_check_req() {
    local req="${1:?Usage: check-req REQ-AUTH-001}"
    [ -f "$SPEC" ] || { echo "ERROR: SPEC.md not found"; exit 1; }

    echo "=== Triangle check: $req ==="
    echo ""

    echo "SPEC:"
    grep -n "$req" "$SPEC" 2>/dev/null | head -3 || echo "  NOT FOUND"
    echo ""

    echo "TESTS:"
    grep -rn "$req" "$D"/apps/*/tests.py "$D"/e2e/*.py 2>/dev/null | head -5 || echo "  NOT FOUND"
    echo ""

    echo "CODE:"
    grep -rn "$req" "$D"/apps/*/models.py "$D"/apps/*/api.py "$D"/apps/*/services*.py "$D"/config/*.py 2>/dev/null | head -5 || echo "  NOT FOUND"
}

cmd_tdd_check() {
    local app="${1:?Usage: tdd-check <app_name>}"
    echo "=== TDD Check: $app ==="

    local test_file="$D/apps/$app/tests.py"
    local code_files=("$D/apps/$app/models.py" "$D/apps/$app/api.py" "$D/apps/$app/services.py")

    if [ ! -f "$test_file" ]; then
        echo "[FAIL] No test file: apps/$app/tests.py"
        echo "[ACTION] Write tests FIRST before any code"
        exit 1
    fi

    local test_count
    test_count=$(grep -c "def test_" "$test_file" 2>/dev/null || echo 0)
    echo "Tests found: $test_count in apps/$app/tests.py"

    if [ "$test_count" -eq 0 ]; then
        echo "[FAIL] Test file exists but has 0 test methods"
        echo "[ACTION] Write test methods before implementing code"
        exit 1
    fi

    echo "[PASS] Tests exist — safe to write code for $app"
}

cmd_create_issue() {
    local req="${1:?Usage: create-issue REQ-AUTH-001 type description}"
    local issue_type="${2:-fix}"
    local desc="${3:-Triangle broken for $req}"

    echo "Creating GitHub issue for $req..."
    gh issue create \
        --title "$issue_type($req): $desc" \
        --body "## Triangle Violation

**REQ:** $req
**Type:** $issue_type
**Description:** $desc

## Checklist
- [ ] Fix in SPEC.md
- [ ] Fix in test file
- [ ] Fix in code
- [ ] Run \`bash scripts/forge-triangle.sh check-req $req\` to verify
- [ ] Run \`bash scripts/forge-triangle.sh check\` for full sync

Generated by forge-triangle.sh" \
        --label "triangle-violation" 2>/dev/null || echo "gh not configured — create issue manually"
}

cmd_sync_report() {
    cmd_check 2>&1 | head -80
}

case "${1:-help}" in
    check)        cmd_check ;;
    check-req)    shift; cmd_check_req "$@" ;;
    sync-report)  cmd_sync_report ;;
    tdd-check)    shift; cmd_tdd_check "$@" ;;
    create-issue) shift; cmd_create_issue "$@" ;;
    *)
        echo "Forge Triangle Enforcer — SPEC ↔ TEST ↔ CODE"
        echo "  check              Full per-REQ triangle verification"
        echo "  check-req <REQ>    Check one REQ across spec/test/code"
        echo "  sync-report        Human-readable matrix"
        echo "  tdd-check <app>    Verify tests exist before code"
        echo "  create-issue <REQ> Create GitHub issue for broken triangle"
        ;;
esac
