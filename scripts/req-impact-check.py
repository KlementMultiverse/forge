#!/usr/bin/env python3
"""
req-impact-check.py — Pre-commit REQ impact analysis.

Detects when REQ tags are removed from staged files and blocks the commit.
When REQ-linked code is modified (but tags intact), flags suspect REQs.

Usage:
  req-impact-check.py --staged                    # check staged files (pre-commit)
  req-impact-check.py --staged --update-state     # also update suspect-reqs.json
  req-impact-check.py --check <file>              # check a single file

Exit codes:
  0 = OK (no REQ removals)
  1 = BLOCKED (REQ tags removed)

Implements #42: Pre-commit REQ impact hook
Implements #52: REQ dependency chains — suspect cascading
"""

import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone

# Unified REQ pattern — supports both [REQ-001] and REQ-AUTH-001 formats
REQ_PATTERN = re.compile(r'(?:\[REQ-\d+\]|REQ-[A-Z]+-\d+)')

SUSPECT_FILE = "docs/suspect-reqs.json"
SPEC_FILE = "SPEC.md"

# REQ dependency pattern: [REQ-AUTH-001] ... depends_on: REQ-CORE-001
DEP_PATTERN = re.compile(r'depends_on:\s*((?:REQ-[A-Z]+-\d+[\s,]*)+)', re.IGNORECASE)


def extract_reqs(text):
    """Extract all REQ tags from text."""
    return set(REQ_PATTERN.findall(text))


def build_req_dependency_graph():
    """Parse SPEC.md for REQ dependency chains.

    Looks for patterns like:
        [REQ-AUTH-001] User login — depends_on: REQ-CORE-001
        [REQ-AUTH-001] ... depends_on: REQ-CORE-001, REQ-CORE-002

    Returns dict: { parent_req: [child_reqs_that_depend_on_it] }
    """
    if not os.path.exists(SPEC_FILE):
        return {}

    with open(SPEC_FILE) as f:
        content = f.read()

    # Build forward map: req → what it depends on
    depends_on = {}
    for line in content.split("\n"):
        reqs_in_line = REQ_PATTERN.findall(line)
        dep_match = DEP_PATTERN.search(line)
        if reqs_in_line and dep_match:
            child_req = reqs_in_line[0]
            parents = REQ_PATTERN.findall(dep_match.group(1))
            depends_on[child_req] = parents

    # Build reverse map: parent → children that depend on it
    depended_by = {}
    for child, parents in depends_on.items():
        for parent in parents:
            depended_by.setdefault(parent, []).append(child)

    return depended_by


def cascade_suspects(suspect_reqs, dep_graph):
    """When a REQ becomes suspect, cascade to all REQs that depend on it."""
    cascaded = {}
    for req, info in suspect_reqs.items():
        dependents = dep_graph.get(req, [])
        for dep in dependents:
            if dep not in suspect_reqs and dep not in cascaded:
                cascaded[dep] = {
                    "reason": f"depends on suspect {req} ({info.get('reason', 'unknown')})",
                    "modified_by": info.get("modified_by", "cascade"),
                    "modified_at": datetime.now(timezone.utc).isoformat(),
                    "file": info.get("file", ""),
                    "verified": False,
                    "verified_at": None,
                    "cleared_by": None,
                    "verification_method": None,
                    "cascaded_from": req,
                }
    return cascaded


def get_staged_files():
    """Get list of staged files."""
    result = subprocess.run(
        ["git", "diff", "--cached", "--name-only", "--diff-filter=ACMR"],
        capture_output=True, text=True
    )
    return [f for f in result.stdout.strip().split("\n") if f and f.endswith(".py")]


def get_file_from_index(filepath):
    """Get file content from git index (staged version)."""
    result = subprocess.run(
        ["git", "show", f":{filepath}"],
        capture_output=True, text=True
    )
    return result.stdout if result.returncode == 0 else ""


def get_file_from_head(filepath):
    """Get file content from HEAD (before changes)."""
    result = subprocess.run(
        ["git", "show", f"HEAD:{filepath}"],
        capture_output=True, text=True
    )
    return result.stdout if result.returncode == 0 else ""


def get_changed_hunks(filepath):
    """Get only the changed lines (+ lines) from staged diff."""
    result = subprocess.run(
        ["git", "diff", "--cached", "-U0", "--", filepath],
        capture_output=True, text=True
    )
    added = []
    removed = []
    for line in result.stdout.split("\n"):
        if line.startswith("+") and not line.startswith("+++"):
            added.append(line[1:])
        elif line.startswith("-") and not line.startswith("---"):
            removed.append(line[1:])
    return added, removed


def load_suspect_state():
    """Load suspect REQs state file."""
    if os.path.exists(SUSPECT_FILE):
        try:
            with open(SUSPECT_FILE) as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            pass
    return {
        "version": "1.0.0",
        "suspect_reqs": {},
        "suspect_history": [],
    }


def save_suspect_state(state):
    """Save suspect REQs state file."""
    os.makedirs(os.path.dirname(SUSPECT_FILE), exist_ok=True)
    with open(SUSPECT_FILE, "w") as f:
        json.dump(state, f, indent=2)


def check_staged(update_state=False):
    """Check all staged files for REQ impact."""
    staged = get_staged_files()
    if not staged:
        return 0

    violations = []
    warnings = []
    suspect_reqs = {}

    for filepath in staged:
        # Skip test files, migrations, configs — use path segment checks to avoid false matches
        path_parts = filepath.replace("\\", "/").split("/")
        if any(part in ("tests", "test", "migrations", "conftest.py", ".venv", "__pycache__")
               for part in path_parts):
            continue
        if filepath.endswith("conftest.py"):
            continue

        # Get old (HEAD) and new (staged) content
        old_content = get_file_from_head(filepath)
        new_content = get_file_from_index(filepath)

        old_reqs = extract_reqs(old_content)
        new_reqs = extract_reqs(new_content)

        # REQs that were REMOVED — this is a violation
        removed_reqs = old_reqs - new_reqs
        for req in removed_reqs:
            violations.append(
                f"BLOCKED: {req} tag removed from {filepath}\n"
                f"         Run: forge-triangle.sh check-req {req}"
            )

        # REQs that still exist but code was modified — suspect
        # Flag ALL REQs in the file as suspect when the file is modified,
        # because code changes can break REQ behavior even if the tag line is untouched
        if new_reqs and (old_content != new_content):
            for req in new_reqs:
                warnings.append(
                    f"IMPACT: {filepath} modified (serves {req})\n"
                    f"        Verify triangle: forge-triangle.sh check-req {req}"
                )
                suspect_reqs[req] = {
                    "reason": f"code modified in {filepath}",
                    "modified_by": _get_current_agent(),
                    "modified_at": datetime.now(timezone.utc).isoformat(),
                    "file": filepath,
                    "verified": False,
                    "verified_at": None,
                    "cleared_by": None,
                    "verification_method": None,
                }

    # Report
    if violations:
        print("=" * 60)
        print("REQ IMPACT ANALYSIS — BLOCKED")
        print("=" * 60)
        for v in violations:
            print(f"  {v}")
        print()
        print("Fix: Restore the REQ tag, or update SPEC.md to remove the requirement.")
        print("     Then run: forge-triangle.sh check")
        return 1

    if warnings:
        print("=" * 60)
        print("REQ IMPACT ANALYSIS — WARNINGS")
        print("=" * 60)
        for w in warnings:
            print(f"  {w}")
        print()

    # Cascade suspects to dependent REQs (#52)
    if suspect_reqs:
        dep_graph = build_req_dependency_graph()
        cascaded = cascade_suspects(suspect_reqs, dep_graph)
        if cascaded:
            print(f"  CASCADE: {len(cascaded)} dependent REQ(s) also flagged suspect:")
            for req, info in cascaded.items():
                print(f"    {req} (depends on {info['cascaded_from']})")
            suspect_reqs.update(cascaded)

    # Bulk refactor threshold (#53) — escalate when too many REQs become suspect
    BULK_THRESHOLD = 20
    if len(suspect_reqs) > BULK_THRESHOLD:
        print("=" * 60)
        print("BULK REFACTOR DETECTED")
        print("=" * 60)
        print(f"  {len(suspect_reqs)} REQs suspect (threshold: {BULK_THRESHOLD})")
        print(f"  ACTION: Run forge-triangle.sh check before ANY gate proceeds")
        print(f"  This commit will proceed, but gates will block until triangle passes.")

    # Update suspect state if requested
    if update_state and suspect_reqs:
        state = load_suspect_state()
        state["suspect_reqs"].update(suspect_reqs)
        # Track bulk refactor flag
        if len(suspect_reqs) > BULK_THRESHOLD:
            state["bulk_refactor"] = {
                "detected_at": datetime.now(timezone.utc).isoformat(),
                "suspect_count": len(suspect_reqs),
                "requires_full_triangle": True,
            }
        save_suspect_state(state)
        print(f"  Updated {SUSPECT_FILE} with {len(suspect_reqs)} suspect REQ(s)")

    return 0


def check_file(filepath):
    """Check a single file for REQ tags."""
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return 1

    with open(filepath) as f:
        content = f.read()

    reqs = extract_reqs(content)
    if reqs:
        print(f"REQ tags in {filepath}:")
        for req in sorted(reqs):
            print(f"  {req}")
    else:
        print(f"No REQ tags in {filepath}")

    return 0


def _get_current_agent():
    """Try to determine the current agent from environment or git config."""
    # Check forge activity log for last agent
    try:
        if os.path.exists("docs/.builder-activity.log"):
            with open("docs/.builder-activity.log") as f:
                lines = f.readlines()
                if lines:
                    last = lines[-1]
                    if "Agent:" in last:
                        return last.split("Agent:")[1].strip().split()[0]
    except IOError:
        pass
    return "unknown"


def main():
    if "--staged" in sys.argv:
        update = "--update-state" in sys.argv
        sys.exit(check_staged(update_state=update))
    elif "--check" in sys.argv:
        idx = sys.argv.index("--check")
        if idx + 1 < len(sys.argv):
            sys.exit(check_file(sys.argv[idx + 1]))
        else:
            print("Usage: req-impact-check.py --check <file>")
            sys.exit(1)
    else:
        print("Usage:")
        print("  req-impact-check.py --staged [--update-state]")
        print("  req-impact-check.py --check <file>")
        sys.exit(1)


if __name__ == "__main__":
    main()
