#!/bin/bash
# Bootstrap AI development environment on a fresh Mac
# Run with: curl -fsSL https://raw.githubusercontent.com/bloom-legal/ai-development/main/bootstrap.sh | bash
set -e

# Colors
G='\033[0;32m' R='\033[0;31m' Y='\033[1;33m' B='\033[0;34m' N='\033[0m'
log() { echo -e "${G}✓ $1${N}"; }
warn() { echo -e "${Y}⚠ $1${N}"; }
error() { echo -e "${R}✗ $1${N}"; exit 1; }
header() { echo -e "\n${B}=== $1 ===${N}"; }

# Config
REPO_URL="https://github.com/bloom-legal/ai-development.git"
INSTALL_DIR="$HOME/Development/global"

header "AI Development Bootstrap"
echo "This will set up your Mac for AI-assisted development."
echo ""

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    error "This script is for macOS only"
fi

# 1. Install Xcode Command Line Tools (includes git)
header "Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
    log "Xcode CLI tools already installed"
else
    warn "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Please complete the installation dialog, then press Enter to continue..."
    read -r
fi

# 2. Install Homebrew
header "Homebrew"
if command -v brew &>/dev/null; then
    log "Homebrew already installed"
else
    warn "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to PATH for Apple Silicon
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        log "Homebrew installed (Apple Silicon)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
        log "Homebrew installed (Intel)"
    fi
fi

# Ensure brew is in PATH for this session
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# 3. Install Git (if not from Xcode)
header "Git"
if command -v git &>/dev/null; then
    log "Git already installed ($(git --version | cut -d' ' -f3))"
else
    warn "Installing Git..."
    brew install git
    log "Git installed"
fi

# 4. Clone the repository
header "Repository"
mkdir -p "$HOME/Development"

if [ -d "$INSTALL_DIR" ]; then
    log "Repository already exists at $INSTALL_DIR"
    cd "$INSTALL_DIR"
    git pull origin main 2>/dev/null || true
else
    warn "Cloning repository..."
    git clone "$REPO_URL" "$INSTALL_DIR"
    log "Repository cloned to $INSTALL_DIR"
fi

# 5. Run the full install script
header "Running Install Script"
cd "$INSTALL_DIR"
chmod +x install.sh check.sh sync-rules.sh
./install.sh

header "Bootstrap Complete!"
echo ""
echo "Your AI development environment is ready."
echo ""
echo "Next steps:"
echo "  1. Open Cursor and sign in"
echo "  2. Run 'claude' in terminal to authenticate Claude Code CLI"
echo ""
echo "Useful commands:"
echo "  $INSTALL_DIR/sync-rules.sh      # Sync configs"
echo "  $INSTALL_DIR/check.sh           # Verify setup"
echo ""
