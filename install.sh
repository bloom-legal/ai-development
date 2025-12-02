#!/bin/bash
# One-time installation script for AI development environment
# Installs: Homebrew, Git, VS Code, Cursor, Claude Desktop, Claude Code CLI + runs initial sync
# For fresh Mac, use bootstrap.sh instead (handles cloning this repo first)
set -e

# Colors
G='\033[0;32m' R='\033[0;31m' Y='\033[1;33m' B='\033[0;34m' N='\033[0m'
log() { echo -e "${G}✓ $1${N}"; }
warn() { echo -e "${Y}⚠ $1${N}"; }
error() { echo -e "${R}✗ $1${N}"; }
header() { echo -e "\n${B}=== $1 ===${N}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

header "AI Development Environment Setup"

# Ensure brew is in PATH
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# 1. Install Homebrew
header "Homebrew"
if command -v brew &>/dev/null; then
    log "Homebrew already installed"
    brew update
else
    warn "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to PATH for Apple Silicon
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    fi
    log "Homebrew installed"
fi

# 2. Install Git
header "Git"
if command -v git &>/dev/null; then
    log "Git already installed ($(git --version | cut -d' ' -f3))"
else
    warn "Installing Git..."
    brew install git
    log "Git installed"
fi

# 3. Install Node.js (required before Claude Code CLI)
header "Node.js"
if command -v node &>/dev/null; then
    log "Node.js already installed ($(node --version))"
else
    warn "Installing Node.js..."
    brew install node
    log "Node.js installed"
fi

# 4. Install VS Code
header "Visual Studio Code"
if [ -d "/Applications/Visual Studio Code.app" ]; then
    log "VS Code already installed"
else
    warn "Installing VS Code..."
    brew install --cask visual-studio-code
    log "VS Code installed"
fi

# 5. Install Cursor
header "Cursor"
if [ -d "/Applications/Cursor.app" ]; then
    log "Cursor already installed"
else
    warn "Installing Cursor..."
    brew install --cask cursor
    log "Cursor installed"
fi

# 6. Install Claude Code (CLI)
header "Claude Code CLI"
if command -v claude &>/dev/null; then
    log "Claude Code CLI already installed"
else
    warn "Installing Claude Code CLI..."
    npm install -g @anthropic-ai/claude-code
    log "Claude Code CLI installed"
fi

# 8. Install other dependencies
header "Dependencies"

# jq (required for JSON manipulation in sync script)
if command -v jq &>/dev/null; then
    log "jq already installed"
else
    warn "Installing jq..."
    brew install jq
    log "jq installed"
fi

# Python/uvx (required for some MCP servers)
if command -v uvx &>/dev/null; then
    log "uvx already installed"
else
    warn "Installing uv (Python package manager)..."
    brew install uv
    log "uv installed"
fi

# 9. Create required directories
header "Directories"
mkdir -p ~/.cursor
mkdir -p ~/.claude/commands
mkdir -p ~/Library/Application\ Support/Claude
mkdir -p ~/Library/Application\ Support/Cursor/User/globalStorage/rooveterinaryinc.roo-code-nightly/settings
mkdir -p ~/Development
log "Directories created"

# 10. Generate MCP config from template
header "MCP Configuration"
MCP_TEMPLATE="$SCRIPT_DIR/template/.rulesync/mcp.json.template"
MCP_OUTPUT="$SCRIPT_DIR/template/.rulesync/mcp.json"
ENV_FILE="$SCRIPT_DIR/.env"

if [ -f "$MCP_TEMPLATE" ]; then
    # Load .env if it exists
    if [ -f "$ENV_FILE" ]; then
        set -a
        source "$ENV_FILE"
        set +a
        log "Loaded configuration from .env"
    else
        warn "No .env file found - using default placeholders"
        warn "Copy .env.example to .env and fill in your values"
    fi

    # Generate mcp.json from template using envsubst
    envsubst < "$MCP_TEMPLATE" > "$MCP_OUTPUT"
    log "Generated mcp.json from template"
else
    error "MCP template not found at $MCP_TEMPLATE"
    exit 1
fi

# 11. Run initial sync
header "Initial Sync"
if [ -f "$SCRIPT_DIR/sync-rules.sh" ]; then
    "$SCRIPT_DIR/sync-rules.sh" mcp
    log "MCP configs synced to global locations"
else
    error "sync-rules.sh not found in $SCRIPT_DIR"
    exit 1
fi

# 12. Verify installation
header "Verification"
"$SCRIPT_DIR/check.sh" || true

header "Setup Complete!"
echo ""
echo "Installed:"
echo "  • Homebrew, Git, Node.js, jq, uv"
echo "  • VS Code, Cursor"
echo "  • Claude Code CLI"
echo "  • MCP configs synced to all tools"
echo ""
echo "Next steps:"
echo "  1. Copy .env.example to .env and add your secrets"
echo "  2. Run ./install.sh again to regenerate MCP config"
echo "  3. Open Cursor and sign in"
echo "  4. Run 'claude' in terminal to authenticate Claude Code CLI"
echo ""
echo "Useful commands:"
echo "  $SCRIPT_DIR/sync-rules.sh sync  # Sync all configs"
echo "  $SCRIPT_DIR/check.sh            # Verify setup"
