#!/usr/bin/env bash
# MCP configuration management, syncing, and setup
# Handles generation, syncing to global configs, and interactive configuration

# Guard: Only source common.sh if not already loaded
if [ -z "${COLOR_GREEN+x}" ]; then
    # shellcheck source=scripts/lib/common.sh
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
        sed -i '' 's/, *"mcp"//g; s/"mcp", *//g' "$config" 2>/dev/null || true
    fi
}

# ============================================================================
# INTERACTIVE MCP CONFIGURATION
# ============================================================================

# Configure MCP secrets interactively
configure_mcp() {
    local MCP_TEMPLATE="$SCRIPT_DIR/template/.rulesync/mcp.json.template"
    local MCP_OUTPUT="$SCRIPT_DIR/template/.rulesync/mcp.json"
    local ENV_FILE="$SCRIPT_DIR/.env"

    # Create directories for tool configs
    mkdir -p ~/.cursor 2>/dev/null || true
    mkdir -p ~/.claude/commands 2>/dev/null || true
    mkdir -p ~/Library/Application\ Support/Claude 2>/dev/null || true
    mkdir -p ~/Library/Application\ Support/Cursor/User/globalStorage/rooveterinaryinc.roo-code-nightly/settings 2>/dev/null || true

    # Load existing .env
    if [ -f "$ENV_FILE" ]; then
        set -a
        source "$ENV_FILE" 2>/dev/null || true
        set +a
    fi

    # Only prompt for secrets if not skipped
    if ! $SKIP_SECRETS; then
        echo ""
        echo -e "${COLOR_BLUE}Configure MCP server secrets (press Enter to skip, 's' to skip all):${COLOR_RESET}"
        echo ""

        # PostgreSQL
        current_pg="${POSTGRES_CONNECTION:-}"
        printf "PostgreSQL connection [user:pass@host:port/db]"
        [ -n "$current_pg" ] && printf " (current: %s...)" "${current_pg:0:20}"
        printf ": "
        read -r input_pg || input_pg=""
        if [[ "$input_pg" == "s" ]]; then
            SKIP_SECRETS=true
            log "Skipping remaining secrets"
        elif [ -n "$input_pg" ]; then
            POSTGRES_CONNECTION="$input_pg"
        fi

        if ! $SKIP_SECRETS; then
            # Portainer Server
            current_server="${PORTAINER_SERVER:-}"
            printf "Portainer server hostname"
            [ -n "$current_server" ] && printf " (current: %s)" "$current_server"
            printf ": "
            read -r input_server || input_server=""
            if [[ "$input_server" == "s" ]]; then
                SKIP_SECRETS=true
                log "Skipping remaining secrets"
            elif [ -n "$input_server" ]; then
                PORTAINER_SERVER="$input_server"
            fi
        fi

        if ! $SKIP_SECRETS; then
            # Portainer Token
            current_token="${PORTAINER_TOKEN:-}"
            printf "Portainer API token"
            [ -n "$current_token" ] && printf " (current: %s...)" "${current_token:0:10}"
            printf ": "
            read -r input_token || input_token=""
            [ -n "$input_token" ] && PORTAINER_TOKEN="$input_token"
        fi
    else
        log "Skipping secrets configuration (using existing or defaults)"
    fi

    # Save to .env
    cat > "$ENV_FILE" << EOF
# MCP Configuration - DO NOT COMMIT

# PostgreSQL connection string
POSTGRES_CONNECTION=${POSTGRES_CONNECTION:-}

# Portainer configuration
PORTAINER_SERVER=${PORTAINER_SERVER:-}
PORTAINER_TOKEN=${PORTAINER_TOKEN:-}
EOF

    export POSTGRES_CONNECTION PORTAINER_SERVER PORTAINER_TOKEN HOME

    # Generate config
    if command -v envsubst &>/dev/null; then
        envsubst < "$MCP_TEMPLATE" > "$MCP_OUTPUT"
    else
        # Fallback: manual substitution
        sed -e "s|\$POSTGRES_CONNECTION|${POSTGRES_CONNECTION:-}|g" \
            -e "s|\$PORTAINER_SERVER|${PORTAINER_SERVER:-}|g" \
            -e "s|\$PORTAINER_TOKEN|${PORTAINER_TOKEN:-}|g" \
            -e "s|\$HOME|$HOME|g" \
            "$MCP_TEMPLATE" > "$MCP_OUTPUT"
    fi

    # Sync MCP configs to global locations
    SKIP_PREFLIGHT=1 "$SCRIPT_DIR/sync-rules.sh" mcp 2>/dev/null || warn "MCP sync had warnings"

    # Sync rules to all projects
    SKIP_PREFLIGHT=1 "$SCRIPT_DIR/sync-rules.sh" sync 2>/dev/null || warn "Rules sync had warnings"
}
