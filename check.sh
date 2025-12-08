#!/bin/bash
# Check and remediate AI development environment
# Usage: ./check.sh [--fix]
set -e

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/bash/lib/common.sh"

# Additional logging functions specific to check.sh
ok() { echo -e "${COLOR_GREEN}✓${COLOR_RESET} $1"; }
fail() { echo -e "${COLOR_RED}✗${COLOR_RESET} $1"; }
TEMPLATE_DIR="$SCRIPT_DIR/template"
FIX_MODE="${1:-}"
ERROR_COUNT=0

# MCP paths are defined in common.sh: CURSOR_MCP, CLAUDE_DESKTOP_MCP, ROO_MCP

remediate() {
    if [[ "$FIX_MODE" == "--fix" ]]; then
        return 0
    else
        return 1
    fi
}

header "Prerequisites"

# Homebrew
if command -v brew &>/dev/null; then
    ok "Homebrew installed"
else
    fail "Homebrew not installed"
    ((ERROR_COUNT++))
    if remediate; then
        warn "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

# Node.js
if command -v node &>/dev/null; then
    ok "Node.js installed ($(node --version))"
else
    fail "Node.js not installed"
    ((ERROR_COUNT++))
    if remediate; then
        warn "Installing Node.js..."
        brew install node
    fi
fi

# jq
if command -v jq &>/dev/null; then
    ok "jq installed"
else
    fail "jq not installed"
    ((ERROR_COUNT++))
    if remediate; then
        warn "Installing jq..."
        brew install jq
    fi
fi

# uvx (for Python MCP servers)
if command -v uvx &>/dev/null; then
    ok "uvx installed"
else
    fail "uvx not installed"
    ((ERROR_COUNT++))
    if remediate; then
        warn "Installing uv..."
        brew install uv
    fi
fi

header "Applications"

# VS Code
if [ -d "/Applications/Visual Studio Code.app" ]; then
    ok "VS Code installed"
else
    fail "VS Code not installed"
    ((ERROR_COUNT++))
    if remediate; then
        warn "Installing VS Code..."
        brew install --cask visual-studio-code
    fi
fi

# Cursor
if [ -d "/Applications/Cursor.app" ]; then
    ok "Cursor installed"
else
    fail "Cursor not installed"
    ((ERROR_COUNT++))
    if remediate; then
        warn "Installing Cursor..."
        brew install --cask cursor
    fi
fi

# Claude Code CLI
if command -v claude &>/dev/null; then
    ok "Claude Code CLI installed"
else
    fail "Claude Code CLI not installed"
    ((ERROR_COUNT++))
    if remediate; then
        warn "Installing Claude Code..."
        npm install -g @anthropic-ai/claude-code
    fi
fi

header "Directories"

# Check and create directories
for dir in \
    "$HOME/.cursor" \
    "$HOME/.claude/commands" \
    "$HOME/Library/Application Support/Claude" \
    "$HOME/Library/Application Support/Cursor/User/globalStorage/rooveterinaryinc.roo-code-nightly/settings"
do
    if [ -d "$dir" ]; then
        ok "Directory exists: $(basename "$dir")"
    else
        fail "Directory missing: $dir"
        ((ERROR_COUNT++))
        if remediate; then
            warn "Creating directory..."
            mkdir -p "$dir"
        fi
    fi
done

header "MCP Template"

# Check template exists
if [ -f "$TEMPLATE_DIR/.rulesync/mcp.json.template" ]; then
    ok "MCP template exists"
    MCP_COUNT=$(jq '.mcpServers | keys | length' "$TEMPLATE_DIR/.rulesync/mcp.json.template" 2>/dev/null || echo 0)
    ok "Template has $MCP_COUNT MCP servers"
else
    fail "MCP template not found at $TEMPLATE_DIR/.rulesync/mcp.json.template"
    ((ERROR_COUNT++))
fi

# Check .env file
if [ -f "$SCRIPT_DIR/.env" ]; then
    ok ".env file exists (secrets configured)"
else
    warn ".env file missing - copy .env.example and add your secrets"
fi

header "Global MCP Configs"

check_mcp_config() {
    local name="$1"
    local path="$2"

    if [ -f "$path" ]; then
        if jq -e '.mcpServers' "$path" &>/dev/null; then
            local count
            count=$(jq '.mcpServers | keys | length' "$path" 2>/dev/null || echo 0)
            if [ "$count" -gt 0 ]; then
                ok "$name: $count MCP servers"
            else
                fail "$name: empty mcpServers"
                ((ERROR_COUNT++))
                if remediate; then
                    warn "Syncing MCPs..."
                    SKIP_PREFLIGHT=1 "$SCRIPT_DIR/sync-rules.sh" mcp
                fi
            fi
        else
            fail "$name: invalid format (no mcpServers key)"
            ((ERROR_COUNT++))
            if remediate; then
                warn "Syncing MCPs..."
                SKIP_PREFLIGHT=1 "$SCRIPT_DIR/sync-rules.sh" mcp
            fi
        fi
    else
        fail "$name: config file missing"
        ((ERROR_COUNT++))
        if remediate; then
            warn "Creating config..."
            mkdir -p "$(dirname "$path")"
            SKIP_PREFLIGHT=1 "$SCRIPT_DIR/sync-rules.sh" mcp
        fi
    fi
}

check_mcp_config "Cursor" "$CURSOR_MCP"
check_mcp_config "Roo Code" "$ROO_MCP"
check_mcp_config "Claude Code CLI" "$CLAUDE_CODE_MCP"

header "MCP Server Availability"

# Check if common MCP servers can be resolved
check_mcp_server() {
    local name="$1"
    local cmd="$2"

    if command -v "$cmd" &>/dev/null || which "$cmd" &>/dev/null 2>&1; then
        ok "$name ($cmd)"
    else
        # For npx commands, just check npx exists
        if [[ "$cmd" == "npx" ]] && command -v npx &>/dev/null; then
            ok "$name (via npx)"
        elif [[ "$cmd" == "uvx" ]] && command -v uvx &>/dev/null; then
            ok "$name (via uvx)"
        else
            warn "$name: $cmd not in PATH (may work via npx/uvx)"
        fi
    fi
}

check_mcp_server "context7" "npx"
check_mcp_server "docker-mcp" "uvx"
check_mcp_server "puppeteer" "npx"

# Check portainer-mcp binary (optional)
if [ -f "$HOME/.local/bin/portainer-mcp" ]; then
    ok "portainer-mcp binary exists"
else
    warn "portainer-mcp binary not found (optional - install if using Portainer)"
fi

header "Development Projects"

DEV_DIR="$(get_dev_folder)"
# SYNC_SKIP_PATTERN is defined in common.sh
PROJECT_COUNT=0
PROJECT_ISSUES=0

if [ -d "$DEV_DIR" ]; then
    ok "Development directory: $DEV_DIR"
    
    for dir in "$DEV_DIR"/*/; do
        [ ! -d "$dir" ] && continue
        name=$(basename "$dir")
        [[ "$name" =~ $SYNC_SKIP_PATTERN ]] && continue

        ((PROJECT_COUNT++))
        
        # Check if project has rulesync
        if [ -f "$dir/rulesync.jsonc" ]; then
            # Check for .cursor/rules
            if [ -d "$dir/.cursor/rules" ] && [ "$(ls -A "$dir/.cursor/rules" 2>/dev/null)" ]; then
                ok "$name: rulesync configured"
            else
                fail "$name: missing .cursor/rules (run sync-rules.sh sync)"
                ((PROJECT_ISSUES++))
                ((ERROR_COUNT++))
            fi
            
            # Warn about local MCP configs (should use global)
            if [ -f "$dir/.cursor/mcp.json" ] || [ -f "$dir/.rulesync/mcp.json" ]; then
                warn "$name: has local MCP config (use global instead)"
            fi
        else
            fail "$name: missing rulesync.jsonc (mandatory)"
            ((PROJECT_ISSUES++))
            ((ERROR_COUNT++))
        fi
    done
    
    if [ $PROJECT_COUNT -eq 0 ]; then
        warn "No projects found in $DEV_DIR"
    else
        echo ""
        log "$PROJECT_COUNT project(s) found, $PROJECT_ISSUES with issues"
        
        if [ $PROJECT_ISSUES -gt 0 ] && remediate; then
            warn "Syncing projects..."
            SKIP_PREFLIGHT=1 "$SCRIPT_DIR/sync-rules.sh" sync 2>/dev/null || true
        fi
    fi
else
    fail "Development directory not found: $DEV_DIR"
    ((ERROR_COUNT++))
fi

header "Summary"

if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${COLOR_GREEN}All checks passed!${COLOR_RESET}"
    exit 0
else
    echo -e "${COLOR_RED}Found $ERROR_COUNT issue(s)${COLOR_RESET}"
    if [[ "$FIX_MODE" != "--fix" ]]; then
        echo ""
        echo "Run with --fix to attempt remediation:"
        echo "  $0 --fix"
    fi
    exit 1
fi
