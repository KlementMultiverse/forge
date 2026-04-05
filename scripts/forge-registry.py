#!/usr/bin/env python3
"""
forge-registry.py — Auto-generate dependency graph for forge components.

Scans all forge files (agents, commands, scripts, templates, hooks),
extracts references between them, and outputs:
  1. forge-registry.json — machine-readable dependency graph
  2. Mermaid diagram (printed to stdout)

Usage:
  python3 forge-registry.py [forge-dir]
  python3 forge-registry.py                  # defaults to ~/projects/forge
  python3 forge-registry.py --mermaid        # print mermaid diagram only
"""

import json
import os
import re
import sys
from pathlib import Path
from collections import defaultdict


def find_forge_dir():
    if len(sys.argv) > 1 and not sys.argv[1].startswith("--"):
        return Path(sys.argv[1])
    return Path.home() / "projects" / "forge"


def scan_agents(forge_dir):
    """Scan agent definition files."""
    agents = {}
    for pattern in ["agents/universal/*.md", "agents/stacks/*/*.md"]:
        for f in forge_dir.glob(pattern):
            agent_id = f.stem
            content = f.read_text(errors="ignore")
            # Extract frontmatter deps if present
            deps = extract_frontmatter_deps(content)
            # Auto-detect: scripts, commands, other agents referenced
            auto_deps = auto_detect_refs(content, "agent")
            agents[agent_id] = {
                "type": "agent",
                "path": str(f.relative_to(forge_dir)),
                "depends_on": merge_deps(deps.get("depends_on", {}), auto_deps),
                "depended_by": deps.get("depended_by", {}),
            }
    return agents


def scan_commands(forge_dir):
    """Scan command/skill definition files."""
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
            "depended_by": deps.get("depended_by", {}),
        }
    # Phase files
    for f in forge_dir.glob("commands/forge-phases/*.md"):
        cmd_id = f"phase:{f.stem}"
        content = f.read_text(errors="ignore")
        auto_deps = auto_detect_refs(content, "command")
        commands[cmd_id] = {
            "type": "phase",
            "path": str(f.relative_to(forge_dir)),
            "depends_on": auto_deps,
            "depended_by": {},
        }
    return commands


def scan_scripts(forge_dir):
    """Scan script files."""
    scripts = {}
    for ext in ["*.sh", "*.py"]:
        for f in forge_dir.glob(f"scripts/{ext}"):
            if f.name == "forge-registry.py" or f.name == "forge-lint.py":
                continue
            script_id = f.name
            content = f.read_text(errors="ignore")
            deps = extract_meta_deps(content)
            auto_deps = auto_detect_script_refs(content)
            scripts[script_id] = {
                "type": "script",
                "path": str(f.relative_to(forge_dir)),
                "depends_on": merge_deps(deps.get("depends_on", {}), auto_deps),
                "depended_by": deps.get("depended_by", {}),
            }
    return scripts


def scan_hooks(forge_dir):
    """Scan hooks from templates/hooks.json."""
    hooks = {}
    hooks_file = forge_dir / "templates" / "hooks.json"
    if not hooks_file.exists():
        return hooks
    data = json.loads(hooks_file.read_text())
    for event, hook_groups in data.get("hooks", {}).items():
        for i, group in enumerate(hook_groups):
            matcher = group.get("matcher", "(all)")
            hook_id = f"{event}:{matcher}" if matcher else event
            # Find script references in hook commands
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
                "depended_by": {},
            }
    return hooks


def scan_templates(forge_dir):
    """Scan template files."""
    templates = {}
    for f in forge_dir.glob("templates/*.md"):
        tmpl_id = f.name
        templates[tmpl_id] = {
            "type": "template",
            "path": str(f.relative_to(forge_dir)),
            "depends_on": {},
            "depended_by": {},
        }
    for f in forge_dir.glob("templates/rules/*.md"):
        tmpl_id = f"rules/{f.name}"
        templates[tmpl_id] = {
            "type": "template",
            "path": str(f.relative_to(forge_dir)),
            "depends_on": {},
            "depended_by": {},
        }
    return templates


def scan_rules(forge_dir):
    """Scan rule files."""
    rules = {}
    for f in forge_dir.glob("rules/*.md"):
        rule_id = f.name
        rules[rule_id] = {
            "type": "rule",
            "path": str(f.relative_to(forge_dir)),
            "depends_on": {},
            "depended_by": {},
        }
    return rules


def extract_frontmatter_deps(content):
    """Extract depends_on/depended_by from YAML frontmatter."""
    if not content.startswith("---"):
        return {}
    end = content.find("---", 3)
    if end == -1:
        return {}
    fm = content[3:end]
    deps = {}
    current_key = None
    current_sub = None
    for line in fm.split("\n"):
        line = line.strip()
        if line.startswith("depends_on:"):
            current_key = "depends_on"
            deps[current_key] = {}
        elif line.startswith("depended_by:"):
            current_key = "depended_by"
            deps[current_key] = {}
        elif current_key and line.startswith("scripts:"):
            val = line.split(":", 1)[1].strip().strip("[]")
            deps[current_key]["scripts"] = [v.strip() for v in val.split(",") if v.strip()]
        elif current_key and line.startswith("commands:"):
            val = line.split(":", 1)[1].strip().strip("[]")
            deps[current_key]["commands"] = [v.strip() for v in val.split(",") if v.strip()]
        elif current_key and line.startswith("agents:"):
            val = line.split(":", 1)[1].strip().strip("[]")
            deps[current_key]["agents"] = [v.strip() for v in val.split(",") if v.strip()]
        elif current_key and line.startswith("rules:"):
            val = line.split(":", 1)[1].strip().strip("[]")
            deps[current_key]["rules"] = [v.strip() for v in val.split(",") if v.strip()]
        elif not line or (not line.startswith("-") and ":" in line and current_key):
            current_key = None
    return deps


def extract_meta_deps(content):
    """Extract deps from bash meta-comments (# @forge-meta blocks)."""
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
            elif line.startswith("depended_by."):
                parts = line.split(":", 1)
                if len(parts) == 2:
                    key = parts[0].replace("depended_by.", "")
                    vals = [v.strip() for v in parts[1].split(",") if v.strip()]
                    deps.setdefault("depended_by", {})[key] = vals
    return deps


def auto_detect_refs(content, source_type):
    """Auto-detect references to other components in markdown content."""
    deps = defaultdict(list)
    # Agent references: @agent-name
    for m in re.findall(r"@([\w-]+(?:-agent|expert|architect|analyst|miner|curator|fixer|critic|enforcer|guide|review|writer))", content):
        deps["agents"].append(m)
    # Skill/command references: /command-name (but not file paths)
    for m in re.findall(r"(?:^|\s)/([\w-]+)(?:\s|$|\"|\))", content, re.MULTILINE):
        if m not in ("dev", "api", "etc", "bin", "usr", "home", "tmp", "var"):
            deps["commands"].append(m)
    # Script references
    for m in re.findall(r"(forge-[\w-]+\.sh)", content):
        deps["scripts"].append(m)
    # Deduplicate
    return {k: sorted(set(v)) for k, v in deps.items() if v}


def auto_detect_script_refs(content):
    """Auto-detect references in bash/python scripts."""
    deps = defaultdict(list)
    # Other scripts called via bash/source
    for m in re.findall(r"(?:bash|source|\.)\s+.*?(forge-[\w-]+\.sh)", content):
        deps["scripts"].append(m)
    for m in re.findall(r"(?:bash|source|\.)\s+.*?([\w-]+\.sh)", content):
        if m.startswith("forge-"):
            deps["scripts"].append(m)
    return {k: sorted(set(v)) for k, v in deps.items() if v}


def merge_deps(declared, auto):
    """Merge declared frontmatter deps with auto-detected deps."""
    result = dict(declared)
    for key, vals in auto.items():
        existing = set(result.get(key, []))
        existing.update(vals)
        result[key] = sorted(existing)
    return result


def build_edges(registry):
    """Build edge list from all components."""
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


def generate_mermaid(registry, edges):
    """Generate Mermaid diagram from registry."""
    lines = ["graph TD"]

    # Group by type for subgraphs
    type_map = {"hooks": "Hook", "scripts": "Script", "commands": "Command",
                "agents": "Agent", "rules": "Rule", "templates": "Template"}

    # Only show components that have connections
    connected = set()
    for e in edges:
        connected.add(e["from"])
        connected.add(e["to"])

    # Add nodes
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

    # Add edges
    for e in edges:
        from_id = e["from"].replace("/", "_").replace("-", "_").replace(":", "_").replace(".", "_")
        to_id = e["to"].replace("/", "_").replace("-", "_").replace(":", "_").replace(".", "_")
        lines.append(f"    {from_id} --> {to_id}")

    return "\n".join(lines)


def main():
    forge_dir = find_forge_dir()
    if not forge_dir.exists():
        print(f"Error: {forge_dir} not found", file=sys.stderr)
        sys.exit(1)

    # Scan all components
    registry = {
        "agents": scan_agents(forge_dir),
        "commands": scan_commands(forge_dir),
        "scripts": scan_scripts(forge_dir),
        "hooks": scan_hooks(forge_dir),
        "templates": scan_templates(forge_dir),
        "rules": scan_rules(forge_dir),
    }

    # Build edges
    edges = build_edges(registry)

    # Stats
    stats = {k: len(v) for k, v in registry.items()}
    stats["edges"] = len(edges)

    # Output
    output = {
        "version": "1.0",
        "forge_dir": str(forge_dir),
        "stats": stats,
        "components": registry,
        "edges": edges,
    }

    if "--mermaid" in sys.argv:
        print(generate_mermaid(registry, edges))
    else:
        # Write registry
        out_file = forge_dir / "forge-registry.json"
        out_file.write_text(json.dumps(output, indent=2))
        print(f"Registry: {out_file}")
        print(f"  Agents:    {stats['agents']}")
        print(f"  Commands:  {stats['commands']}")
        print(f"  Scripts:   {stats['scripts']}")
        print(f"  Hooks:     {stats['hooks']}")
        print(f"  Templates: {stats['templates']}")
        print(f"  Rules:     {stats['rules']}")
        print(f"  Edges:     {stats['edges']}")

        # Also print mermaid
        mermaid = generate_mermaid(registry, edges)
        mermaid_file = forge_dir / "docs" / "dependency-graph.md"
        mermaid_file.write_text(f"# Forge Dependency Graph\n\nAuto-generated by `forge-registry.py`.\n\n```mermaid\n{mermaid}\n```\n")
        print(f"  Diagram:   {mermaid_file}")


if __name__ == "__main__":
    main()
