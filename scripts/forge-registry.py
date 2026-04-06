#!/usr/bin/env python3
"""
forge-registry.py — Full traceability registry for forge components.

Scans all forge files (agents, commands, scripts, templates, hooks, rules),
extracts references, and produces a unified registry with:
  1. Component dependency graph (forward + computed reverse)
  2. Phase/step mapping (which files participate in which pipeline steps)
  3. Flow mapping (file participation across 9 core flows)
  4. Changelog generation (from conventional commits in git log)

Usage:
  python3 forge-registry.py [forge-dir]              # generate full registry
  python3 forge-registry.py --mermaid                 # print mermaid diagram
  python3 forge-registry.py --impact <file>           # show impact of changing a file
  python3 forge-registry.py --impact <file> --json    # impact as JSON
  python3 forge-registry.py --changelog               # generate changelog from git log
  python3 forge-registry.py --changelog --since <hash> # changelog since commit
  python3 forge-registry.py --changelog --component X # changelog for component X only
  python3 forge-registry.py --changelog --breaking    # breaking changes only

Implements:
  - #34: Phase/step mapping
  - #35: Reverse deps with action items + --impact CLI
  - #36: Flow mapping (9 flows)
  - #37: Changelog from conventional commits
"""

import json
import os
import re
import subprocess
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path


# ─── Phase boundaries (parsed from forge-phase-map.sh, not hardcoded) ───

def parse_phase_map(forge_dir):
    """Parse forge-phase-map.sh to get phase boundaries dynamically."""
    phase_map_file = forge_dir / "scripts" / "forge-phase-map.sh"
    boundaries = {}
    gate_steps = []
    phase_names = {}

    if not phase_map_file.exists():
        # Fallback defaults
        return {
            "boundaries": {0: 8, 1: 11, 2: 19, 3: 39, 4: 46, 5: 56, 6: 57},
            "gate_steps": [8, 11, 19, 39, 46, 56],
            "phase_names": {0: "Genesis", 1: "Specify", 2: "Architect", 3: "Implement",
                           4: "Validate", 5: "Review+Learn", 6: "Iterate"},
        }

    content = phase_map_file.read_text()

    # Parse PHASE_LAST_STEP
    for m in re.finditer(r'\[(\d+)\]=(\d+)', content):
        if "PHASE_LAST_STEP" in content[:content.index(m.group())].split("PHASE_LAST_STEP")[-1] if "PHASE_LAST_STEP" in content else "":
            boundaries[int(m.group(1))] = int(m.group(2))

    # Simpler: find the array block
    last_step_block = re.search(r'PHASE_LAST_STEP=\((.*?)\)', content, re.DOTALL)
    if last_step_block:
        boundaries = {}
        for m in re.finditer(r'\[(\d+)\]=(\d+)', last_step_block.group(1)):
            boundaries[int(m.group(1))] = int(m.group(2))

    # Parse GATE_STEPS
    gate_match = re.search(r'GATE_STEPS="([\d\s]+)"', content)
    if gate_match:
        gate_steps = [int(x) for x in gate_match.group(1).split()]

    # Parse PHASE_NAMES
    names_block = re.search(r'PHASE_NAMES=\((.*?)\)', content, re.DOTALL)
    if names_block:
        for m in re.finditer(r'\[(\d+)\]="([^"]+)"', names_block.group(1)):
            phase_names[int(m.group(1))] = m.group(2)

    return {
        "boundaries": boundaries or {0: 8, 1: 11, 2: 19, 3: 39, 4: 46, 5: 56, 6: 57},
        "gate_steps": gate_steps or [8, 11, 19, 39, 46, 56],
        "phase_names": phase_names or {0: "Genesis", 1: "Specify", 2: "Architect",
                                        3: "Implement", 4: "Validate", 5: "Review+Learn", 6: "Iterate"},
    }


# ─── Component Scanning ───

def find_forge_dir():
    if len(sys.argv) > 1 and not sys.argv[1].startswith("--"):
        return Path(sys.argv[1])
    return Path.home() / "projects" / "forge"


def scan_agents(forge_dir):
    agents = {}
    for pattern in ["agents/universal/*.md", "agents/stacks/*/*.md"]:
        for f in forge_dir.glob(pattern):
            agent_id = f.stem
            content = f.read_text(errors="ignore")
            deps = extract_frontmatter_deps(content)
            auto_deps = auto_detect_refs(content, "agent")
            # Extract frontmatter name for alias resolution
            fm_name = extract_frontmatter_field(content, "name")
            agents[agent_id] = {
                "type": "agent",
                "path": str(f.relative_to(forge_dir)),
                "depends_on": merge_deps(deps.get("depends_on", {}), auto_deps),
                "alias": fm_name if fm_name and fm_name != agent_id else None,
            }
    return agents


def scan_commands(forge_dir):
    commands = {}
    for f in forge_dir.glob("commands/*.md"):
        cmd_id = f.stem
        content = f.read_text(errors="ignore")
        deps = extract_frontmatter_deps(content)
        auto_deps = auto_detect_refs(content, "command")
        commands[cmd_id] = {
            "type": "command",
            "path": str(f.relative_to(forge_dir)),
            "depends_on": merge_deps(deps.get("depends_on", {}), auto_deps),
        }
    for f in forge_dir.glob("commands/forge-phases/*.md"):
        cmd_id = f"phase:{f.stem}"
        content = f.read_text(errors="ignore")
        auto_deps = auto_detect_refs(content, "command")
        commands[cmd_id] = {
            "type": "phase",
            "path": str(f.relative_to(forge_dir)),
            "depends_on": auto_deps,
        }
    return commands


def scan_scripts(forge_dir):
    scripts = {}
    for ext in ["*.sh", "*.py"]:
        for f in forge_dir.glob(f"scripts/{ext}"):
            # Include all scripts (forge-lint.py and forge-registry.py are part of install flow)
            script_id = f.name
            content = f.read_text(errors="ignore")
            deps = extract_meta_deps(content)
            auto_deps = auto_detect_script_refs(content)
            scripts[script_id] = {
                "type": "script",
                "path": str(f.relative_to(forge_dir)),
                "depends_on": merge_deps(deps.get("depends_on", {}), auto_deps),
            }
    return scripts


def scan_hooks(forge_dir):
    hooks = {}
    hooks_file = forge_dir / "templates" / "hooks.json"
    if not hooks_file.exists():
        return hooks
    data = json.loads(hooks_file.read_text())
    for event, hook_groups in data.get("hooks", {}).items():
        for i, group in enumerate(hook_groups):
            matcher = group.get("matcher", "(all)")
            hook_id = f"{event}:{matcher}" if matcher else event
            script_deps = []
            for h in group.get("hooks", []):
                cmd = h.get("command", "")
                found = re.findall(r"([\w-]+\.sh)", cmd)
                script_deps.extend(found)
            hooks[hook_id] = {
                "type": "hook",
                "path": "templates/hooks.json",
                "event": event,
                "matcher": matcher,
                "depends_on": {"scripts": list(set(script_deps))},
            }
    return hooks


def scan_templates(forge_dir):
    templates = {}
    for f in forge_dir.glob("templates/*.md"):
        templates[f.name] = {
            "type": "template",
            "path": str(f.relative_to(forge_dir)),
            "depends_on": {},
        }
    for f in forge_dir.glob("templates/*.json"):
        templates[f.name] = {
            "type": "template",
            "path": str(f.relative_to(forge_dir)),
            "depends_on": {},
        }
    for f in forge_dir.glob("templates/rules/*.md"):
        templates[f"rules/{f.name}"] = {
            "type": "template",
            "path": str(f.relative_to(forge_dir)),
            "depends_on": {},
        }
    # Git hook templates (no extension)
    for hook_name in ("commit-msg", "pre-commit"):
        hook_file = forge_dir / "templates" / hook_name
        if hook_file.exists():
            templates[hook_name] = {
                "type": "template",
                "path": f"templates/{hook_name}",
                "depends_on": {},
            }
    return templates


def scan_rules(forge_dir):
    rules = {}
    for f in forge_dir.glob("rules/*.md"):
        rules[f.name] = {
            "type": "rule",
            "path": str(f.relative_to(forge_dir)),
            "depends_on": {},
        }
    return rules


# ─── Dependency Extraction ───

def extract_frontmatter_field(content, field):
    """Extract a single field from YAML frontmatter."""
    if not content.startswith("---"):
        return None
    end = content.find("---", 3)
    if end == -1:
        return None
    fm = content[3:end]
    for line in fm.split("\n"):
        line = line.strip()
        if line.startswith(f"{field}:"):
            return line.split(":", 1)[1].strip().strip('"').strip("'")
    return None


def extract_frontmatter_deps(content):
    if not content.startswith("---"):
        return {}
    end = content.find("---", 3)
    if end == -1:
        return {}
    fm = content[3:end]
    deps = {}
    current_key = None
    for line in fm.split("\n"):
        line = line.strip()
        if line.startswith("depends_on:"):
            current_key = "depends_on"
            deps[current_key] = {}
        elif current_key and line.startswith(("scripts:", "commands:", "agents:", "rules:")):
            cat = line.split(":")[0]
            val = line.split(":", 1)[1].strip().strip("[]")
            deps[current_key][cat] = [v.strip() for v in val.split(",") if v.strip()]
        elif not line or (not line.startswith("-") and ":" in line and current_key):
            current_key = None
    return deps


def extract_meta_deps(content):
    deps = {}
    in_meta = False
    for line in content.split("\n"):
        if "# @forge-meta" in line:
            in_meta = True
            continue
        if "# @end-forge-meta" in line:
            in_meta = False
            continue
        if in_meta and line.startswith("#"):
            line = line.lstrip("# ").strip()
            if line.startswith("depends_on."):
                parts = line.split(":", 1)
                if len(parts) == 2:
                    key = parts[0].replace("depends_on.", "")
                    vals = [v.strip() for v in parts[1].split(",") if v.strip()]
                    deps.setdefault("depends_on", {})[key] = vals
    return deps


def auto_detect_refs(content, source_type):
    deps = defaultdict(list)
    for m in re.findall(r"@([\w-]+(?:-agent|expert|architect|analyst|miner|curator|fixer|critic|enforcer|guide|review|writer|engineer))", content):
        deps["agents"].append(m)
    for m in re.findall(r'subagent_type="([\w-]+)"', content):
        deps["agents"].append(m)
    for m in re.findall(r"(?:^|\s)/([\w-]+)(?:\s|$|\"|\))", content, re.MULTILINE):
        if m not in ("dev", "api", "etc", "bin", "usr", "home", "tmp", "var"):
            deps["commands"].append(m)
    for m in re.findall(r'skill:\s*"([\w:-]+)"', content):
        # Keep full namespaced skill name (e.g., "sc:estimate") as-is
        deps["commands"].append(m)
    for m in re.findall(r"(forge-[\w-]+\.sh)", content):
        deps["scripts"].append(m)
    return {k: sorted(set(v)) for k, v in deps.items() if v}


def auto_detect_script_refs(content):
    deps = defaultdict(list)
    for m in re.findall(r"(?:bash|source|\.)\s+.*?(forge-[\w-]+\.sh)", content):
        deps["scripts"].append(m)
    return {k: sorted(set(v)) for k, v in deps.items() if v}


def merge_deps(declared, auto):
    result = dict(declared)
    for key, vals in auto.items():
        existing = set(result.get(key, []))
        existing.update(vals)
        result[key] = sorted(existing)
    return result


# ─── Edge Building + Reverse Index (#35) ───

def build_edges(registry):
    edges = []
    for category, components in registry.items():
        for comp_id, comp in components.items():
            for dep_type, dep_list in comp.get("depends_on", {}).items():
                for dep in dep_list:
                    edges.append({
                        "from": f"{category}/{comp_id}",
                        "to": f"{dep_type}/{dep}",
                        "type": dep_type,
                    })
    return edges


def build_reverse_index(registry, edges):
    """Compute depended_by from forward edges. Never maintain manually."""
    reverse = defaultdict(lambda: defaultdict(list))
    for e in edges:
        to_parts = e["to"].split("/", 1)
        from_parts = e["from"].split("/", 1)
        if len(to_parts) == 2 and len(from_parts) == 2:
            to_cat, to_id = to_parts
            from_cat, from_id = from_parts
            if to_cat in registry and to_id in registry[to_cat]:
                if from_id not in reverse[f"{to_cat}/{to_id}"][from_cat]:
                    reverse[f"{to_cat}/{to_id}"][from_cat].append(from_id)
    return dict(reverse)


# ─── Action Items (#35) ───

ACTION_ITEMS = {
    "install.sh": [
        {"target": "~/.claude/", "action": "Re-run install.sh to propagate changes", "action_type": "execute", "priority": "required"},
    ],
    "templates/hooks.json": [
        {"target": "install.sh", "action": "Re-run to propagate hooks to ~/.claude/", "action_type": "execute", "priority": "required"},
        {"target": "commands/forge-phases/phase-a-setup.md", "action": "Update Step S8 if hook schema changed", "action_type": "review", "priority": "conditional", "condition": "hook_schema_changed"},
        {"target": "README.md", "action": "Update hooks reference table", "action_type": "edit", "priority": "required"},
        {"target": "docs/architecture.md", "action": "Update Hook Reference table", "action_type": "edit", "priority": "required"},
    ],
    "scripts/forge-enforce.sh": [
        {"target": "install.sh", "action": "Re-run to propagate script", "action_type": "execute", "priority": "required"},
        {"target": "docs/protocols/error-handling.md", "action": "Update if error types changed", "action_type": "review", "priority": "conditional", "condition": "error_types_changed"},
    ],
    "scripts/forge-phase-map.sh": [
        {"target": "install.sh", "action": "Re-run to propagate", "action_type": "execute", "priority": "required"},
        {"target": "scripts/forge-registry.py", "action": "Re-run to regenerate phase index", "action_type": "execute", "priority": "required"},
        {"target": "README.md", "action": "Update phase table if boundaries changed", "action_type": "review", "priority": "conditional", "condition": "phase_boundaries_changed"},
    ],
    "scripts/forge-phase-gate.sh": [
        {"target": "install.sh", "action": "Re-run to propagate", "action_type": "execute", "priority": "required"},
        {"target": "docs/protocols/error-handling.md", "action": "Update circuit breaker docs if logic changed", "action_type": "review", "priority": "conditional", "condition": "circuit_breaker_changed"},
    ],
    "forge-core.json": [
        {"target": "scripts/forge-lint.py", "action": "Run to validate checksums", "action_type": "validate", "priority": "required"},
    ],
    "templates/commit-msg": [
        {"target": "install.sh", "action": "Re-run to propagate hook", "action_type": "execute", "priority": "required"},
        {"target": "commands/forge-phases/phase-a-setup.md", "action": "Update Step S8 if format changed", "action_type": "review", "priority": "conditional", "condition": "format_changed"},
    ],
    "README.md": [
        {"target": "docs/architecture.md", "action": "Check for consistency", "action_type": "review", "priority": "informational"},
    ],
}

# Generate action items for agent/command/rule changes (pattern-based)
def get_action_items(path):
    """Get action items for a file path. Static items + pattern-based."""
    items = list(ACTION_ITEMS.get(path, []))

    # Pattern-based: all agents/commands/scripts/templates/rules need reinstall
    if any(path.startswith(p) for p in ("agents/", "commands/", "scripts/", "templates/", "rules/")):
        items.append({
            "target": "install.sh",
            "action": "Re-run to propagate to ~/.claude/",
            "action_type": "execute",
            "priority": "required",
        })
        items.append({
            "target": "forge-core.json",
            "action": "Update checksum with forge-lint.py --update-registry",
            "action_type": "execute",
            "priority": "required",
        })

    # Deduplicate by target
    seen = set()
    unique = []
    for item in items:
        key = (item["target"], item["action"])
        if key not in seen:
            seen.add(key)
            unique.append(item)

    return unique


# Global short-circuit: changes to these affect ALL projects
GLOBAL_SHORT_CIRCUIT = {
    "files": ["install.sh", "templates/hooks.json", "rules/*.md"],
    "action": "Flag ALL projects as requiring reinstall and full re-review",
}


# ─── Phase/Step Mapping (#34) ───

def scan_phase_mapping(forge_dir, registry, phase_map):
    """Scan phase files to build file→phase and phase→file mappings."""

    # Build lookup tables for resolution
    skill_to_file = {}
    for cmd_id, cmd in registry.get("commands", {}).items():
        if cmd["type"] == "command":
            skill_to_file[cmd_id] = cmd["path"]

    agent_to_file = {}
    for agent_id, agent in registry.get("agents", {}).items():
        agent_to_file[agent_id] = agent["path"]
        if agent.get("alias"):
            agent_to_file[agent["alias"]] = agent["path"]

    # Phase A mapping (S1-S10 steps)
    phase_a_steps = _scan_phase_a(forge_dir, skill_to_file, agent_to_file)

    # Phases 0-5 mapping (steps 1-56)
    phase_steps = _scan_numbered_phases(forge_dir, skill_to_file, agent_to_file, phase_map)

    # Merge into component entries
    file_phases = defaultdict(list)

    for step_id, files in phase_a_steps.items():
        for f in files:
            file_phases[f].append({"phase": "A", "steps": [step_id], "role": _infer_role(f)})

    for step_num, files in phase_steps.items():
        # Phase 3 dynamic steps are strings like "p3:N0"
        if isinstance(step_num, str) and step_num.startswith("p3:"):
            for f in files:
                file_phases[f].append({
                    "phase": 3,
                    "steps": [step_num],
                    "role": _infer_role(f),
                    "is_gate": False,
                    "step_pattern": step_num.split(":")[1],
                })
            continue
        phase_num = _get_phase(step_num, phase_map["boundaries"])
        is_gate = step_num in phase_map["gate_steps"]
        for f in files:
            file_phases[f].append({
                "phase": phase_num,
                "steps": [step_num],
                "role": _infer_role(f),
                "is_gate": is_gate,
            })

    # Consolidate: merge steps within same phase for same file
    consolidated = {}
    for f, entries in file_phases.items():
        by_phase = defaultdict(lambda: {"steps": [], "role": None, "is_gate": False, "step_pattern": None})
        for entry in entries:
            key = str(entry["phase"])
            by_phase[key]["steps"].extend(entry["steps"])
            by_phase[key]["role"] = entry.get("role")
            if entry.get("is_gate"):
                by_phase[key]["is_gate"] = True
            if entry.get("step_pattern"):
                by_phase[key]["step_pattern"] = entry["step_pattern"]
        result = []
        for k, v in sorted(by_phase.items()):
            entry = {
                "phase": k if not k.isdigit() else int(k),
                "steps": sorted(set(v["steps"]), key=lambda x: (isinstance(x, str), str(x))),
                "role": v["role"],
                "is_gate": v["is_gate"],
            }
            if v["step_pattern"]:
                entry["step_pattern"] = v["step_pattern"]
            result.append(entry)
        consolidated[f] = result

    # Build reverse index: phase→step→files
    phase_index = []
    all_step_files = defaultdict(lambda: defaultdict(list))
    for f, phases in consolidated.items():
        for p in phases:
            for s in p["steps"]:
                all_step_files[str(p["phase"])][str(s)].append(f)

    def natural_sort_key(s):
        return [int(c) if c.isdigit() else c for c in re.split(r'(\d+)', s)]

    for phase, steps in sorted(all_step_files.items(), key=lambda x: natural_sort_key(x[0])):
        for step, files in sorted(steps.items(), key=lambda x: natural_sort_key(x[0])):
            is_gate = int(step) in phase_map["gate_steps"] if step.isdigit() else False
            phase_index.append({
                "phase": int(phase) if phase.isdigit() else phase,
                "step": int(step) if step.isdigit() else step,
                "is_gate": is_gate,
                "files": sorted(set(files)),
            })

    return consolidated, phase_index


def _scan_phase_a(forge_dir, skill_to_file, agent_to_file):
    """Extract file references from phase-a-setup.md."""
    phase_a = forge_dir / "commands" / "forge-phases" / "phase-a-setup.md"
    if not phase_a.exists():
        return {}

    content = phase_a.read_text(errors="ignore")
    steps = {}

    # S1-S10 step markers
    step_pattern = re.compile(r'\*\*STEP (S\d+(?:-\w+)?)')
    current_step = None
    current_block = []

    for line in content.split("\n"):
        m = step_pattern.search(line)
        if m:
            if current_step and current_block:
                steps[current_step] = _extract_files_from_block(
                    "\n".join(current_block), skill_to_file, agent_to_file)
            current_step = m.group(1)
            current_block = [line]
        elif current_step:
            current_block.append(line)

    if current_step and current_block:
        steps[current_step] = _extract_files_from_block(
            "\n".join(current_block), skill_to_file, agent_to_file)

    return steps


def _scan_numbered_phases(forge_dir, skill_to_file, agent_to_file, phase_map):
    """Extract file references from numbered phase files."""
    steps = {}

    for phase_file in sorted(forge_dir.glob("commands/forge-phases/phase-*.md")):
        if "phase-a" in phase_file.name:
            continue
        content = phase_file.read_text(errors="ignore")

        # Match STEP N patterns
        step_pattern = re.compile(r'STEP\s+(\d+)\s')
        current_step = None
        current_block = []

        for line in content.split("\n"):
            m = step_pattern.search(line)
            if m:
                if current_step is not None and current_block:
                    steps[current_step] = _extract_files_from_block(
                        "\n".join(current_block), skill_to_file, agent_to_file)
                current_step = int(m.group(1))
                current_block = [line]
            elif current_step is not None:
                current_block.append(line)

        if current_step is not None and current_block:
            steps[current_step] = _extract_files_from_block(
                "\n".join(current_block), skill_to_file, agent_to_file)

        # Phase 3 dynamic steps (N0-N9 pattern)
        if "phase-3" in phase_file.name:
            for label in ["N0", "N1", "N2", "N3", "N4", "N5", "N6", "N7", "N8", "N9"]:
                pattern = re.compile(rf'STEP\s+{label}\b')
                block_lines = []
                capturing = False
                for line in content.split("\n"):
                    if pattern.search(line):
                        capturing = True
                        block_lines = [line]
                    elif capturing and re.search(r'STEP\s+(N\d|[\d]+)\b', line) and not pattern.search(line):
                        capturing = False
                    elif capturing:
                        block_lines.append(line)
                if block_lines:
                    files = _extract_files_from_block(
                        "\n".join(block_lines), skill_to_file, agent_to_file)
                    # Store as step_pattern entries under a synthetic step range
                    for f in files:
                        steps.setdefault(f"p3:{label}", [])
                        if f not in steps[f"p3:{label}"]:
                            steps[f"p3:{label}"].append(f)

    return steps


def _extract_files_from_block(block, skill_to_file, agent_to_file):
    """Extract referenced forge files from a step block."""
    files = []

    # skill: "name" references
    for m in re.findall(r'skill:\s*"([\w:-]+)"', block):
        name = m.split(":")[0] if ":" in m else m
        if name in skill_to_file:
            files.append(skill_to_file[name])

    # subagent_type="name" references
    for m in re.findall(r'subagent_type="([\w-]+)"', block):
        if m in agent_to_file:
            files.append(agent_to_file[m])

    # @agent-name references
    for m in re.findall(r"@([\w-]+(?:-agent|expert|architect|analyst|miner|curator|fixer|critic|enforcer|guide|review|writer|engineer))", block):
        if m in agent_to_file:
            files.append(agent_to_file[m])

    # Script references
    for m in re.findall(r"(forge-[\w-]+\.sh)", block):
        files.append(f"scripts/{m}")

    # Direct script references like scripts/traceability.sh
    for m in re.findall(r"scripts/([\w-]+\.sh)", block):
        files.append(f"scripts/{m}")

    return sorted(set(files))


def _infer_role(path):
    """Infer the role of a file based on its path."""
    if "gate" in path:
        return "gate"
    if "enforce" in path or "state" in path:
        return "enforcement"
    if "phase-map" in path:
        return "routing"
    if "traceability" in path or "sync-report" in path:
        return "validation"
    if "review" in path or "critic" in path:
        return "review"
    if "security" in path:
        return "security"
    if "architect" in path:
        return "design"
    if "quality" in path or "test" in path:
        return "testing"
    if "requirements" in path or "spec" in path:
        return "requirements"
    if "discover" in path or "research" in path:
        return "research"
    if "deploy" in path or "docker" in path:
        return "infrastructure"
    if "template" in path:
        return "template"
    if "observer" in path:
        return "approval"
    if "playbook" in path or "retro" in path:
        return "learning"
    return "implementation"


def _get_phase(step, boundaries):
    """Get phase number for a step."""
    prev_end = 0
    for phase in sorted(boundaries.keys()):
        if step <= boundaries[phase]:
            return phase
        prev_end = boundaries[phase]
    return max(boundaries.keys())


# ─── Flow Mapping (#36) ───

FLOWS = {
    "install": {
        "description": "Global installation of forge components to ~/.claude/",
        "trigger": "./install.sh",
        "spans": [
            {"order": 1, "file": "install.sh", "role": "orchestrator",
             "action": "copies agents, commands, rules, scripts, templates to ~/.claude/"},
            {"order": 2, "file": "scripts/forge-lint.py", "role": "validator",
             "action": "validates all components", "parallel_group": "validate"},
            {"order": 2, "file": "scripts/forge-registry.py", "role": "indexer",
             "action": "generates dependency graph", "parallel_group": "validate"},
        ],
    },
    "hook_execution": {
        "description": "Runtime hook pipeline on each Claude Code event",
        "trigger": "Claude Code event (Stop, UserPromptSubmit, PreToolUse, PostToolUse)",
        "spans": [
            {"order": 1, "file": "templates/hooks.json", "role": "config",
             "action": "defines 8 hooks with matchers and commands"},
            {"order": 2, "file": "scripts/forge-phase-gate.sh", "role": "gate-checker",
             "triggered_by": "Stop hook",
             "action": "checks observer + CodeRabbit approval",
             "on_failure": {"action": "block_and_wait", "exits_flow": False}},
            {"order": 3, "file": "scripts/forge-auto-state.sh", "role": "state-updater",
             "triggered_by": "PostToolUse Agent/Skill hooks",
             "action": "maps agent/skill to step number, updates forge-state.json"},
            {"order": 4, "file": "scripts/forge-state-sync.sh", "role": "state-syncer",
             "triggered_by": "UserPromptSubmit hook",
             "action": "syncs project state before each prompt"},
        ],
    },
    "phase_transition": {
        "description": "Moving between phases via gate approval",
        "trigger": "/gate phase-N",
        "spans": [
            {"order": 1, "file": "scripts/forge-enforce.sh", "role": "gate-validator",
             "action": "check-gate verifies all steps complete", "shared": True},
            {"order": 2, "file": "scripts/forge-phase-gate.sh", "role": "approval-checker",
             "action": "checks observer + CodeRabbit approval",
             "on_failure": {"action": "circuit_breaker", "exits_flow": True}},
            {"order": 3, "file": "scripts/forge-fsm.sh", "role": "state-machine",
             "action": "drives phase transition logic"},
            {"order": 4, "file": "scripts/forge-phase-map.sh", "role": "boundary-resolver",
             "action": "maps step to phase", "shared": True},
        ],
    },
    "project_bootstrap": {
        "description": "Phase A: new project setup from empty directory",
        "trigger": "/forge on empty directory (no CLAUDE.md)",
        "spans": [
            {"order": 1, "file": "commands/forge-phases/phase-a-setup.md", "role": "orchestrator",
             "action": "10 steps: detect stack, create CLAUDE.md, SPEC.md, scaffold"},
            {"order": 2, "file": "templates/CLAUDE.template.md", "role": "template",
             "action": "read by Step S3, provides CLAUDE.md skeleton"},
            {"order": 3, "file": "templates/SPEC.template.md", "role": "template",
             "action": "read by Step S4, provides SPEC.md skeleton"},
            {"order": 4, "file": "templates/hooks.json", "role": "template",
             "action": "copied to .claude/settings.json in Step S8"},
            {"order": 5, "file": "templates/commit-msg", "role": "template",
             "action": "copied to .git/hooks/commit-msg in Step S8"},
        ],
    },
    "planning": {
        "description": "Phases 0-2: research, requirements, feasibility, architecture, and design",
        "trigger": "/forge on initialized project (steps 1-19)",
        "spans": [
            {"order": 1, "file": "commands/discover.md", "role": "researcher",
             "action": "deep domain research"},
            {"order": 2, "file": "commands/requirements.md", "role": "analyst",
             "action": "elicit and validate requirements"},
            {"order": 3, "file": "commands/feasibility.md", "role": "evaluator",
             "action": "architecture feasibility check"},
            {"order": 4, "file": "commands/generate-spec.md", "role": "specifier",
             "action": "generate full SPEC.md"},
            {"order": 5, "file": "commands/challenge.md", "role": "challenger",
             "action": "stress-test spec",
             "on_failure": {"action": "RETHINK_stop", "exits_flow": True}},
            {"order": 6, "file": "commands/bootstrap.md", "role": "scaffolder",
             "action": "create project scaffold"},
            {"order": 7, "file": "commands/specify.md", "role": "detailer",
             "action": "detailed proposal with Given/When/Then"},
            {"order": 8, "file": "commands/design-doc.md", "role": "designer",
             "action": "10-section design document"},
            {"order": 9, "file": "commands/plan-tasks.md", "role": "planner",
             "action": "break design into ordered GitHub issues"},
        ],
    },
    "tdd_cycle": {
        "description": "Phase 3: per-issue TDD loop with strict agent separation",
        "trigger": "Each GitHub issue in dependency order",
        "spans": [
            {"order": 1, "file": "agents/universal/backend-architect.md", "role": "designer",
             "action": "task design doc (N0)", "step_pattern": "N0"},
            {"order": 2, "file": "agents/universal/context-loader-agent.md", "role": "context",
             "action": "fetch library docs via context7 (N1)", "step_pattern": "N1"},
            {"order": 3, "file": "agents/universal/requirements-analyst.md", "role": "spec",
             "action": "add REQ to SPEC.md (N2)", "step_pattern": "N2"},
            {"order": 4, "file": "agents/universal/quality-engineer.md", "role": "tester",
             "action": "write tests from SPEC, must FAIL (N3)", "step_pattern": "N3",
             "loop_until": "tests_fail"},
            {"order": 5, "file": "(domain-agent)", "role": "coder",
             "action": "write code to make tests PASS (N4)", "step_pattern": "N4",
             "loop_until": "tests_pass", "max_iterations": 3},
            {"order": 6, "file": "scripts/traceability.sh", "role": "validator",
             "action": "100% REQ coverage check (N6)", "step_pattern": "N6"},
            {"order": 7, "file": "agents/universal/security-engineer.md", "role": "security",
             "action": "security review (N7)", "step_pattern": "N7"},
            {"order": 8, "file": "agents/universal/reviewer.md", "role": "reviewer",
             "action": "rate 1-5, must be >=4 (N8)", "step_pattern": "N8",
             "on_failure": {"action": "fix_and_retry", "exits_flow": False}},
        ],
    },
    "review_cycle": {
        "description": "Code review and gate approval",
        "trigger": "/review command at phase boundary",
        "spans": [
            {"order": 1, "file": "commands/review.md", "role": "reviewer",
             "action": "inline code review of all changes"},
            {"order": 2, "file": "commands/checkpoint.md", "role": "self-check",
             "action": "self-review checkpoint"},
            {"order": 3, "file": "commands/gate.md", "role": "gate",
             "action": "observer + CodeRabbit approval"},
        ],
    },
    "ship": {
        "description": "Final release: audit, security, gate, and PR merge",
        "trigger": "Phase 5 gate pass (step 56)",
        "spans": [
            {"order": 1, "file": "commands/audit-patterns.md", "role": "auditor",
             "action": "pattern compliance check (>90%)"},
            {"order": 2, "file": "commands/security-scan.md", "role": "scanner",
             "action": "OWASP top 10 security audit"},
            {"order": 3, "file": "commands/gate.md", "role": "gate",
             "action": "final gate check → merge PR"},
        ],
    },
    "observer_approval": {
        "description": "Human-in-the-loop approval for gate checks",
        "trigger": "forge observe <project> command",
        "spans": [
            {"order": 1, "file": "scripts/forge-shell.sh", "role": "initiator",
             "action": "observer session management"},
            {"order": 2, "file": "scripts/forge-observer-check.sh", "role": "checker",
             "action": "verifies observer presence and reviews"},
            {"order": 3, "file": "scripts/forge-observer-approve.sh", "role": "approver",
             "action": "records approval, unblocks gate"},
        ],
    },
}


def build_file_flows(flows):
    """Build reverse index: file → flows it participates in."""
    file_flows = defaultdict(list)
    for flow_name, flow in flows.items():
        for span in flow.get("spans", []):
            f = span.get("file", "")
            if f.startswith("("):  # Skip placeholders like (domain-agent)
                continue
            entry = {
                "flow": flow_name,
                "role": span.get("role"),
                "order": span.get("order"),
            }
            if span.get("shared"):
                entry["shared"] = True
            file_flows[f].append(entry)
    return dict(file_flows)


# ─── Changelog (#37) ───

ALLOWED_SCOPES = {"scripts", "agents", "commands", "templates", "rules", "hooks", "docs"}

CONVENTIONAL_COMMIT_RE = re.compile(
    r'^(?P<type>feat|fix|chore|docs|refactor|test|perf|ci|build|revert)'
    r'(?:\((?P<scope>[^)]+)\))?'
    r'(?P<breaking>!)?'
    r':\s*(?P<subject>.+?)(?:\s+#(?P<issue>\d+))?$'
)

SCOPE_TO_COMPONENT = {
    "scripts": "scripts", "agents": "agents", "commands": "commands",
    "templates": "templates", "rules": "rules", "hooks": "hooks", "docs": "docs",
}

TYPE_TO_CHANGE = {
    "feat": "feature", "fix": "bugfix", "chore": "chore", "docs": "documentation",
    "refactor": "refactor", "test": "test", "perf": "performance",
    "ci": "ci", "build": "build", "revert": "revert",
}

REQUIRES_REINSTALL_SCOPES = {"scripts", "agents", "commands", "templates", "rules", "hooks"}


def generate_changelog(forge_dir, since=None, component=None, breaking_only=False):
    """Generate structured changelog from git log with conventional commits."""
    # Get commit metadata (hash, date, subject, body) separately from file list
    # to avoid mixing commit message body text into file paths
    fmt_cmd = ["git", "-C", str(forge_dir), "log", "--format=%H|%aI|%s|%b", "-z"]
    if since:
        fmt_cmd.append(f"{since}..HEAD")

    try:
        result = subprocess.run(fmt_cmd, capture_output=True, text=True, timeout=30)
        if result.returncode != 0:
            return {}
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return {}

    changelog = defaultdict(list)

    # Parse commits from NUL-separated output
    for record in result.stdout.split("\0"):
        record = record.strip()
        if not record:
            continue

        parts = record.split("|", 3)
        if len(parts) < 3:
            continue

        commit_hash, date, subject = parts[0], parts[1], parts[2]
        body = parts[3] if len(parts) == 4 else ""
        full_msg = f"{subject}\n{body}" if body else subject

        m = CONVENTIONAL_COMMIT_RE.match(subject)
        if not m:
            continue

        scope = m.group("scope") or "general"
        if scope not in ALLOWED_SCOPES:
            scope = "general"
        comp = SCOPE_TO_COMPONENT.get(scope, scope)

        if component and comp != component:
            continue

        is_breaking = bool(m.group("breaking")) or "BREAKING" in full_msg

        if breaking_only and not is_breaking:
            continue

        # Find issue references anywhere in commit message
        issues = sorted(set(re.findall(r"#(\d+)", full_msg)))

        # Get file list using git diff-tree (plumbing, clean — no message body)
        files = []
        try:
            files_result = subprocess.run(
                ["git", "-C", str(forge_dir), "diff-tree", "--no-commit-id", "--name-only", "-r", commit_hash],
                capture_output=True, text=True, timeout=10
            )
            if files_result.returncode == 0:
                files = [f for f in files_result.stdout.strip().splitlines() if f]
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass

        # Determine requires_reinstall from actual files
        reinstall = False
        if files:
            reinstall = any(
                f.startswith(p) for f in files
                for p in ("scripts/", "agents/", "commands/", "templates/", "rules/")
            )
        else:
            reinstall = scope in REQUIRES_REINSTALL_SCOPES

        entry = {
            "date": date[:10],
            "commit": commit_hash[:8],
            "change_type": TYPE_TO_CHANGE.get(m.group("type"), m.group("type")),
            "scope": scope,
            "summary": m.group("subject"),
            "breaking": is_breaking,
            "requires_reinstall": reinstall,
        }
        if files:
            entry["files"] = files
        if issues:
            entry["issues"] = [f"#{i}" for i in issues]

        changelog[comp].append(entry)

    return dict(changelog)


# ─── Impact Analysis (#35) ───

def compute_impact(file_path, registry, edges, reverse_index, file_phases, file_flows_map):
    """Compute full impact of changing a file."""
    # Normalize path
    norm = file_path.replace("\\", "/")

    # Check global short-circuit
    is_global = False
    for pattern in GLOBAL_SHORT_CIRCUIT["files"]:
        if "*" in pattern:
            import fnmatch
            if fnmatch.fnmatch(norm, pattern):
                is_global = True
                break
        elif norm == pattern:
            is_global = True
            break

    # Find reverse deps with DFS (cycle-safe)
    dependents = []
    visited = set()

    def _walk(target):
        if target in visited:
            return
        visited.add(target)
        key = target
        if key in reverse_index:
            for cat, ids in reverse_index[key].items():
                for dep_id in ids:
                    dep_key = f"{cat}/{dep_id}"
                    dependents.append(dep_key)
                    _walk(dep_key)

    # Find which category/id this file belongs to
    for cat, components in registry.items():
        for comp_id, comp in components.items():
            if comp.get("path") == norm:
                _walk(f"{cat}/{comp_id}")
                break

    # Get action items for the changed file itself
    direct_actions = get_action_items(norm)

    # Get action items per dependent
    dependent_actions = {}
    for dep in sorted(set(dependents)):
        # Resolve dep path
        dep_parts = dep.split("/", 1)
        if len(dep_parts) == 2:
            dep_cat, dep_id = dep_parts
            if dep_cat in registry and dep_id in registry[dep_cat]:
                dep_path = registry[dep_cat][dep_id].get("path", "")
                dep_acts = get_action_items(dep_path)
                if dep_acts:
                    dependent_actions[dep] = dep_acts

    # Get phase involvement
    phases = file_phases.get(norm, [])

    # Get flow involvement
    flows = file_flows_map.get(norm, [])

    return {
        "file": norm,
        "is_global_short_circuit": is_global,
        "dependents": sorted(set(dependents)),
        "action_items": direct_actions,
        "dependent_actions": dependent_actions,
        "phases": phases,
        "flows": flows,
    }


def print_impact(impact):
    """Pretty-print impact analysis."""
    print(f"\nImpact report for: {impact['file']}")
    print("=" * 60)

    if impact["is_global_short_circuit"]:
        print("\n!! GLOBAL SHORT-CIRCUIT — ALL projects affected")
        print(f"   {GLOBAL_SHORT_CIRCUIT['action']}")

    if impact["action_items"]:
        print("\nRequired actions:")
        for item in impact["action_items"]:
            if item["priority"] == "required":
                print(f"  [{item['action_type']:8s}]  {item['target']} — {item['action']}")
        cond = [i for i in impact["action_items"] if i["priority"] == "conditional"]
        if cond:
            print("\nConditional actions:")
            for item in cond:
                condition = item.get("condition", "")
                print(f"  [{item['action_type']:8s}]  {item['target']} — {item['action']} (if {condition})")

    if impact["dependents"]:
        print(f"\nReverse dependents ({len(impact['dependents'])}):")
        for d in impact["dependents"][:20]:
            print(f"  - {d}")
        if len(impact["dependents"]) > 20:
            print(f"  ... and {len(impact['dependents']) - 20} more")

    if impact["phases"]:
        print("\nPhase involvement:")
        for p in impact["phases"]:
            steps = ", ".join(str(s) for s in p["steps"])
            gate = " [GATE]" if p.get("is_gate") else ""
            print(f"  Phase {p['phase']}: steps {steps} ({p['role']}){gate}")

    if impact["flows"]:
        print("\nFlow participation:")
        for f in impact["flows"]:
            print(f"  - {f['flow']} (role: {f['role']}, order: {f['order']})")

    print()


# ─── Mermaid Diagram ───

def generate_mermaid(registry, edges):
    lines = ["graph TD"]
    type_map = {"hooks": "Hook", "scripts": "Script", "commands": "Command",
                "agents": "Agent", "rules": "Rule", "templates": "Template"}

    connected = set()
    for e in edges:
        connected.add(e["from"])
        connected.add(e["to"])

    for category, components in registry.items():
        label = type_map.get(category, category)
        has_connected = any(f"{category}/{cid}" in connected for cid in components)
        if has_connected:
            lines.append(f"    subgraph {label}s")
            for comp_id in components:
                node_id = f"{category}/{comp_id}".replace("/", "_").replace("-", "_").replace(":", "_").replace(".", "_")
                full_id = f"{category}/{comp_id}"
                if full_id in connected:
                    short = comp_id[:25]
                    lines.append(f"        {node_id}[{short}]")
            lines.append("    end")

    for e in edges:
        from_id = e["from"].replace("/", "_").replace("-", "_").replace(":", "_").replace(".", "_")
        to_id = e["to"].replace("/", "_").replace("-", "_").replace(":", "_").replace(".", "_")
        lines.append(f"    {from_id} --> {to_id}")

    return "\n".join(lines)


# ─── Main ───

def main():
    forge_dir = find_forge_dir()
    if not forge_dir.exists():
        print(f"Error: {forge_dir} not found", file=sys.stderr)
        sys.exit(1)

    # Parse phase boundaries dynamically
    phase_map = parse_phase_map(forge_dir)

    # Scan all components
    registry = {
        "agents": scan_agents(forge_dir),
        "commands": scan_commands(forge_dir),
        "scripts": scan_scripts(forge_dir),
        "hooks": scan_hooks(forge_dir),
        "templates": scan_templates(forge_dir),
        "rules": scan_rules(forge_dir),
    }

    # Build edges + reverse index
    edges = build_edges(registry)
    reverse_index = build_reverse_index(registry, edges)

    # Phase mapping
    file_phases, phase_index = scan_phase_mapping(forge_dir, registry, phase_map)

    # Flow mapping
    file_flows_map = build_file_flows(FLOWS)

    # ─── CLI Modes ───

    if "--impact" in sys.argv:
        idx = sys.argv.index("--impact")
        if idx + 1 >= len(sys.argv):
            print("Usage: forge-registry.py --impact <file>", file=sys.stderr)
            sys.exit(1)
        target = sys.argv[idx + 1]
        impact = compute_impact(target, registry, edges, reverse_index, file_phases, file_flows_map)
        if "--json" in sys.argv:
            print(json.dumps(impact, indent=2))
        else:
            print_impact(impact)
        return

    if "--changelog" in sys.argv:
        since = None
        component = None
        breaking_only = "--breaking" in sys.argv
        if "--since" in sys.argv:
            since = sys.argv[sys.argv.index("--since") + 1]
        if "--component" in sys.argv:
            component = sys.argv[sys.argv.index("--component") + 1]
        cl = generate_changelog(forge_dir, since, component, breaking_only=breaking_only)
        print(json.dumps(cl, indent=2))
        return

    if "--mermaid" in sys.argv:
        print(generate_mermaid(registry, edges))
        return

    # ─── Full Registry Generation ───

    # Stats
    stats = {k: len(v) for k, v in registry.items()}
    stats["edges"] = len(edges)
    stats["phase_mapped_components"] = len(file_phases)
    stats["flows"] = len(FLOWS)

    # Clean registry for output (remove internal fields like 'alias')
    clean_registry = {}
    for cat, components in registry.items():
        clean_registry[cat] = {}
        for comp_id, comp in components.items():
            entry = {k: v for k, v in comp.items() if k != "alias"}
            # Add phases if available
            if comp.get("path") and comp["path"] in file_phases:
                entry["phases"] = file_phases[comp["path"]]
            clean_registry[cat][comp_id] = entry

    # Changelog
    changelog = generate_changelog(forge_dir)

    # Output
    output = {
        "version": "2.0",
        "generated": datetime.now(timezone.utc).isoformat(),
        "forge_dir": str(forge_dir),
        "stats": stats,
        "global_short_circuit": GLOBAL_SHORT_CIRCUIT,
        "components": clean_registry,
        "edges": edges,
        "indexes": {
            "phase_index": phase_index,
            "reverse_deps": {k: dict(v) for k, v in reverse_index.items()},
            "file_flows": file_flows_map,
        },
        "flows": FLOWS,
        "changelog": changelog,
    }

    # Write registry
    out_file = forge_dir / "forge-registry.json"
    out_file.write_text(json.dumps(output, indent=2))

    # Print summary
    print(f"Registry v2.0: {out_file}")
    print(f"  Agents:       {stats['agents']}")
    print(f"  Commands:     {stats['commands']}")
    print(f"  Scripts:      {stats['scripts']}")
    print(f"  Hooks:        {stats['hooks']}")
    print(f"  Templates:    {stats['templates']}")
    print(f"  Rules:        {stats['rules']}")
    print(f"  Edges:        {stats['edges']}")
    print(f"  Phase-mapped: {stats['phase_mapped_components']}")
    print(f"  Flows:        {stats['flows']}")
    if changelog:
        total_entries = sum(len(v) for v in changelog.values())
        print(f"  Changelog:    {total_entries} entries across {len(changelog)} components")

    # Mermaid diagram
    mermaid = generate_mermaid(registry, edges)
    mermaid_file = forge_dir / "docs" / "dependency-graph.md"
    mermaid_file.write_text(
        f"# Forge Dependency Graph\n\nAuto-generated by `forge-registry.py`.\n\n```mermaid\n{mermaid}\n```\n")
    print(f"  Diagram:      {mermaid_file}")


if __name__ == "__main__":
    main()
