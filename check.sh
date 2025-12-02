#!/bin/bash
# Check and remediate AI development environment
# Usage: ./check.sh [--fix]
set -e

# Colors
G='\033[0;32m' R='\033[0;31m' Y='\033[1;33m' B='\033[0;34m' N='\033[0m'
ok() { echo -e "${G}✓${N} $1"; }
fail() { echo -e "${R}✗${N} $1"; }
warn() { echo -e "${Y}⚠${N} $1"; }
header() { echo -e "\n${B}=== $1 ===${N}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TPL="$SCRIPT_DIR/template"
FIX="${1:-}"
ERRORS=0

# Global MCP config locations
CURSOR_MCP="$HOME/.cursor/mcp.json"
CLAUDE_DESKTOP_MCP="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
ROO_MCP="$HOME/Library/Application Support/Cursor/User/globalStorage/rooveterinaryinc.roo-code-nightly/settings/mcp_settings.json"

remediate() {
    if [[ "$FIX" == "--fix" ]]; then
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
    ((ERRORS++))
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
    ((ERRORS++))
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
    ((ERRORS++))
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
    ((ERRORS++))
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
    ((ERRORS++))
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
    ((ERRORS++))
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
    ((ERRORS++))
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
        ((ERRORS++))
        if remediate; then
            warn "Creating directory..."
            mkdir -p "$dir"
        fi
    fi
done

header "MCP Template"

# Check template exists
if [ -f "$TPL/.rulesync/mcp.json" ]; then
    ok "MCP template exists"
    MCP_COUNT=$(jq '.mcpServers | keys | length' "$TPL/.rulesync/mcp.json" 2>/dev/null || echo 0)
    ok "Template has $MCP_COUNT MCP servers"
else
    fail "MCP template not found at $TPL/.rulesync/mcp.json"
    ((ERRORS++))
fi

header "Global MCP Configs"

check_mcp_config() {
    local name="$1"
    local path="$2"

    if [ -f "$path" ]; then
        if jq -e '.mcpServers' "$path" &>/dev/null; then
            local count=$(jq '.mcpServers | keys | length' "$path" 2>/dev/null || echo 0)
            if [ "$count" -gt 0 ]; then
                ok "$name: $count MCP servers"
            else
                fail "$name: empty mcpServers"
                ((ERRORS++))
                if remediate; then
                    warn "Syncing MCPs..."
                    "$SCRIPT_DIR/sync-rules.sh" mcp
                fi
            fi
        else
            fail "$name: invalid format (no mcpServers key)"
            ((ERRORS++))
            if remediate; then
                warn "Syncing MCPs..."
                "$SCRIPT_DIR/sync-rules.sh" mcp
            fi
        fi
    else
        fail "$name: config file missing"
        ((ERRORS++))
        if remediate; then
            warn "Creating config..."
            mkdir -p "$(dirname "$path")"
            "$SCRIPT_DIR/sync-rules.sh" mcp
        fi
    fi
}

check_mcp_config "Cursor" "$CURSOR_MCP"
check_mcp_config "Roo Code" "$ROO_MCP"

# Claude Desktop needs special handling (has preferences)
check_mcp_config "Claude Desktop" "$CLAUDE_DESKTOP_MCP"

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

header "Summary"

if [ $ERRORS -eq 0 ]; then
    echo -e "${G}All checks passed!${N}"
    exit 0
else
    echo -e "${R}Found $ERRORS issue(s)${N}"
    if [[ "$FIX" != "--fix" ]]; then
        echo ""
        echo "Run with --fix to attempt remediation:"
        echo "  $0 --fix"
    fi
    exit 1
fi
