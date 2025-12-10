#!/usr/bin/env bash
# MCP Setup module - MCP configuration functions
# Note: This module expects common.sh to be sourced by the parent script

# Guard: Only source common.sh if not already loaded (use +x to check if SET)
if [ -z "${COLOR_GREEN+x}" ]; then
    _MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$_MODULE_DIR/common.sh"
fi

# Configure MCP
configure_mcp() {
    local MCP_TEMPLATE="$SCRIPT_DIR/template/.rulesync/mcp.json.template"
    local MCP_OUTPUT="$SCRIPT_DIR/template/.rulesync/mcp.json"
    local ENV_FILE="$SCRIPT_DIR/.env"

    # Create directories for tool configs (NOT dev folder - that's user's choice)
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

    # Generate config (ensure envsubst is available)
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

    # Sync rules to all projects (auto-initializes if needed)
    # This also syncs commands from .rulesync/commands/ to all projects and ~/.claude/commands/
    SKIP_PREFLIGHT=1 "$SCRIPT_DIR/sync-rules.sh" sync 2>/dev/null || warn "Rules sync had warnings"
}
