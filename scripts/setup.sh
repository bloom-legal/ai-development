#!/bin/bash
# =============================================================================
# AI Dev Environment Setup Script
# One-command setup for Claude Code and development tools on macOS
# =============================================================================
set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================
readonly MARKER="# Added by ai-dev-setup"
readonly MIN_MACOS_VERSION=12
readonly HELP_URL="https://github.com/joachimbrindeau/global/issues"

# Track what was installed for summary
INSTALLED=()
SKIPPED=()
UPDATED=()

# =============================================================================
# Logging Functions
# =============================================================================
info() {
    echo "[INFO] $*"
}

success() {
    echo "[✓] $*"
}

step() {
    echo ""
    echo "[→] $*"
}

error() {
    echo "[ERROR] $*" >&2
}

warn() {
    echo "[WARN] $*" >&2
}

# =============================================================================
# Error Handling Functions
# =============================================================================

# Trap for handling script interruption
cleanup_on_error() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo ""
        echo "======================================"
        echo "  Installation Interrupted"
        echo "======================================"
        echo ""
        echo "The setup was interrupted or encountered an error."
        echo ""
        echo "What was completed has been preserved."
        echo "You can safely re-run this script to continue."
        echo ""
        echo "For help: $HELP_URL"
        echo ""
    fi
}

# Handle Ctrl+C and other signals gracefully
handle_interrupt() {
    echo ""
    warn "Installation cancelled by user"
    exit 130
}

# Set traps for cleanup
trap cleanup_on_error EXIT
trap handle_interrupt INT TERM

# T028: Network error handler
handle_network_error() {
    local operation="$1"
    error "Network error during $operation"
    echo ""
    echo "Troubleshooting steps:"
    echo "  1. Check your internet connection"
    echo "  2. Try again in a few minutes"
    echo "  3. If using VPN, try disconnecting"
    echo ""
    echo "Then re-run this script to continue."
    echo ""
    echo "For help: $HELP_URL"
    exit 1
}

# T029: Admin/sudo denial handler
handle_permission_error() {
    error "Administrator privileges required"
    echo ""
    echo "This script needs admin access to install development tools."
    echo ""
    echo "Please:"
    echo "  1. Enter your Mac password when prompted"
    echo "  2. If you don't have admin access, contact your IT department"
    echo ""
    echo "For help: $HELP_URL"
    exit 1
}

# T030: Unsupported macOS handler (already in check_macos_version, this enhances it)
handle_unsupported_macos() {
    local current_version="$1"
    error "Unsupported macOS version: $current_version"
    echo ""
    echo "This script requires macOS Monterey (12.0) or newer."
    echo ""
    echo "Your options:"
    echo "  1. Upgrade your macOS (recommended)"
    echo "  2. Install components manually:"
    echo "     - Homebrew: https://brew.sh"
    echo "     - Claude Code: https://claude.ai/docs"
    echo ""
    echo "For help: $HELP_URL"
    exit 1
}

# =============================================================================
# System Check Functions
# =============================================================================

# T004: Check macOS version meets minimum requirement
check_macos_version() {
    local macos_version
    local major_version

    macos_version=$(sw_vers -productVersion)
    major_version=$(echo "$macos_version" | cut -d. -f1)

    if [[ "$major_version" -lt "$MIN_MACOS_VERSION" ]]; then
        handle_unsupported_macos "$macos_version"
    fi

    info "macOS version $macos_version meets requirements"
    return 0
}

# T005: Detect user's shell
detect_shell() {
    local shell_name
    shell_name=$(basename "$SHELL")
    echo "$shell_name"
}

# T006: Get the appropriate shell rc file path
get_shell_rc_file() {
    local shell_name
    shell_name=$(detect_shell)

    case "$shell_name" in
        zsh)
            echo "$HOME/.zshrc"
            ;;
        bash)
            # Prefer .bash_profile on macOS for login shells
            if [[ -f "$HOME/.bash_profile" ]]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
        fish)
            echo "$HOME/.config/fish/config.fish"
            ;;
        *)
            # Default to zsh (macOS default since Catalina)
            warn "Unknown shell '$shell_name', defaulting to zsh config"
            echo "$HOME/.zshrc"
            ;;
    esac
}

# T007: Check if marker already exists in rc file (for idempotency)
check_marker_exists() {
    local rc_file="$1"

    if [[ -f "$rc_file" ]] && grep -q "$MARKER" "$rc_file" 2>/dev/null; then
        return 0  # Marker exists
    fi
    return 1  # Marker does not exist
}

# =============================================================================
# Homebrew Functions
# =============================================================================

# T008: Check if Homebrew is installed
check_homebrew() {
    if command -v brew &>/dev/null; then
        return 0  # Homebrew exists
    fi
    return 1  # Homebrew not found
}

# T009: Install Homebrew
install_homebrew() {
    info "Installing Homebrew (this may take a few minutes)..."

    # Run the official Homebrew installer with error handling
    if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        # Check if it's a network error or permission error
        if ! curl -s --head https://raw.githubusercontent.com &>/dev/null; then
            handle_network_error "Homebrew download"
        else
            handle_permission_error
        fi
    fi

    # Add Homebrew to PATH for current session
    add_homebrew_to_path

    INSTALLED+=("Homebrew")
    success "Homebrew installed successfully"
}

# T010: Add Homebrew to PATH (handles Apple Silicon and Intel Macs)
add_homebrew_to_path() {
    local brew_path

    # Determine Homebrew path based on architecture
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        # Apple Silicon
        brew_path="/opt/homebrew/bin"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        # Intel Mac
        brew_path="/usr/local/bin"
        eval "$(/usr/local/bin/brew shellenv)"
    else
        error "Homebrew installed but cannot find brew binary"
        return 1
    fi

    export PATH="$brew_path:$PATH"
}

# =============================================================================
# Node.js Functions
# =============================================================================

# T011: Check if Node.js is installed
check_node() {
    if command -v node &>/dev/null; then
        return 0  # Node exists
    fi
    return 1  # Node not found
}

# T012: Install Node.js via Homebrew
install_node() {
    info "Installing Node.js via Homebrew..."

    if ! brew install node; then
        if ! curl -s --head https://formulae.brew.sh &>/dev/null; then
            handle_network_error "Node.js download"
        fi
        error "Failed to install Node.js"
        echo "For help: $HELP_URL"
        exit 1
    fi

    INSTALLED+=("Node.js")
    success "Node.js installed successfully"
}

# =============================================================================
# VS Code Functions
# =============================================================================

check_vscode() {
    if [[ -d "/Applications/Visual Studio Code.app" ]] || command -v code &>/dev/null; then
        return 0
    fi
    return 1
}

install_vscode() {
    info "Installing VS Code..."

    if ! brew install --cask visual-studio-code; then
        error "Failed to install VS Code"
        echo "For help: $HELP_URL"
        exit 1
    fi

    INSTALLED+=("VS Code")
    success "VS Code installed successfully"
}

# =============================================================================
# Cursor Functions
# =============================================================================

check_cursor() {
    if [[ -d "/Applications/Cursor.app" ]] || command -v cursor &>/dev/null; then
        return 0
    fi
    return 1
}

install_cursor() {
    info "Installing Cursor..."

    if ! brew install --cask cursor; then
        error "Failed to install Cursor"
        echo "For help: $HELP_URL"
        exit 1
    fi

    INSTALLED+=("Cursor")
    success "Cursor installed successfully"
}

# =============================================================================
# CLI Tools Functions (jq, uv)
# =============================================================================

check_jq() {
    if command -v jq &>/dev/null; then
        return 0
    fi
    return 1
}

install_jq() {
    info "Installing jq..."

    if ! brew install jq; then
        error "Failed to install jq"
        echo "For help: $HELP_URL"
        exit 1
    fi

    INSTALLED+=("jq")
    success "jq installed successfully"
}

check_uv() {
    if command -v uv &>/dev/null; then
        return 0
    fi
    return 1
}

install_uv() {
    info "Installing uv..."

    if ! brew install uv; then
        error "Failed to install uv"
        echo "For help: $HELP_URL"
        exit 1
    fi

    INSTALLED+=("uv")
    success "uv installed successfully"
}

# =============================================================================
# Claude Code Functions
# =============================================================================

check_claude() {
    if command -v claude &>/dev/null; then
        return 0  # Claude exists
    fi
    return 1  # Claude not found
}

install_claude() {
    info "Installing Claude Code..."

    # Use the official native installer (doesn't require Node.js)
    if ! curl -fsSL https://claude.ai/install.sh | bash; then
        if ! curl -s --head https://claude.ai &>/dev/null; then
            handle_network_error "Claude Code download"
        fi
        error "Failed to install Claude Code"
        echo "For help: $HELP_URL"
        exit 1
    fi

    INSTALLED+=("Claude Code")
    success "Claude Code installed successfully"
}

update_claude() {
    info "Checking for Claude Code updates..."

    claude update || {
        warn "Claude update command not available, reinstalling..."
        install_claude
        return
    }

    UPDATED+=("Claude Code")
    success "Claude Code updated successfully"
}

# =============================================================================
# Shell Configuration
# =============================================================================

# T016: Configure shell rc file with PATH entries
configure_shell() {
    local rc_file
    local shell_name

    rc_file=$(get_shell_rc_file)
    shell_name=$(detect_shell)

    step "Configuring shell ($shell_name)..."

    # Check if already configured (idempotency)
    if check_marker_exists "$rc_file"; then
        SKIPPED+=("Shell configuration (already configured)")
        info "Shell already configured, skipping"
        return 0
    fi

    # Ensure rc file exists
    if [[ ! -f "$rc_file" ]]; then
        touch "$rc_file"
    fi

    # Add PATH configuration based on shell type
    if [[ "$shell_name" == "fish" ]]; then
        # Fish shell uses different syntax
        mkdir -p "$HOME/.config/fish"
        cat >> "$rc_file" << EOF

$MARKER
# Homebrew
if test -d /opt/homebrew/bin
    fish_add_path /opt/homebrew/bin
end
if test -d /usr/local/bin
    fish_add_path /usr/local/bin
end
EOF
    else
        # Bash and Zsh use similar syntax
        cat >> "$rc_file" << EOF

$MARKER
# Homebrew (Apple Silicon)
if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "\$(/opt/homebrew/bin/brew shellenv)"
fi
# Homebrew (Intel)
if [[ -f "/usr/local/bin/brew" ]]; then
    eval "\$(/usr/local/bin/brew shellenv)"
fi
EOF
    fi

    INSTALLED+=("Shell configuration")
    success "Shell configured successfully"
}

# =============================================================================
# Summary Function
# =============================================================================

show_summary() {
    local total_changes
    total_changes=$((${#INSTALLED[@]} + ${#UPDATED[@]}))

    echo ""
    echo "======================================"
    echo "  Setup Complete!"
    echo "======================================"
    echo ""

    if [[ ${#INSTALLED[@]} -gt 0 ]]; then
        echo "Installed:"
        for item in "${INSTALLED[@]}"; do
            echo "  [+] $item"
        done
        echo ""
    fi

    if [[ ${#UPDATED[@]} -gt 0 ]]; then
        echo "Updated:"
        for item in "${UPDATED[@]}"; do
            echo "  [^] $item"
        done
        echo ""
    fi

    if [[ ${#SKIPPED[@]} -gt 0 ]]; then
        echo "Already installed (skipped):"
        for item in "${SKIPPED[@]}"; do
            echo "  [=] $item"
        done
        echo ""
    fi

    # Summary counts
    echo "--------------------------------------"
    echo "Summary: ${#INSTALLED[@]} installed, ${#UPDATED[@]} updated, ${#SKIPPED[@]} skipped"
    echo "--------------------------------------"
    echo ""

    # Next steps with clear instructions
    echo "What's next?"
    echo ""
    if [[ $total_changes -gt 0 ]]; then
        echo "  1. Open a NEW terminal window"
        echo "     (required for PATH changes to take effect)"
        echo ""
    fi
    echo "  2. Start using Claude Code:"
    echo "     $ claude"
    echo ""
    echo "  3. Or check the version:"
    echo "     $ claude --version"
    echo ""
    echo "======================================"
    echo "  Ready to code with AI!"
    echo "======================================"
    echo ""
}

# =============================================================================
# Main Orchestration
# =============================================================================

# Main function orchestrating installation order
main() {
    echo ""
    echo "======================================"
    echo "  AI Dev Environment Setup"
    echo "======================================"
    echo ""
    echo "This script will install:"
    echo "  - Homebrew (macOS package manager)"
    echo "  - Node.js (JavaScript runtime)"
    echo "  - VS Code (code editor)"
    echo "  - Cursor (AI-powered editor)"
    echo "  - jq (JSON processor)"
    echo "  - uv (Python package manager)"
    echo "  - Claude Code (AI coding assistant)"
    echo ""
    echo "Starting installation..."
    echo ""

    # Step 1: Check macOS version
    step "Checking system requirements..."
    info "Verifying macOS version..."
    check_macos_version || exit 1

    # Step 2: Install Homebrew (if missing)
    step "Setting up Homebrew (1/8)..."
    if check_homebrew; then
        local brew_version
        brew_version=$(brew --version | head -n1)
        SKIPPED+=("Homebrew ($brew_version)")
        info "Homebrew already installed: $brew_version"
    else
        info "Homebrew not found. Installing..."
        install_homebrew
    fi

    # Ensure Homebrew is in PATH
    add_homebrew_to_path || true

    # Step 3: Install Node.js via Homebrew (if missing)
    step "Setting up Node.js (2/8)..."
    if check_node; then
        local node_version
        node_version=$(node --version)
        SKIPPED+=("Node.js ($node_version)")
        info "Node.js already installed: $node_version"
    else
        info "Node.js not found. Installing via Homebrew..."
        install_node
    fi

    # Step 4: Install VS Code
    step "Setting up VS Code (3/8)..."
    if check_vscode; then
        SKIPPED+=("VS Code (already installed)")
        info "VS Code already installed"
    else
        install_vscode
    fi

    # Step 5: Install Cursor
    step "Setting up Cursor (4/8)..."
    if check_cursor; then
        SKIPPED+=("Cursor (already installed)")
        info "Cursor already installed"
    else
        install_cursor
    fi

    # Step 6: Install jq
    step "Setting up jq (5/8)..."
    if check_jq; then
        local jq_version
        jq_version=$(jq --version 2>/dev/null || echo "installed")
        SKIPPED+=("jq ($jq_version)")
        info "jq already installed: $jq_version"
    else
        install_jq
    fi

    # Step 7: Install uv
    step "Setting up uv (6/8)..."
    if check_uv; then
        local uv_version
        uv_version=$(uv --version 2>/dev/null || echo "installed")
        SKIPPED+=("uv ($uv_version)")
        info "uv already installed: $uv_version"
    else
        install_uv
    fi

    # Step 8: Install or update Claude Code
    step "Setting up Claude Code (7/8)..."
    if check_claude; then
        local claude_version
        claude_version=$(claude --version 2>/dev/null || echo "installed")
        info "Claude Code found ($claude_version). Checking for updates..."
        update_claude
    else
        info "Claude Code not found. Installing..."
        install_claude
    fi

    # Step 9: Configure shell rc file (idempotent)
    step "Configuring shell (8/8)..."
    configure_shell

    # Show summary
    show_summary
}

# Run main
main "$@"
