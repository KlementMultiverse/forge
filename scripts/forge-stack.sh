#!/bin/bash
# Forge Stack Manager — create, list, and manage tech stack registries
#
# Usage:
#   forge-stack.sh list                          — show all registered stacks
#   forge-stack.sh create <name>                 — create new stack interactively
#   forge-stack.sh create <name> --auto          — auto-research and create stack
#   forge-stack.sh show <name>                   — show stack details
#   forge-stack.sh add-learning <name> <lesson>  — add a learning to a stack
#   forge-stack.sh compare <s1> <s2>             — compare two stacks

set -uo pipefail

STACKS_DIR="$HOME/.claude/stacks"
mkdir -p "$STACKS_DIR"

# ═══════════════════════════════════════════════
# LIST — show all registered stacks
# ═══════════════════════════════════════════════
cmd_list() {
    echo "=== Registered Tech Stacks ==="
    echo ""

    local count=0
    for stack_dir in "$STACKS_DIR"/*/; do
        [ -d "$stack_dir" ] || continue
        local name=$(basename "$stack_dir")
        [ "$name" = "README.md" ] && continue

        local rules="missing"
        local agents="missing"
        local learnings=0
        local scaffold="missing"

        [ -f "$stack_dir/rules.md" ] && rules="$(grep -c '^\d\|^[0-9]' "$stack_dir/rules.md" 2>/dev/null || echo 0) rules"
        [ -f "$stack_dir/agents.md" ] && agents="$(grep -c '|' "$stack_dir/agents.md" 2>/dev/null || echo 0) agents"
        [ -f "$stack_dir/learnings.md" ] && learnings=$(grep -c '^- ' "$stack_dir/learnings.md" 2>/dev/null || echo 0)
        [ -f "$stack_dir/scaffold.md" ] && scaffold="ready"

        printf "  %-15s rules:%-10s agents:%-10s learnings:%-4s scaffold:%s\n" \
            "$name" "$rules" "$agents" "$learnings" "$scaffold"
        count=$((count + 1))
    done

    echo ""
    echo "Total: $count stacks"
    echo ""
    echo "To create a new stack: forge-stack.sh create <name>"
}

# ═══════════════════════════════════════════════
# CREATE — new stack from template
# ═══════════════════════════════════════════════
cmd_create() {
    local name="${1:?Usage: forge-stack.sh create <name>}"
    local mode="${2:-interactive}"
    local stack_dir="$STACKS_DIR/$name"

    if [ -d "$stack_dir" ]; then
        echo "Stack '$name' already exists at $stack_dir"
        echo "Use 'forge-stack.sh show $name' to view it"
        return 0
    fi

    mkdir -p "$stack_dir"

    if [ "$mode" = "--auto" ]; then
        # Auto mode — create minimal templates, let the builder fill them
        echo "Creating stack '$name' with auto-research templates..."
        _create_auto "$name" "$stack_dir"
    else
        # Interactive mode — ask user
        echo "Creating stack '$name' interactively..."
        echo ""
        _create_interactive "$name" "$stack_dir"
    fi

    echo ""
    echo "Stack '$name' created at $stack_dir/"
    echo "Files:"
    ls -1 "$stack_dir/"
    echo ""
    echo "The next forge build with this stack will use these files."
    echo "Learnings will accumulate automatically after each /retro."
}

_create_auto() {
    local name="$1"
    local dir="$2"

    cat > "$dir/rules.md" << EOF
# ${name^} Stack Rules

<!-- AUTO-GENERATED — will be refined by @system-architect during first build -->
<!-- Run: forge-stack.sh create $name to fill interactively -->

## API
1. (to be filled during first build)

## Database
2. (to be filled during first build)

## Testing
3. (to be filled during first build)

## Infrastructure
4. (to be filled during first build)
EOF

    cat > "$dir/agents.md" << EOF
# ${name^} Agent Routing

<!-- AUTO-GENERATED — will be refined by @system-architect during first build -->

| Domain | Files | Agent | context7 Libraries |
|---|---|---|---|
| Core logic | \`src/**\` | @backend-architect | $name |
| Tests | \`tests/**\` | @quality-engineer | pytest |
| Docker & deploy | \`Dockerfile\`, \`docker-compose.yml\` | @devops-architect | -- |
| Frontend (if any) | \`static/**\`, \`templates/**\` | /sc:implement | -- |
EOF

    cat > "$dir/learnings.md" << EOF
# ${name^} Stack Learnings

<!-- Updated by /retro after each build. Each entry prevents a real past mistake. -->

<!-- No builds yet. Learnings will accumulate here. -->
EOF

    cat > "$dir/scaffold.md" << EOF
# ${name^} Scaffold Instructions

<!-- AUTO-GENERATED — refine this after first build -->

## Required Files
- Project config file (pyproject.toml / package.json / Cargo.toml / go.mod)
- Dockerfile — multi-stage build
- docker-compose.yml — DEVELOPMENT config with:
  - Volume mount for live reload
  - Development command (not production)
  - Database service with healthcheck
- .dockerignore
- .env.example
- .gitignore
- Entry point / main file
- Test configuration
EOF
}

_create_interactive() {
    local name="$1"
    local dir="$2"

    echo "I'll ask a few questions to set up the stack."
    echo ""

    read -p "  Language (e.g., Python, TypeScript, Go, Rust): " lang
    read -p "  Framework (e.g., FastAPI, Next.js, Axum): " framework
    read -p "  Package manager (e.g., uv, npm, cargo): " pkg_mgr
    read -p "  Test runner (e.g., pytest, jest, go test): " test_runner
    read -p "  Lint command (e.g., ruff check, eslint, clippy): " linter
    read -p "  Format command (e.g., black, prettier, rustfmt): " formatter
    read -p "  Dev server command (e.g., uvicorn --reload, next dev): " dev_cmd
    read -p "  Production server (e.g., gunicorn, next start): " prod_cmd
    read -p "  Config file (e.g., pyproject.toml, package.json): " config_file
    read -p "  Source directory (e.g., app/, src/, cmd/): " src_dir

    # Generate rules
    cat > "$dir/rules.md" << EOF
# ${name^} Stack Rules

## API
1. Use ${framework} idioms for ALL routes
2. Validate all input at boundaries

## Package Management
3. Use \`${pkg_mgr}\` — NEVER use alternative package managers

## Code Quality
4. Format with \`${formatter}\` — run after every code generation
5. Lint with \`${linter}\` — run after every code generation

## Testing
6. Run tests: \`docker compose exec web ${test_runner}\`
7. Tests MUST run inside Docker — not on host

## Infrastructure
8. Dev server: \`${dev_cmd}\` (in docker-compose.yml command)
9. Prod server: \`${prod_cmd}\` (in Dockerfile CMD)
EOF

    # Generate agents
    cat > "$dir/agents.md" << EOF
# ${name^} Agent Routing

| Domain | Files | Agent | context7 Libraries |
|---|---|---|---|
| Core logic | \`${src_dir}**\` | @backend-architect | ${framework} |
| API routes | \`${src_dir}**/routes*\`, \`${src_dir}**/api*\` | @backend-architect | ${framework} |
| Tests | \`tests/**\` | @quality-engineer | ${test_runner} |
| Docker & deploy | \`Dockerfile\`, \`docker-compose.yml\` | @devops-architect | -- |
| Frontend (if any) | \`static/**\`, \`templates/**\` | /sc:implement | -- |
| Config | \`${config_file}\`, config files | @backend-architect | ${framework} |
EOF

    # Generate learnings
    cat > "$dir/learnings.md" << EOF
# ${name^} Stack Learnings

<!-- Updated by /retro after each build. Each entry prevents a real past mistake. -->

<!-- No builds yet. Learnings will accumulate here. -->
EOF

    # Generate scaffold
    cat > "$dir/scaffold.md" << EOF
# ${name^} Scaffold Instructions

## Required Files
- \`${config_file}\` — all dependencies
- Entry point / main file in \`${src_dir}\`
- \`Dockerfile\` — multi-stage build (builder + runtime)
  - Builder: install deps with \`${pkg_mgr}\`
  - Runtime: run with \`${prod_cmd}\`
- \`docker-compose.yml\` — DEVELOPMENT config with:
  - Volume mount (\`.:/app\`) for live reload
  - \`command: ${dev_cmd}\`
  - Database service with healthcheck
- \`.dockerignore\`
- \`.env.example\` — all env vars with placeholder values
- \`.gitignore\`
- Test config / conftest

## Do NOT
- Run \`${pkg_mgr}\` install on host — Docker build handles deps
- Use \`${prod_cmd}\` in docker-compose (that's for production)
EOF
}

# ═══════════════════════════════════════════════
# SHOW — display stack details
# ═══════════════════════════════════════════════
cmd_show() {
    local name="${1:?Usage: forge-stack.sh show <name>}"
    local stack_dir="$STACKS_DIR/$name"

    if [ ! -d "$stack_dir" ]; then
        echo "Stack '$name' not found. Available stacks:"
        cmd_list
        return 1
    fi

    echo "=== Stack: $name ==="
    echo ""

    for file in rules.md agents.md scaffold.md learnings.md; do
        if [ -f "$stack_dir/$file" ]; then
            echo "--- $file ---"
            cat "$stack_dir/$file"
            echo ""
        fi
    done
}

# ═══════════════════════════════════════════════
# ADD-LEARNING — append a learning to a stack
# ═══════════════════════════════════════════════
cmd_add_learning() {
    local name="${1:?Usage: forge-stack.sh add-learning <stack> <lesson>}"
    shift
    local lesson="$*"
    local stack_dir="$STACKS_DIR/$name"
    local learnings="$stack_dir/learnings.md"

    if [ ! -d "$stack_dir" ]; then
        echo "Stack '$name' not found."
        return 1
    fi

    echo "- ${lesson}" >> "$learnings"
    echo "Added learning to $name stack."
}

# ═══════════════════════════════════════════════
# COMPARE — compare two stacks
# ═══════════════════════════════════════════════
cmd_compare() {
    local s1="${1:?Usage: forge-stack.sh compare <stack1> <stack2>}"
    local s2="${2:?Usage: forge-stack.sh compare <stack1> <stack2>}"

    echo "=== Comparing $s1 vs $s2 ==="
    echo ""

    for file in rules.md agents.md scaffold.md; do
        local f1="$STACKS_DIR/$s1/$file"
        local f2="$STACKS_DIR/$s2/$file"

        if [ -f "$f1" ] && [ -f "$f2" ]; then
            echo "--- $file ---"
            diff --color "$f1" "$f2" 2>/dev/null || diff "$f1" "$f2"
            echo ""
        fi
    done

    # Compare learnings count
    local l1=$(grep -c '^- ' "$STACKS_DIR/$s1/learnings.md" 2>/dev/null || echo 0)
    local l2=$(grep -c '^- ' "$STACKS_DIR/$s2/learnings.md" 2>/dev/null || echo 0)
    echo "Learnings: $s1=$l1, $s2=$l2"
}

# ═══════════════════════════════════════════════
# DISPATCH
# ═══════════════════════════════════════════════
case "${1:-help}" in
    list)           cmd_list ;;
    create)         shift; cmd_create "$@" ;;
    show)           shift; cmd_show "$@" ;;
    add-learning)   shift; cmd_add_learning "$@" ;;
    compare)        shift; cmd_compare "$@" ;;
    *)
        echo "Forge Stack Manager — tech stack registry"
        echo ""
        echo "  list                          Show all registered stacks"
        echo "  create <name>                 Create stack interactively"
        echo "  create <name> --auto          Create with auto-fill templates"
        echo "  show <name>                   Show stack details"
        echo "  add-learning <name> <lesson>  Add a learning"
        echo "  compare <stack1> <stack2>     Compare two stacks"
        echo ""
        echo "Stacks: $STACKS_DIR/"
        ;;
esac
