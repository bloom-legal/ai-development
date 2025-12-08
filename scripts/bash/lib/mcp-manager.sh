#!/usr/bin/env bash
# MCP configuration management and syncing
# Handles MCP generation and syncing to global AI editor configs

# Note: This module expects SCRIPT_DIR, TEMPLATE_DIR, DEV_DIR to be set by the caller
# Load common functions if not already loaded
if [ -z "${COLOR_GREEN:-}" ]; then
    # shellcheck source=scripts/bash/lib/common.sh
    source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
fi

# ============================================================================
# MCP GENERATION AND SYNCING
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
