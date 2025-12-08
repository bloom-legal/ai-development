#!/bin/bash
# Sync modular building blocks across all projects
# MCPs are synced to GLOBAL configs (Cursor, Claude Code CLI, Roo Code)
# Rules and commands are synced to per-project configs
# Usage: ./sync-rules.sh [update|sync|init|mcp]
set -e

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/bash/lib/common.sh
source "$SCRIPT_DIR/scripts/bash/lib/common.sh"

# Config - derive paths from script location
DEV_DIR="$(get_dev_folder)"
TEMPLATE_DIR="$SCRIPT_DIR/template"
# SYNC_SKIP_PATTERN is defined in common.sh

# Paths defined in common.sh: CURSOR_MCP, CLAUDE_CODE_MCP, ROO_MCP, CLAUDE_GLOBAL_MD

# ============================================================================
# BUILDING BLOCK CONFIGURATION
# ============================================================================
# Enable/disable independent building blocks
# Set to false to exclude a building block from sync operations

ENABLE_DIET103=true       # diet103 infrastructure (hooks + skills + agents)
ENABLE_SPECKIT=true       # SpecKit templates and infrastructure
ENABLE_RULESYNC=true      # Rulesync rules and configuration

# ============================================================================
# MODULAR SYNC FUNCTIONS - Independent Building Blocks
# ============================================================================

# Sync diet103 infrastructure
# Includes hooks, skills, and diet103-specific configurations
sync_diet103() {
    [[ "$ENABLE_DIET103" != "true" ]] && return 0

    local dir="$1"

    # Sync hooks (auto-activation system)
    if [ -d "$TEMPLATE_DIR/.claude/hooks" ]; then
        mkdir -p "$dir/.claude/hooks"
        cp -rf "$TEMPLATE_DIR/.claude/hooks/"* "$dir/.claude/hooks/" 2>/dev/null || true
        chmod +x "$dir/.claude/hooks/"*.sh 2>/dev/null || true
        # Install hook dependencies quietly
        (cd "$dir/.claude/hooks" && npm install --silent 2>/dev/null) || true
    fi

    # Sync skills (production-tested patterns)
    if [ -d "$TEMPLATE_DIR/.claude/skills" ]; then
        mkdir -p "$dir/.claude/skills"
        cp -rf "$TEMPLATE_DIR/.claude/skills/"* "$dir/.claude/skills/" 2>/dev/null || true
    fi

    # Sync agents (specialized helpers)
    if [ -d "$TEMPLATE_DIR/.claude/agents" ]; then
        mkdir -p "$dir/.claude/agents"
        cp -rf "$TEMPLATE_DIR/.claude/agents/"* "$dir/.claude/agents/" 2>/dev/null || true
    fi

    # Sync skill-rules.json (activation configuration)
    [ -f "$TEMPLATE_DIR/.claude/skill-rules.json" ] && \
        cp -f "$TEMPLATE_DIR/.claude/skill-rules.json" "$dir/.claude/"

    # Sync settings.json (hooks configuration)
    [ -f "$TEMPLATE_DIR/.claude/settings.json" ] && \
        cp -f "$TEMPLATE_DIR/.claude/settings.json" "$dir/.claude/"
}

# Sync SpecKit templates and infrastructure
# Initializes and syncs SpecKit .specify directory
sync_speckit() {
    [[ "$ENABLE_SPECKIT" != "true" ]] && return 0

    local dir="$1"

    # Initialize SpecKit if not already initialized
    if [ ! -f "$dir/.specify/scripts/bash/common.sh" ]; then
        log "  Initializing SpecKit..."
        (cd "$dir" && specify init --here --ai claude --force --no-git 2>/dev/null) || true
    fi
}

# Sync all commands from .rulesync/commands/ to project
# Single source of truth: template/.rulesync/commands/
sync_commands() {
    local dir="$1"
    local count=0

    # Ensure directories exist
    mkdir -p "$dir/.rulesync/commands"
    mkdir -p "$dir/.claude/commands"

    # Copy ALL commands from .rulesync/commands/ (dynamic discovery)
    if [ -d "$TEMPLATE_DIR/.rulesync/commands" ]; then
        for cmd in "$TEMPLATE_DIR/.rulesync/commands/"*.md; do
            [ -f "$cmd" ] || continue
            local name
            name=$(basename "$cmd")

            # Copy to rulesync for Cursor/Roo
            cp -f "$cmd" "$dir/.rulesync/commands/" 2>/dev/null || true

            # Copy to .claude for Claude Code
            cp -f "$cmd" "$dir/.claude/commands/" 2>/dev/null || true

            ((count++))
        done
    fi

    [ $count -gt 0 ] && log "    ✓ $count commands synced"
}

# Sync rulesync rules and base configuration
# Rules are shared prompts/context loaded by AI editors
sync_rulesync() {
    [[ "$ENABLE_RULESYNC" != "true" ]] && return 0

    local dir="$1"

    # Copy rulesync rules
    if [ -d "$TEMPLATE_DIR/.rulesync/rules" ]; then
        cp -f "$TEMPLATE_DIR/.rulesync/rules/"*.md "$dir/.rulesync/rules/" 2>/dev/null || true
    fi

    # Copy .aiignore
    if [ -f "$TEMPLATE_DIR/.rulesync/.aiignore" ]; then
        cp -f "$TEMPLATE_DIR/.rulesync/.aiignore" "$dir/.rulesync/"
    fi
}

# ============================================================================
# CORE FUNCTIONS
# ============================================================================

# Generate MCP config from template
generate_mcp_config() {
    local template="$TEMPLATE_DIR/.rulesync/mcp.json.template"
    local output="$TEMPLATE_DIR/.rulesync/mcp.json"
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

    local mcp_source="$TEMPLATE_DIR/.rulesync/mcp.json"
    [ ! -f "$mcp_source" ] && { warn "No MCP source found at $mcp_source"; return 1; }

    # 1. Cursor global - direct copy (same format)
    log "  → Cursor: $CURSOR_MCP"
    cp "$mcp_source" "$CURSOR_MCP"

    # 2. Roo Code global - same format
    log "  → Roo Code: $ROO_MCP"
    mkdir -p "$(dirname "$ROO_MCP")"
    cp "$mcp_source" "$ROO_MCP"

    # 3. Claude Code CLI - merge mcpServers into existing user state file
    log "  → Claude Code CLI: $CLAUDE_CODE_MCP"
    if [ -f "$CLAUDE_CODE_MCP" ]; then
        # Merge mcpServers into existing config (preserves user state)
        local existing
        existing=$(cat "$CLAUDE_CODE_MCP")
        local servers
        servers=$(jq '.mcpServers' "$mcp_source")
        echo "$existing" | jq --argjson servers "$servers" '.mcpServers = $servers' > "$CLAUDE_CODE_MCP"
    else
        # Create new config file with only mcpServers
        mkdir -p "$(dirname "$CLAUDE_CODE_MCP")"
        cp "$mcp_source" "$CLAUDE_CODE_MCP"
    fi

    log "MCPs synced to global configs ✓"
}

# Sync global CLAUDE.md (principles) to Claude Code global config
sync_global_claude_md() {
    local source="$TEMPLATE_DIR/CLAUDE.md"
    # CLAUDE_GLOBAL_MD is defined in common.sh

    [ ! -f "$source" ] && { warn "No CLAUDE.md found at $source"; return 1; }

    header "Syncing global CLAUDE.md..."
    log "  → Claude Code: $CLAUDE_GLOBAL_MD"
    mkdir -p "$(dirname "$CLAUDE_GLOBAL_MD")"
    cp "$source" "$CLAUDE_GLOBAL_MD"
    log "Global CLAUDE.md synced ✓"
}

# Copy template files to project using modular sync functions
copy_template() {
    local dir="$1"

    # Create base directory structure
    mkdir -p "$dir/.rulesync"/{rules,commands}
    mkdir -p "$dir/.claude/commands"

    # Sync each building block independently
    sync_speckit "$dir"        # SpecKit templates and infrastructure
    sync_commands "$dir"       # All commands (dynamic discovery)
    sync_rulesync "$dir"       # Rulesync rules and configuration
    sync_diet103 "$dir"        # diet103 infrastructure (hooks, skills, agents)

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

# Remove local MCP configs from all projects
clean_local_mcps() {
    header "Removing local MCP configs from projects..."
    local count=0

    for dir in "$DEV_DIR"/*/; do
        name=$(basename "$dir")
        [[ "$name" =~ $SYNC_SKIP_PATTERN ]] && continue

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

# ============================================================================
# MAIN
# ============================================================================

# Display enabled building blocks
display_building_blocks() {
    header "Building Blocks Configuration:"
    log "  diet103:   $([ "$ENABLE_DIET103" = "true" ] && echo "ENABLED" || echo "DISABLED")"
    log "  SpecKit:   $([ "$ENABLE_SPECKIT" = "true" ] && echo "ENABLED" || echo "DISABLED")"
    log "  Rulesync:  $([ "$ENABLE_RULESYNC" = "true" ] && echo "ENABLED" || echo "DISABLED")"
    log "  Commands:  dynamic (from .rulesync/commands/)"
    echo ""
}

header "=== Sync: Modular Building Blocks ==="
display_building_blocks

action="${1:-sync}"

# Run pre-flight check for sync operations (skip for mcp/clean/help to avoid loops)
# mcp is excluded because check.sh calls sync-rules.sh mcp to remediate
if [[ "$action" =~ ^(sync|generate|update)$ ]] && [[ -z "$SKIP_PATTERN_PREFLIGHT" ]]; then
    preflight_check
fi

if [[ "$action" == "update" ]]; then
    warn "Updating tools..."
    npm update -g rulesync 2>/dev/null || true
    echo ""
    action="sync"
fi

case "$action" in
    mcp)
        # Sync MCPs and CLAUDE.md to global configs only
        sync_global_mcps
        sync_global_claude_md
        ;;

    clean)
        # Remove local MCP configs
        clean_local_mcps
        ;;

    sync|generate)
        # Sync MCPs and CLAUDE.md to global configs
        sync_global_mcps
        sync_global_claude_md

        # Auto-init + sync rules/commands to ALL projects
        count=0
        init_count=0
        for dir in "$DEV_DIR"/*/; do
            name=$(basename "$dir")
            [[ "$name" =~ $SYNC_SKIP_PATTERN ]] && continue

            # Auto-initialize if no rulesync.jsonc exists
            if [ ! -f "$dir/rulesync.jsonc" ]; then
                log "Init: $name"
                copy_template "$dir"
                create_config "$dir"
                ((init_count++))
            fi

            log "$name"
            copy_template "$dir"
            update_config_remove_mcp "$dir"
            (cd "$dir" && npx rulesync generate 2>/dev/null) || true
            ((count++))
        done

        if [ $init_count -gt 0 ]; then
            header "=== Done! $count projects synced ($init_count newly initialized) ==="
        else
            header "=== Done! $count projects synced ==="
        fi
        ;;

    init)
        count=0
        for dir in "$DEV_DIR"/*/; do
            name=$(basename "$dir")
            [[ "$name" =~ $SYNC_SKIP_PATTERN ]] && continue
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
        echo "  sync    - Sync MCPs + CLAUDE.md to global + rules/commands to projects (default)"
        echo "  mcp     - Sync MCPs + CLAUDE.md to global configs only"
        echo "  clean   - Remove local MCP configs from all projects"
        echo "  init    - Initialize new projects with rulesync"
        echo "  update  - Update tools and sync"
        echo ""
        echo "Building Blocks:"
        echo "  Edit sync-rules.sh to enable/disable:"
        echo "  - ENABLE_DIET103   : Hooks, skills, agents"
        echo "  - ENABLE_SPECKIT   : SpecKit templates"
        echo "  - ENABLE_RULESYNC  : Rules and .aiignore"
        echo ""
        echo "  Commands are auto-discovered from template/.rulesync/commands/"
        exit 1
        ;;
esac
