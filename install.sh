#!/bin/bash
# One-time installation script for AI development environment
# Installs: Homebrew, VS Code, Cursor, Claude Code + runs initial sync
set -e

# Colors
G='\033[0;32m' R='\033[0;31m' Y='\033[1;33m' B='\033[0;34m' N='\033[0m'
log() { echo -e "${G}✓ $1${N}"; }
warn() { echo -e "${Y}⚠ $1${N}"; }
error() { echo -e "${R}✗ $1${N}"; }
header() { echo -e "\n${B}=== $1 ===${N}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

header "AI Development Environment Setup"

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

# 2. Install VS Code
header "Visual Studio Code"
if brew list --cask visual-studio-code &>/dev/null || [ -d "/Applications/Visual Studio Code.app" ]; then
    log "VS Code already installed"
else
    warn "Installing VS Code..."
    brew install --cask visual-studio-code
    log "VS Code installed"
fi

# 3. Install Cursor
header "Cursor"
if brew list --cask cursor &>/dev/null || [ -d "/Applications/Cursor.app" ]; then
    log "Cursor already installed"
else
    warn "Installing Cursor..."
    brew install --cask cursor
    log "Cursor installed"
fi

# 4. Install Claude Code (CLI)
header "Claude Code"
if command -v claude &>/dev/null; then
    log "Claude Code already installed"
else
    warn "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
    log "Claude Code installed"
fi

# 5. Install dependencies
header "Dependencies"

# Node.js (required for MCP servers)
if command -v node &>/dev/null; then
    log "Node.js already installed ($(node --version))"
else
    warn "Installing Node.js..."
    brew install node
    log "Node.js installed"
fi

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

# 6. Create required directories
header "Directories"
mkdir -p ~/.cursor
mkdir -p ~/.claude/commands
mkdir -p ~/Library/Application\ Support/Claude
mkdir -p ~/Library/Application\ Support/Cursor/User/globalStorage/rooveterinaryinc.roo-code-nightly/settings
log "Directories created"

# 7. Run initial sync
header "Initial Sync"
if [ -f "$SCRIPT_DIR/sync-rules.sh" ]; then
    "$SCRIPT_DIR/sync-rules.sh" mcp
    log "MCP configs synced to global locations"
else
    error "sync-rules.sh not found in $SCRIPT_DIR"
    exit 1
fi

# 8. Verify installation
header "Verification"
"$SCRIPT_DIR/check.sh" || true

header "Setup Complete!"
echo ""
echo "Next steps:"
echo "  1. Open Cursor and sign in"
echo "  2. Run 'claude' in terminal to authenticate Claude Code"
echo "  3. Open Claude Desktop app and sign in"
echo ""
echo "To sync configs: $SCRIPT_DIR/sync-rules.sh sync"
echo "To check status: $SCRIPT_DIR/check.sh"
