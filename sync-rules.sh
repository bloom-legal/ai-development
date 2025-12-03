#!/bin/bash
# Sync SpecKit + SuperClaude + Rulesync across all projects
# MCPs are synced to GLOBAL configs (Cursor, Claude Desktop, Roo Code)
# Rules and commands are synced to per-project configs
# Usage: ./sync-rules.sh [update|sync|init|mcp]
set -e

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/bash/lib/common.sh"

# Config
DEV="/Users/joachimbrindeau/Development"
TPL="$DEV/global/template"
SKIP="global|_archives|^\."

# Global MCP config locations
CURSOR_MCP="$HOME/.cursor/mcp.json"
CLAUDE_DESKTOP_MCP="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
ROO_MCP="$HOME/Library/Application Support/Cursor/User/globalStorage/rooveterinaryinc.roo-code-nightly/settings/mcp_settings.json"

# Generate MCP config from template
generate_mcp_config() {
    local template="$TPL/.rulesync/mcp.json.template"
    local output="$TPL/.rulesync/mcp.json"
    local env_file="$SCRIPT_DIR/.env"

    [ ! -f "$template" ] && { warn "MCP template not found at $template"; return 1; }

    # Load .env if it exists
    if [ -f "$env_file" ]; then
        set -a
        source "$env_file"
        set +a
    fi

    # Generate mcp.json from template
    envsubst < "$template" > "$output"
    log "Generated mcp.json from template"
}

# Sync MCPs to global configs
sync_global_mcps() {
    # Generate config from template first
    generate_mcp_config || return 1

    header "Syncing MCPs to global configs..."

    local mcp_source="$TPL/.rulesync/mcp.json"
    [ ! -f "$mcp_source" ] && { warn "No MCP source found at $mcp_source"; return 1; }

    # Read mcpServers from template
    local mcp_servers=$(cat "$mcp_source")

    # 1. Cursor global - direct copy (same format)
    log "  → Cursor: $CURSOR_MCP"
    cp "$mcp_source" "$CURSOR_MCP"

    # 2. Roo Code global - same format
    log "  → Roo Code: $ROO_MCP"
    mkdir -p "$(dirname "$ROO_MCP")"
    cp "$mcp_source" "$ROO_MCP"

    # 3. Claude Desktop - merge into existing config (preserves preferences)
    log "  → Claude Desktop: $CLAUDE_DESKTOP_MCP"
    if [ -f "$CLAUDE_DESKTOP_MCP" ]; then
        # Merge mcpServers into existing config
        local existing=$(cat "$CLAUDE_DESKTOP_MCP")
        local servers=$(cat "$mcp_source" | jq '.mcpServers')
        echo "$existing" | jq --argjson servers "$servers" '.mcpServers = $servers' > "$CLAUDE_DESKTOP_MCP"
    else
        # Create new config
        mkdir -p "$(dirname "$CLAUDE_DESKTOP_MCP")"
        cp "$mcp_source" "$CLAUDE_DESKTOP_MCP"
    fi

    log "MCPs synced to global configs ✓"
}

# Initialize SpecKit in a project
init_speckit() {
    local dir="$1"
    if [ ! -f "$dir/.specify/scripts/bash/common.sh" ]; then
        (cd "$dir" && specify init --here --ai claude --force --no-git 2>/dev/null) || true
    fi
}

# Copy template files to project (SpecKit + Rulesync - NO MCP)
copy_template() {
    local dir="$1"
    mkdir -p "$dir/.rulesync"/{rules,commands}
    mkdir -p "$dir/.claude/commands"

    # Initialize SpecKit properly
    init_speckit "$dir"

    # Copy SpecKit commands to .claude/commands (for Claude Code)
    [ -d "$TPL/.claude/commands" ] && cp -f "$TPL/.claude/commands/"*.md "$dir/.claude/commands/" 2>/dev/null || true

    # Copy rulesync configs (rules and commands only - NO MCP)
    cp -f "$TPL/.rulesync/rules/"*.md "$dir/.rulesync/rules/" 2>/dev/null || true
    cp -f "$TPL/.rulesync/commands/"*.md "$dir/.rulesync/commands/" 2>/dev/null || true
    [ -f "$TPL/.rulesync/.aiignore" ] && cp -f "$TPL/.rulesync/.aiignore" "$dir/.rulesync/"

    # Remove local MCP config if it exists (use global instead)
    rm -f "$dir/.rulesync/mcp.json" 2>/dev/null || true
}

# Create rulesync config (without MCP feature)
create_config() {
    cat > "$1/rulesync.jsonc" << 'EOF'
{
  "$schema": "https://raw.githubusercontent.com/dyoshikawa/rulesync/main/schema.json",
  "targets": ["cursor", "roo"],
  "features": ["rules", "ignore", "commands"],
  "simulateCommands": true,
  "delete": true
}
EOF
}

# Update rulesync config to remove MCP feature
update_config_remove_mcp() {
    local config="$1/rulesync.jsonc"
    [ ! -f "$config" ] && return

    # Remove "mcp" from features array using sed
    if grep -q '"mcp"' "$config" 2>/dev/null; then
        # Remove "mcp", from features or , "mcp"
        sed -i '' 's/, *"mcp"//g; s/"mcp", *//g' "$config" 2>/dev/null || true
    fi
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

# Remove local MCP configs from all projects
clean_local_mcps() {
    header "Removing local MCP configs from projects..."
    local count=0

    for dir in "$DEV"/*/; do
        name=$(basename "$dir")
        [[ "$name" =~ $SKIP ]] && continue

        # Remove .rulesync/mcp.json
        if [ -f "$dir/.rulesync/mcp.json" ]; then
            rm -f "$dir/.rulesync/mcp.json"
            log "  Removed: $name/.rulesync/mcp.json"
            ((count++))
        fi

        # Remove generated .cursor/mcp.json
        if [ -f "$dir/.cursor/mcp.json" ]; then
            rm -f "$dir/.cursor/mcp.json"
            log "  Removed: $name/.cursor/mcp.json"
        fi

        # Remove generated .roo/mcp.json
        if [ -f "$dir/.roo/mcp.json" ]; then
            rm -f "$dir/.roo/mcp.json"
            log "  Removed: $name/.roo/mcp.json"
        fi

        # Update rulesync.jsonc to remove mcp feature
        update_config_remove_mcp "$dir"
    done

    log "Cleaned $count projects"
}

# Pre-flight check and remediation
preflight_check() {
    local check_script="$SCRIPT_DIR/check.sh"

    if [ ! -f "$check_script" ]; then
        warn "check.sh not found, skipping pre-flight check"
        return 0
    fi

    header "Pre-flight check..."
    if ! "$check_script" 2>/dev/null; then
        warn "Issues detected, attempting remediation..."
        "$check_script" --fix 2>/dev/null || true

        # Verify fix worked
        if ! "$check_script" 2>/dev/null; then
            warn "Some issues remain, continuing anyway..."
        else
            log "Remediation successful"
        fi
    else
        log "All checks passed"
    fi
}

# Main
header "=== Sync: SpecKit + SuperClaude + Rulesync ==="

action="${1:-sync}"

# Run pre-flight check for sync operations (skip for mcp/clean/help to avoid loops)
# mcp is excluded because check.sh calls sync-rules.sh mcp to remediate
if [[ "$action" =~ ^(sync|generate|update)$ ]] && [[ -z "$SKIP_PREFLIGHT" ]]; then
    preflight_check
fi

if [[ "$action" == "update" ]]; then
    warn "Updating tools..."
    npm update -g rulesync 2>/dev/null || true
    update_superclaude
    echo ""
    action="sync"
fi

case "$action" in
    mcp)
        # Sync MCPs to global configs only
        sync_global_mcps
        ;;

    clean)
        # Remove local MCP configs
        clean_local_mcps
        ;;

    sync|generate)
        # Sync MCPs to global configs
        sync_global_mcps

        # Sync rules/commands to projects (no MCP)
        count=0
        for dir in "$DEV"/*/; do
            name=$(basename "$dir")
            [[ "$name" =~ $SKIP ]] && continue
            [ ! -f "$dir/rulesync.jsonc" ] && continue

            log "$name"
            copy_template "$dir"
            update_config_remove_mcp "$dir"
            (cd "$dir" && npx rulesync generate 2>/dev/null) || true
            ((count++))
        done

        header "=== Done! $count projects synced ==="
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

        header "=== Done! $count projects initialized ==="
        ;;

    *)
        echo "Usage: $0 [update|sync|init|mcp|clean]"
        echo ""
        echo "Commands:"
        echo "  sync    - Sync MCPs to global + rules/commands to projects (default)"
        echo "  mcp     - Sync MCPs to global configs only"
        echo "  clean   - Remove local MCP configs from all projects"
        echo "  init    - Initialize new projects with rulesync"
        echo "  update  - Update tools and sync"
        exit 1
        ;;
esac
