#!/usr/bin/env python3
"""
forge-lint.py — Validate consistency of forge components.

Checks:
  1. All script deps in hooks actually exist
  2. All agents referenced in commands exist as files
  3. No orphan scripts (exist but nothing references them)
  4. No orphan agents (exist but no command references them)
  5. Hooks.json is valid JSON with expected structure

Usage:
  python3 forge-lint.py [forge-dir]
"""

import json
import os
import re
import sys
from pathlib import Path


def find_forge_dir():
    if len(sys.argv) > 1 and not sys.argv[1].startswith("--"):
        return Path(sys.argv[1])
    return Path.home() / "projects" / "forge"


def check_hook_scripts(forge_dir):
    """Check all scripts referenced by hooks exist."""
    errors = []
    hooks_file = forge_dir / "templates" / "hooks.json"
    if not hooks_file.exists():
        errors.append("MISSING: templates/hooks.json does not exist")
        return errors

    try:
        data = json.loads(hooks_file.read_text())
    except json.JSONDecodeError as e:
        errors.append(f"INVALID JSON: templates/hooks.json — {e}")
        return errors

    for event, hook_groups in data.get("hooks", {}).items():
        for group in hook_groups:
            for h in group.get("hooks", []):
                cmd = h.get("command", "")
                scripts = re.findall(r"(forge-[\w-]+\.sh)", cmd)
                for s in scripts:
                    if not (forge_dir / "scripts" / s).exists():
                        errors.append(f"MISSING SCRIPT: hooks [{event}] references {s} — not found in scripts/")
    return errors


def check_agent_files(forge_dir):
    """Check all agents referenced in commands exist as files."""
    errors = []
    # Collect all agent files
    agent_files = set()
    for f in forge_dir.glob("agents/universal/*.md"):
        agent_files.add(f.stem)
    for f in forge_dir.glob("agents/stacks/*/*.md"):
        agent_files.add(f.stem)

    # Find agent references in commands (skip templates — they have examples)
    referenced = set()
    for f in forge_dir.glob("commands/**/*.md"):
        content = f.read_text(errors="ignore")
        # Strip HTML comments (examples, not real references)
        content = re.sub(r"<!--.*?-->", "", content, flags=re.DOTALL)
        for m in re.findall(r"@([\w-]+)", content):
            referenced.add(m)

    # Check references that look like agents but have no file
    agent_suffixes = ("-agent", "-expert", "-architect", "-analyst",
                      "-miner", "-curator", "-fixer", "-critic",
                      "-enforcer", "-guide", "-writer")
    for ref in referenced:
        if any(ref.endswith(s) for s in agent_suffixes):
            if ref not in agent_files:
                errors.append(f"MISSING AGENT: @{ref} referenced in commands but no agent file exists")
    return errors


def check_orphan_scripts(forge_dir):
    """Find scripts that nothing references."""
    warnings = []
    # Collect all script files
    script_files = set()
    for f in forge_dir.glob("scripts/*.sh"):
        script_files.add(f.name)
    for f in forge_dir.glob("scripts/*.py"):
        if f.name not in ("forge-registry.py", "forge-lint.py"):
            script_files.add(f.name)

    # Find all script references across all files
    referenced = set()
    for pattern in ["commands/**/*.md", "templates/*.json", "scripts/*.sh", "scripts/*.py"]:
        for f in forge_dir.glob(pattern):
            content = f.read_text(errors="ignore")
            for m in re.findall(r"([\w-]+\.(?:sh|py))", content):
                referenced.add(m)

    orphans = script_files - referenced
    # Exclude self-references and known utilities
    orphans.discard("forge-registry.py")
    orphans.discard("forge-lint.py")
    orphans.discard("forge-shell.sh")

    for s in sorted(orphans):
        warnings.append(f"ORPHAN SCRIPT: {s} — exists but nothing references it")
    return warnings


def check_orphan_agents(forge_dir):
    """Find agents that no command references."""
    warnings = []
    agent_files = set()
    # Map: frontmatter name → filename stem (so @forge-pm counts for pm-orchestrator)
    name_to_file = {}
    for f in list(forge_dir.glob("agents/universal/*.md")) + list(forge_dir.glob("agents/stacks/*/*.md")):
        agent_files.add(f.stem)
        # Read frontmatter name field
        content = f.read_text(errors="ignore")
        m = re.search(r"^name:\s*(\S+)", content, re.MULTILINE)
        if m and m.group(1) != f.stem:
            name_to_file[m.group(1)] = f.stem

    # Find all agent references
    referenced = set()
    for pattern in ["commands/**/*.md", "agents/**/*.md"]:
        for f in forge_dir.glob(pattern):
            content = f.read_text(errors="ignore")
            for m in re.findall(r"@([\w-]+)", content):
                referenced.add(m)
                # If @forge-pm is referenced, also mark pm-orchestrator as referenced
                if m in name_to_file:
                    referenced.add(name_to_file[m])

    orphans = agent_files - referenced
    # Skip READMEs and known non-agent files
    orphans -= {"README"}
    for a in sorted(orphans):
        warnings.append(f"ORPHAN AGENT: {a} — file exists but no command references @{a}")
    return warnings


def check_hooks_structure(forge_dir):
    """Validate hooks.json has expected events."""
    errors = []
    hooks_file = forge_dir / "templates" / "hooks.json"
    if not hooks_file.exists():
        return errors

    data = json.loads(hooks_file.read_text())
    hooks = data.get("hooks", {})

    expected_events = {"Stop", "UserPromptSubmit", "PreToolUse", "PostToolUse"}
    actual_events = set(hooks.keys())
    missing = expected_events - actual_events
    for m in missing:
        errors.append(f"MISSING HOOK EVENT: {m} not found in hooks.json")

    # Count hooks
    total = sum(len(groups) for groups in hooks.values())
    if total < 8:
        errors.append(f"LOW HOOK COUNT: {total} hooks (expected 8)")
    return errors


def check_core_registry(forge_dir):
    """Validate forge-core.json checksums match actual files."""
    import hashlib
    warnings = []
    registry_file = forge_dir / "forge-core.json"
    if not registry_file.exists():
        return warnings  # No registry yet — skip silently

    data = json.loads(registry_file.read_text())
    components = data.get("components", {})
    drifted = 0
    missing = 0

    for path, info in components.items():
        full_path = forge_dir / path
        if not full_path.exists():
            warnings.append(f"REGISTRY DRIFT: {path} listed in forge-core.json but file missing")
            missing += 1
            continue

        actual = hashlib.sha256(full_path.read_bytes()).hexdigest()[:16]
        if actual != info.get("checksum", ""):
            drifted += 1

    if drifted > 0:
        warnings.append(f"REGISTRY DRIFT: {drifted} files changed since last forge-core.json update. Run: python3 scripts/forge-lint.py --update-registry")
    if missing > 0:
        warnings.append(f"REGISTRY MISSING: {missing} files in registry no longer exist")
    return warnings


def check_agent_frontmatter(forge_dir):
    """Validate all agents have required frontmatter fields."""
    errors = []
    for f in list(forge_dir.glob("agents/universal/*.md")) + list(forge_dir.glob("agents/stacks/*/*.md")):
        if f.name == "README.md":
            continue
        content = f.read_text(errors="ignore")
        if not content.startswith("---"):
            errors.append(f"AGENT NO FRONTMATTER: {f.relative_to(forge_dir)} — missing YAML frontmatter (name, description, tools)")
            continue
        fm = re.search(r"^---\s*\n(.*?)---", content, re.DOTALL)
        if fm:
            fm_text = fm.group(1)
            if not re.search(r"^name:", fm_text, re.MULTILINE):
                errors.append(f"AGENT NO NAME: {f.relative_to(forge_dir)} — frontmatter missing 'name:' field")
            if not re.search(r"^description:", fm_text, re.MULTILINE):
                errors.append(f"AGENT NO DESC: {f.relative_to(forge_dir)} — frontmatter missing 'description:' field")
            if not re.search(r"^tools:", fm_text, re.MULTILINE):
                errors.append(f"AGENT NO TOOLS: {f.relative_to(forge_dir)} — frontmatter missing 'tools:' field")
    return errors


def check_command_headers(forge_dir):
    """Validate all commands have # /name — description (after optional frontmatter)."""
    warnings = []
    for f in forge_dir.glob("commands/*.md"):
        content = f.read_text(errors="ignore")
        # Skip YAML frontmatter if present
        if content.startswith("---"):
            fm_end = content.find("---", 3)
            if fm_end != -1:
                content = content[fm_end + 3:].lstrip("\n")
        first_line = content.split("\n")[0] if content else ""
        if not re.match(r"^#\s+/\S+\s+(?:--|[—–-])\s+.+", first_line):
            warnings.append(f"COMMAND BAD HEADER: {f.name} — first heading should be '# /name — description'")
    return warnings


def update_registry(forge_dir):
    """Regenerate checksums in forge-core.json."""
    import hashlib
    registry_file = forge_dir / "forge-core.json"
    if not registry_file.exists():
        print("No forge-core.json found. Run the generator first.")
        return

    data = json.loads(registry_file.read_text())
    updated = 0
    for path, info in data.get("components", {}).items():
        full_path = forge_dir / path
        if full_path.exists():
            new_hash = hashlib.sha256(full_path.read_bytes()).hexdigest()[:16]
            if new_hash != info.get("checksum", ""):
                info["checksum"] = new_hash
                info["last_verified"] = __import__("datetime").date.today().isoformat()
                updated += 1

    data["generated"] = __import__("datetime").datetime.now(__import__("datetime").UTC).isoformat()
    registry_file.write_text(json.dumps(data, indent=2))
    print(f"Updated {updated} checksums in forge-core.json")


def main():
    forge_dir = find_forge_dir()
    if not forge_dir.exists():
        print(f"Error: {forge_dir} not found", file=sys.stderr)
        sys.exit(1)

    # Handle --update-registry flag
    if "--update-registry" in sys.argv:
        update_registry(forge_dir)
        return

    errors = []
    warnings = []

    print(f"Linting forge at {forge_dir}...")
    print()

    # Run all checks
    errors.extend(check_hook_scripts(forge_dir))
    errors.extend(check_agent_files(forge_dir))
    errors.extend(check_agent_frontmatter(forge_dir))
    errors.extend(check_hooks_structure(forge_dir))
    warnings.extend(check_command_headers(forge_dir))
    warnings.extend(check_orphan_scripts(forge_dir))
    warnings.extend(check_orphan_agents(forge_dir))
    warnings.extend(check_core_registry(forge_dir))

    # Report
    if errors:
        print(f"ERRORS ({len(errors)}):")
        for e in errors:
            print(f"  ✗ {e}")
        print()

    if warnings:
        print(f"WARNINGS ({len(warnings)}):")
        for w in warnings:
            print(f"  ⚠ {w}")
        print()

    if not errors and not warnings:
        print("✓ All checks passed. No errors or warnings.")
    elif not errors:
        print(f"✓ No errors. {len(warnings)} warnings.")
    else:
        print(f"✗ {len(errors)} errors, {len(warnings)} warnings.")
        sys.exit(1)


if __name__ == "__main__":
    main()
