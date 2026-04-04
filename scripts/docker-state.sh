#!/bin/bash
# Docker State Capture — Global, project-agnostic
# Provides Docker awareness to all forge-managed projects
#
# Usage:
#   docker-state.sh              — capture + display state
#   docker-state.sh --json       — output JSON only
#   docker-state.sh --check      — health check, exit 0 if healthy
#   docker-state.sh --cleanup    — remove orphan volumes/networks

set -euo pipefail

# Auto-detect project root
find_project_root() {
    local dir="${1:-$PWD}"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/CLAUDE.md" ] || [ -d "$dir/.git" ]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    echo "$PWD"
}

PROJECT_ROOT="${PROJECT_ROOT:-$(find_project_root)}"
STATE_FILE="$PROJECT_ROOT/docs/docker-state.json"

# Check if any compose file exists
has_compose() {
    [ -f "$PROJECT_ROOT/docker-compose.yml" ] || \
    [ -f "$PROJECT_ROOT/docker-compose.yaml" ] || \
    [ -f "$PROJECT_ROOT/compose.yml" ]
}

cmd_capture() {
    if ! has_compose; then
        echo "No docker-compose file found in $PROJECT_ROOT — skipping"
        exit 0
    fi

    mkdir -p "$(dirname "$STATE_FILE")"

    local project_name
    project_name=$(basename "$PROJECT_ROOT")

    python3 << PYEOF
import json, subprocess, datetime, sys

def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True, cwd="$PROJECT_ROOT")
    return r.stdout.strip()

project = "$project_name"
state = {
    "captured_at": datetime.datetime.now(datetime.UTC).isoformat(),
    "project": project,
    "project_root": "$PROJECT_ROOT",
    "containers": [],
    "volumes": [],
    "networks": [],
    "images": [],
    "project_services": {"expected": [], "running": [], "healthy": [], "missing": []}
}

# Get expected services from compose
svc_out = run(["docker", "compose", "config", "--services"])
state["project_services"]["expected"] = [s for s in svc_out.split("\n") if s.strip()]

# Containers
ps_out = run(["docker", "ps", "-a", "--format", "{{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}"])
for line in ps_out.split("\n"):
    if line.strip():
        parts = line.split("\t")
        if len(parts) >= 4:
            state["containers"].append({
                "id": parts[0][:12], "name": parts[1],
                "status": parts[2], "image": parts[3],
                "ports": parts[4] if len(parts) > 4 else "",
                "is_project": project.replace("-", "_").replace(" ", "_") in parts[1].replace("-", "_")
            })

# Volumes
vol_out = run(["docker", "volume", "ls", "--format", "{{.Name}}"])
for v in vol_out.split("\n"):
    if v.strip():
        state["volumes"].append({
            "name": v.strip(),
            "is_project": project.replace("-", "_") in v.replace("-", "_"),
            "is_orphan": len(v) == 64 and v.isalnum()
        })

# Networks
net_out = run(["docker", "network", "ls", "--format", "{{.Name}}\t{{.Driver}}"])
for line in net_out.split("\n"):
    if line.strip():
        parts = line.split("\t")
        name = parts[0]
        if name not in ("bridge", "host", "none"):
            state["networks"].append({
                "name": name,
                "driver": parts[1] if len(parts) > 1 else "",
                "is_project": project.replace("-", "_") in name.replace("-", "_")
            })

# Images
img_out = run(["docker", "images", "--format", "{{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"])
for line in img_out.split("\n"):
    if line.strip():
        parts = line.split("\t")
        if len(parts) >= 3:
            state["images"].append({
                "repo": parts[0], "tag": parts[1] if len(parts) > 1 else "",
                "id": parts[2][:12] if len(parts) > 2 else "",
                "size": parts[3] if len(parts) > 3 else ""
            })

# Check project services
for svc in state["project_services"]["expected"]:
    found = False
    for c in state["containers"]:
        if c["is_project"] and svc in c["name"]:
            found = True
            state["project_services"]["running"].append(svc)
            if "healthy" in c["status"].lower() or ("up" in c["status"].lower() and "unhealthy" not in c["status"].lower()):
                state["project_services"]["healthy"].append(svc)
            break
    if not found:
        state["project_services"]["missing"].append(svc)

state["all_healthy"] = (
    len(state["project_services"]["healthy"]) == len(state["project_services"]["expected"])
    and len(state["project_services"]["expected"]) > 0
)

with open("$STATE_FILE", "w") as f:
    json.dump(state, f, indent=2)

if "--json" in sys.argv:
    print(json.dumps(state, indent=2))
else:
    print(f"Docker State — {project}")
    print()
    for svc in state["project_services"]["expected"]:
        if svc in state["project_services"]["healthy"]:
            print(f"  {svc}: HEALTHY")
        elif svc in state["project_services"]["running"]:
            print(f"  {svc}: RUNNING (not healthy)")
        else:
            print(f"  {svc}: NOT RUNNING")
    print()
    orphan_vol = sum(1 for v in state["volumes"] if v["is_orphan"])
    stale_net = sum(1 for n in state["networks"] if not n["is_project"])
    print(f"Containers: {len(state['containers'])} ({sum(1 for c in state['containers'] if c['is_project'])} project)")
    print(f"Volumes:    {len(state['volumes'])} ({orphan_vol} orphan)")
    print(f"Networks:   {len(state['networks'])} ({stale_net} stale)")
    print(f"Images:     {len(state['images'])}")
    print()
    if state["all_healthy"]:
        print("STATUS: ALL HEALTHY — skip Docker setup")
    elif state["project_services"]["missing"]:
        print(f"STATUS: MISSING services: {state['project_services']['missing']}")
        print("ACTION: docker compose up -d")
    else:
        print("STATUS: Some services unhealthy — check logs")
PYEOF
}

cmd_check() {
    if ! has_compose; then
        echo "NO_COMPOSE"
        exit 0
    fi
    cmd_capture --json > /dev/null 2>&1
    python3 -c "
import json, sys
with open('$STATE_FILE') as f:
    state = json.load(f)
if state.get('all_healthy'):
    print('DOCKER_HEALTHY')
    sys.exit(0)
else:
    missing = state.get('project_services', {}).get('missing', [])
    print(f'DOCKER_UNHEALTHY: missing={missing}')
    sys.exit(1)
"
}

cmd_cleanup() {
    echo "=== Docker Cleanup ==="

    orphans=$(docker volume ls -qf dangling=true 2>/dev/null || true)
    if [ -n "$orphans" ]; then
        echo "Removing orphan volumes..."
        echo "$orphans" | while read -r vol; do
            if docker volume rm "$vol" 2>/dev/null; then
                echo "  Removed $vol"
            else
                echo "  Skipped $vol (in use)"
            fi
        done
    else
        echo "No orphan volumes"
    fi

    local project_net
    project_net=$(basename "$PROJECT_ROOT" | tr '-' '_')
    docker network ls --format '{{.Name}}' | while read -r net; do
        if [ "$net" != "bridge" ] && [ "$net" != "host" ] && [ "$net" != "none" ] && \
           ! echo "$net" | grep -q "$project_net"; then
            if docker network rm "$net" 2>/dev/null; then
                echo "Removed network: $net"
            fi
        fi
    done

    echo "Done"
}

case "${1:-}" in
    --json)    cmd_capture --json ;;
    --check)   cmd_check ;;
    --cleanup) cmd_cleanup ;;
    *)         cmd_capture ;;
esac
