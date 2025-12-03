#!/bin/bash
# Bootstrap AI development environment on a fresh Mac
# Run with: curl -fsSL https://raw.githubusercontent.com/bloom-legal/ai-development/main/bootstrap.sh | bash
set -e

# Load common functions (if available, otherwise define minimal versions)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
if [[ -f "$SCRIPT_DIR/scripts/bash/lib/common.sh" ]]; then
    source "$SCRIPT_DIR/scripts/bash/lib/common.sh"
else
    # Fallback minimal definitions for curl | bash execution
    init_colors() {
        if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
            export COLOR_GREEN='\033[0;32m' COLOR_RED='\033[0;31m' COLOR_YELLOW='\033[1;33m'
            export COLOR_BLUE='\033[0;34m' COLOR_RESET='\033[0m'
        else
            export COLOR_GREEN='' COLOR_RED='' COLOR_YELLOW='' COLOR_BLUE='' COLOR_RESET=''
        fi
    }
    log() { echo -e "${COLOR_GREEN}✓ $1${COLOR_RESET}"; }
    warn() { echo -e "${COLOR_YELLOW}⚠ $1${COLOR_RESET}"; }
    error() { echo -e "${COLOR_RED}✗ $1${COLOR_RESET}"; exit 1; }
    header() { echo -e "\n${COLOR_BLUE}=== $1 ===${COLOR_RESET}"; }
    init_colors
fi

# Config
REPO_URL="https://github.com/bloom-legal/ai-development.git"
INSTALL_DIR="$HOME/Development/global"
MAX_RETRIES=3

# Use retry_command from common.sh if available, otherwise define it
if ! command -v retry_command &>/dev/null; then
    retry_command() {
        local cmd="$1"
        local desc="$2"
        local max_attempts="${3:-3}"
        local attempt=1

        while [ $attempt -le $max_attempts ]; do
            if eval "$cmd"; then
                return 0
            fi
            warn "Attempt $attempt/$max_attempts failed: $desc"
            ((attempt++))
            sleep 2
        done
        error "Failed after $max_attempts attempts: $desc"
    }
fi

header "AI Development Bootstrap"
echo "This will set up your Mac for AI-assisted development."
echo ""

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    error "This script is for macOS only"
fi

# Check for internet connectivity
header "Connectivity"
if ! ping -c 1 -t 5 github.com &>/dev/null && ! curl -s --head --max-time 5 https://github.com &>/dev/null; then
    error "No internet connection. Please connect to the internet and try again."
fi
log "Internet connection available"

# Check disk space (need at least 5GB free)
free_space_gb=$(df -g "$HOME" | awk 'NR==2 {print $4}')
if [[ "$free_space_gb" -lt 5 ]]; then
    error "Insufficient disk space. Need at least 5GB free, have ${free_space_gb}GB."
fi
log "Disk space OK (${free_space_gb}GB free)"

# Check macOS version (need 10.14+)
macos_version=$(sw_vers -productVersion)
major_version=$(echo "$macos_version" | cut -d. -f1)
minor_version=$(echo "$macos_version" | cut -d. -f2)

if [[ "$major_version" -lt 10 ]] || [[ "$major_version" -eq 10 && "$minor_version" -lt 14 ]]; then
    error "macOS 10.14 (Mojave) or later required. You have $macos_version"
fi
log "macOS $macos_version detected"

# Check for required commands
header "Prerequisites"

# curl is required (should always be present)
if ! command -v curl &>/dev/null; then
    error "curl not found. This should never happen on macOS."
fi
log "curl available"

# 1. Install Xcode Command Line Tools (includes git)
header "Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
    log "Xcode CLI tools already installed"
else
    warn "Installing Xcode Command Line Tools..."

    # Touch file to trigger installation
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

    # Find the package name (try multiple patterns)
    XCODE_PACKAGE_NAME=$(softwareupdate -l 2>/dev/null | grep -E "Command Line Tools|CLTools" | grep -v "^$" | head -n 1 | sed 's/^[* ]*//' | sed 's/^ *//')

    if [[ -z "$XCODE_PACKAGE_NAME" ]]; then
        # Alternative: look for Label line
        XCODE_PACKAGE_NAME=$(softwareupdate -l 2>/dev/null | grep -o "Command Line Tools for Xcode-[0-9.]*" | head -n 1)
    fi

    if [[ -n "$XCODE_PACKAGE_NAME" ]]; then
        warn "Installing: $XCODE_PACKAGE_NAME"
        softwareupdate -i "$XCODE_PACKAGE_NAME" --verbose 2>&1 || softwareupdate -i "$XCODE_PACKAGE_NAME" 2>&1 || {
            warn "softwareupdate failed, trying xcode-select..."
        }
    fi

    rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

    # If still not installed, try xcode-select and wait
    if ! xcode-select -p &>/dev/null; then
        xcode-select --install 2>/dev/null &
        warn "Waiting for Xcode CLI tools installation (this may take a few minutes)..."

        # Wait up to 10 minutes for installation
        for i in {1..120}; do
            if xcode-select -p &>/dev/null; then
                break
            fi
            sleep 5
            printf "."
        done
        echo ""
    fi

    # Final check
    if xcode-select -p &>/dev/null; then
        log "Xcode CLI tools installed"
    else
        error "Xcode CLI tools installation failed. Please run 'xcode-select --install' manually and re-run this script."
    fi
fi

# 2. Install Homebrew
header "Homebrew"

# Setup brew PATH (use common function if available)
if command -v setup_brew_path &>/dev/null; then
    setup_brew_path
else
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        export PATH="/opt/homebrew/bin:$PATH"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
        export PATH="/usr/local/bin:$PATH"
    fi
fi

if command -v brew &>/dev/null; then
    log "Homebrew already installed"
else
    warn "Installing Homebrew..."
    retry_command 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' "Homebrew installation" "$MAX_RETRIES"

    # Add to PATH for this session and future sessions
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile 2>/dev/null || true
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile 2>/dev/null || true
        log "Homebrew installed (Apple Silicon)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile 2>/dev/null || true
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.bash_profile 2>/dev/null || true
        log "Homebrew installed (Intel)"
    else
        error "Homebrew installation failed - brew not found"
    fi
fi

    # Ensure brew is in PATH for this session
    if command -v setup_brew_path &>/dev/null; then
        setup_brew_path
    else
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
            export PATH="/opt/homebrew/bin:$PATH"
        elif [[ -f /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
            export PATH="/usr/local/bin:$PATH"
        fi
    fi

if ! command -v brew &>/dev/null; then
    error "Homebrew not in PATH after installation. Please restart terminal and re-run."
fi

# 3. Install Git (if not from Xcode)
header "Git"
if command -v git &>/dev/null; then
    log "Git already installed ($(git --version | cut -d' ' -f3))"
else
    warn "Installing Git..."
    retry_command 'brew install git' "Git installation" "$MAX_RETRIES"
    log "Git installed"
fi

# Verify git works
if ! git --version &>/dev/null; then
    error "Git not working properly"
fi

# 4. Clone the repository
header "Repository"
mkdir -p "$HOME/Development"

if [ -d "$INSTALL_DIR" ]; then
    log "Repository already exists at $INSTALL_DIR"
    cd "$INSTALL_DIR"

    # Try to update
    if git rev-parse --git-dir &>/dev/null; then
        git fetch origin main 2>/dev/null || true
        git reset --hard origin/main 2>/dev/null || warn "Could not update repository"
    fi
else
    warn "Cloning repository..."
    retry_command "git clone '$REPO_URL' '$INSTALL_DIR'" "Repository clone" "$MAX_RETRIES"
    log "Repository cloned to $INSTALL_DIR"
fi

# 5. Run the full install script
header "Running Install Script"
cd "$INSTALL_DIR"
chmod +x install.sh check.sh sync-rules.sh uninstall.sh 2>/dev/null || true

# Run install in auto mode (installs all, only prompts for MCP secrets)
./install.sh --auto

header "Bootstrap Complete!"
echo ""
echo "Your AI development environment is ready."
echo ""
echo "Next steps:"
echo "  1. Open a new terminal window (to refresh PATH)"
echo "  2. Open Cursor and sign in"
echo "  3. Run 'claude' in terminal to authenticate Claude Code CLI"
echo ""
echo "Useful commands:"
echo "  $INSTALL_DIR/install.sh       # Re-run installer"
echo "  $INSTALL_DIR/uninstall.sh     # Uninstall components"
echo "  $INSTALL_DIR/sync-rules.sh    # Sync configs"
echo "  $INSTALL_DIR/check.sh         # Verify setup"
echo ""
