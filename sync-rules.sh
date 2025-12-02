#!/bin/bash
# Sync SpecKit + SuperClaude + Rulesync across all projects
# Usage: ./sync-rules.sh [update|sync|init]
set -e

# Config
DEV="/Users/joachimbrindeau/Development"
TPL="$DEV/global/template"
SKIP="global|_archives|^\."

# Colors
G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m' C='\033[0;36m' N='\033[0m'

log() { echo -e "${G}$1${N}"; }
warn() { echo -e "${Y}$1${N}"; }
header() { echo -e "${B}$1${N}"; }

# Initialize SpecKit in a project
init_speckit() {
    local dir="$1"
    if [ ! -f "$dir/.specify/scripts/bash/common.sh" ]; then
        (cd "$dir" && specify init --here --ai claude --force --no-git 2>/dev/null) || true
    fi
}

# Copy template files to project (SpecKit + Rulesync)
copy_template() {
    local dir="$1"
    mkdir -p "$dir/.rulesync"/{rules,commands}
    mkdir -p "$dir/.claude/commands"

    # Initialize SpecKit properly
    init_speckit "$dir"

    # Copy SpecKit commands to .claude/commands (for Claude Code)
    [ -d "$TPL/.claude/commands" ] && cp -f "$TPL/.claude/commands/"*.md "$dir/.claude/commands/" 2>/dev/null || true

    # Copy rulesync configs
    cp -f "$TPL/.rulesync/rules/"*.md "$dir/.rulesync/rules/" 2>/dev/null || true
    cp -f "$TPL/.rulesync/commands/"*.md "$dir/.rulesync/commands/" 2>/dev/null || true
    [ -f "$TPL/.rulesync/mcp.json" ] && cp -f "$TPL/.rulesync/mcp.json" "$dir/.rulesync/"
    [ -f "$TPL/.rulesync/.aiignore" ] && cp -f "$TPL/.rulesync/.aiignore" "$dir/.rulesync/"
}

# Create rulesync config
create_config() {
    cat > "$1/rulesync.jsonc" << 'EOF'
{
  "$schema": "https://raw.githubusercontent.com/dyoshikawa/rulesync/main/schema.json",
  "targets": ["cursor", "roo"],
  "features": ["rules", "ignore", "mcp", "commands"],
  "simulateCommands": true,
  "delete": true
}
EOF
}

# Update SuperClaude commands from Claude Code
update_superclaude() {
    [ ! -d "$HOME/.claude/commands/sc" ] && return

    log "Syncing SuperClaude commands..."
    mkdir -p "$TPL/.rulesync/commands"

    for cmd in "$HOME/.claude/commands/sc/"*.md; do
        [ -f "$cmd" ] || continue
        local name=$(basename "$cmd")
        [[ "$name" == "README.md" ]] && continue

        if grep -q "^name:" "$cmd" 2>/dev/null; then
            local desc=$(grep "^description:" "$cmd" | sed 's/^description: *//' | tr -d '"')
            sed '1,/^---$/d' "$cmd" | sed '1,/^---$/d' | {
                echo -e "---\ndescription: \"$desc\"\ntargets: [\"*\"]\n---"
                cat
            } > "$TPL/.rulesync/commands/$name"
        else
            cp -f "$cmd" "$TPL/.rulesync/commands/"
        fi
    done
    echo "  $(ls "$HOME/.claude/commands/sc/"*.md 2>/dev/null | wc -l | tr -d ' ') commands"
}

# Main
header "=== Sync: SpecKit + SuperClaude + Rulesync ==="

action="${1:-sync}"

if [[ "$action" == "update" ]]; then
    warn "Updating tools..."
    npm update -g rulesync 2>/dev/null || true
    update_superclaude
    echo ""
    action="sync"
fi

case "$action" in
    sync|generate)
        count=0
        for dir in "$DEV"/*/; do
            name=$(basename "$dir")
            [[ "$name" =~ $SKIP ]] && continue
            [ ! -f "$dir/rulesync.jsonc" ] && continue

            log "$name"
            copy_template "$dir"
            (cd "$dir" && npx rulesync generate 2>/dev/null) || true
            ((count++))
        done
        ;;

    init)
        count=0
        for dir in "$DEV"/*/; do
            name=$(basename "$dir")
            [[ "$name" =~ $SKIP ]] && continue
            [ -f "$dir/rulesync.jsonc" ] && continue

            log "Init: $name"
            copy_template "$dir"
            create_config "$dir"
            ((count++))
        done
        ;;

    *)
        echo "Usage: $0 [update|sync|init]"
        exit 1
        ;;
esac

header "=== Done! $count projects ==="
