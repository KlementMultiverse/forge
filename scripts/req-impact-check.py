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


def extract_reqs(text):
    """Extract all REQ tags from text."""
    return set(REQ_PATTERN.findall(text))


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
        # Skip test files, migrations, configs
        if any(skip in filepath.lower() for skip in ["test", "migration", "conftest", ".venv"]):
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
        if old_reqs and new_reqs:
            # Only flag REQs in the changed hunks, not entire file
            added_lines, removed_lines = get_changed_hunks(filepath)
            changed_text = "\n".join(added_lines + removed_lines)
            changed_reqs = extract_reqs(changed_text)

            # REQs that appear in changed hunks = suspect
            for req in changed_reqs:
                if req in new_reqs:  # Still present, but code around it changed
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

    # Update suspect state if requested
    if update_state and suspect_reqs:
        state = load_suspect_state()
        state["suspect_reqs"].update(suspect_reqs)
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
        sys.exit(0)


if __name__ == "__main__":
    main()
