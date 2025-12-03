#!/bin/bash
# Interactive installation script for AI development environment
# Navigate with arrow keys, space to toggle, enter to confirm
# Use --auto flag to install all without menu (still prompts for MCP secrets)
set -e

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/bash/lib/common.sh"

AUTO_MODE=false
SKIP_SECRETS=false

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --auto) AUTO_MODE=true ;;
        --skip-secrets) SKIP_SECRETS=true ;;
        --help|-h)
            echo "Usage: ./install.sh [options]"
            echo ""
            echo "Options:"
            echo "  --auto          Install all without interactive menu (prompts for secrets)"
            echo "  --skip-secrets  Skip MCP secrets configuration"
            echo "  --auto --skip-secrets  Fully non-interactive one-click install"
            echo "  --help          Show this help"
            exit 0
            ;;
    esac
done

# Check if terminal supports TUI
if check_tui_support; then
    TUI_SUPPORTED=true
else
    TUI_SUPPORTED=false
fi

# Setup brew PATH
setup_brew_path

# Items: "name|check_cmd|install_cmd|description"
ITEMS=(
    "Homebrew|command -v brew|INSTALL_BREW|Package manager (required)"
    "Git|command -v git|brew install git|Version control"
    "Node.js|command -v node|brew install node|JavaScript runtime (required for MCP)"
    "VS Code|test -d '/Applications/Visual Studio Code.app'|brew install --cask visual-studio-code|Code editor"
    "Cursor|test -d '/Applications/Cursor.app'|brew install --cask cursor|AI-powered editor"
    "Claude Code CLI|command -v claude|npm install -g @anthropic-ai/claude-code|Terminal AI assistant"
    "jq|command -v jq|brew install jq|JSON processor"
    "uv|command -v uvx|brew install uv|Python package manager"
    "envsubst|command -v envsubst|brew install gettext|Template variable substitution"
    "MCP Configs|ALWAYS_INSTALL|CONFIGURE_MCP|Sync MCP servers to all tools"
)

# Selection state (1=selected, 0=not)
declare -a SELECTED
declare -a INSTALLED

# Check what's already installed
check_installed() {
    for i in "${!ITEMS[@]}"; do
        IFS='|' read -r name check_cmd install_cmd desc <<< "${ITEMS[$i]}"
        if [[ "$check_cmd" == "ALWAYS_INSTALL" ]]; then
            INSTALLED[$i]=0
            SELECTED[$i]=1
        elif eval "$check_cmd" &>/dev/null; then
            INSTALLED[$i]=1
            SELECTED[$i]=0
        else
            INSTALLED[$i]=0
            SELECTED[$i]=1
        fi
    done
}

check_installed

CURRENT=0
TOTAL=${#ITEMS[@]}
MIN_POS=-2

# Use cursor functions from common library

trap 'show_cursor; echo' EXIT

# Draw the menu
draw_menu() {
    if ! $TUI_SUPPORTED; then
        return
    fi

    clear 2>/dev/null || printf '\033[2J\033[H'
    echo -e "${COLOR_BOLD}${COLOR_GREEN}=== Install AI Development Environment ===${COLOR_RESET}"
    echo -e "${COLOR_DIM}↑↓ navigate | Space toggle | a=all | n=none | Enter confirm | q=quit${COLOR_RESET}"
    echo ""

    # Select All option
    if [ $CURRENT -eq -1 ]; then
        echo -e " ${COLOR_BOLD}> [${COLOR_GREEN}Select All${COLOR_RESET}${COLOR_BOLD}]${COLOR_RESET}"
    else
        echo -e "   [${COLOR_DIM}Select All${COLOR_RESET}]"
    fi

    # Deselect All option
    if [ $CURRENT -eq -2 ]; then
        echo -e " ${COLOR_BOLD}> [${COLOR_RED}Deselect All${COLOR_RESET}${COLOR_BOLD}]${COLOR_RESET}"
    else
        echo -e "   [${COLOR_DIM}Deselect All${COLOR_RESET}]"
    fi

    echo ""

    for i in "${!ITEMS[@]}"; do
        IFS='|' read -r name check_cmd install_cmd desc <<< "${ITEMS[$i]}"

        # Cursor indicator
        if [ $i -eq $CURRENT ]; then
            cursor=">"
            line_color="${COLOR_BOLD}"
        else
            cursor=" "
            line_color=""
        fi

        # Checkbox and status
        if [ ${INSTALLED[$i]} -eq 1 ]; then
            checkbox="${COLOR_GREEN}[✓]${COLOR_RESET}"
            status="${COLOR_DIM}(installed)${COLOR_RESET}"
        elif [ ${SELECTED[$i]} -eq 1 ]; then
            checkbox="${COLOR_YELLOW}[x]${COLOR_RESET}"
            status=""
        else
            checkbox="[ ]"
            status=""
        fi

        echo -e " ${line_color}${cursor} ${checkbox} ${name}${COLOR_RESET} ${COLOR_DIM}- ${desc}${COLOR_RESET} ${status}"
    done

    echo ""

    # Count selected (not already installed)
    count=0
    for i in "${!SELECTED[@]}"; do
        if [ ${SELECTED[$i]} -eq 1 ] && [ ${INSTALLED[$i]} -eq 0 ]; then
            ((count++)) || true
        fi
    done

    if [ $count -gt 0 ]; then
        echo -e "${COLOR_YELLOW}$count item(s) selected for installation${COLOR_RESET}"
    else
        echo -e "${COLOR_GREEN}Everything is already installed!${COLOR_RESET}"
    fi
}

# Toggle current item
toggle_current() {
    if [ $CURRENT -eq -1 ]; then
        select_all 1
    elif [ $CURRENT -eq -2 ]; then
        select_all 0
    elif [ ${INSTALLED[$CURRENT]} -eq 0 ]; then
        if [ ${SELECTED[$CURRENT]} -eq 1 ]; then
            SELECTED[$CURRENT]=0
        else
            SELECTED[$CURRENT]=1
        fi
    fi
}

# Select/deselect all (only uninstalled items)
select_all() {
    local val=$1
    for i in "${!SELECTED[@]}"; do
        if [ ${INSTALLED[$i]} -eq 0 ]; then
            SELECTED[$i]=$val
        fi
    done
}

# Install Homebrew
install_brew() {
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        error "Homebrew installation failed"
        return 1
    }

    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile 2>/dev/null || true
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile 2>/dev/null || true
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile 2>/dev/null || true
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.bash_profile 2>/dev/null || true
    fi

    setup_brew_path
}

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
    SKIP_PREFLIGHT=1 "$SCRIPT_DIR/sync-rules.sh" sync 2>/dev/null || warn "Rules sync had warnings"

    # Copy Claude Code CLI commands
    if [ -d "$SCRIPT_DIR/template/.claude/commands" ]; then
        cp -f "$SCRIPT_DIR/template/.claude/commands/"*.md ~/.claude/commands/ 2>/dev/null || true
        log "Claude Code commands synced to ~/.claude/commands"
    fi
}

# Execute installation
do_install() {
    show_cursor
    clear 2>/dev/null || printf '\033[2J\033[H'
    echo -e "${COLOR_BOLD}${COLOR_GREEN}=== Installing ===${COLOR_RESET}"
    echo ""

    local any_selected=0
    for i in "${!ITEMS[@]}"; do
        if [ ${SELECTED[$i]} -eq 1 ] && [ ${INSTALLED[$i]} -eq 0 ]; then
            any_selected=1
            IFS='|' read -r name check_cmd install_cmd desc <<< "${ITEMS[$i]}"
            echo -e "${COLOR_YELLOW}Installing: ${name}...${COLOR_RESET}"

            if [[ "$install_cmd" == "INSTALL_BREW" ]]; then
                install_brew || warn "Homebrew installation had issues"
            elif [[ "$install_cmd" == "CONFIGURE_MCP" ]]; then
                configure_mcp
            else
                eval "$install_cmd" 2>&1 || warn "$name installation had issues"
            fi

            # Refresh PATH after each install
            setup_brew_path
            hash -r 2>/dev/null || true

            echo -e "${COLOR_GREEN}✓ ${name} done${COLOR_RESET}"
            echo ""
        fi
    done

    if [ $any_selected -eq 0 ]; then
        echo -e "${COLOR_GREEN}Nothing to install - everything is already set up!${COLOR_RESET}"
    else
        # Run verification
        echo -e "${COLOR_BLUE}Verifying installation...${COLOR_RESET}"
        echo ""

        local errors=0
        command -v brew &>/dev/null && echo -e "${COLOR_GREEN}✓${COLOR_RESET} Homebrew" || { echo -e "${COLOR_RED}✗${COLOR_RESET} Homebrew"; ((errors++)) || true; }
        command -v git &>/dev/null && echo -e "${COLOR_GREEN}✓${COLOR_RESET} Git" || { echo -e "${COLOR_RED}✗${COLOR_RESET} Git"; ((errors++)) || true; }
        command -v node &>/dev/null && echo -e "${COLOR_GREEN}✓${COLOR_RESET} Node.js" || { echo -e "${COLOR_RED}✗${COLOR_RESET} Node.js"; ((errors++)) || true; }
        command -v claude &>/dev/null && echo -e "${COLOR_GREEN}✓${COLOR_RESET} Claude Code CLI" || { echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} Claude Code CLI (restart terminal)"; }
        [ -d "/Applications/Cursor.app" ] && echo -e "${COLOR_GREEN}✓${COLOR_RESET} Cursor" || { echo -e "${COLOR_RED}✗${COLOR_RESET} Cursor"; ((errors++)) || true; }
        [ -f ~/.cursor/mcp.json ] && echo -e "${COLOR_GREEN}✓${COLOR_RESET} MCP Configs" || { echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} MCP Configs"; }

        echo ""
        if [ $errors -eq 0 ]; then
            echo -e "${COLOR_GREEN}${COLOR_BOLD}Installation complete!${COLOR_RESET}"
        else
            echo -e "${COLOR_YELLOW}Installation complete with $errors warning(s)${COLOR_RESET}"
        fi
        echo ""
        echo "Next steps:"
        echo "  1. Open a new terminal window (to refresh PATH)"
        echo "  2. Open Cursor and sign in"
        echo "  3. Run 'claude' in terminal to authenticate Claude Code CLI"
    fi

    echo ""
    if $AUTO_MODE; then
        sleep 2
    else
        echo "Press any key to exit..."
        read -rsn1 || true
    fi
}

# Non-interactive mode (for piped input)
run_non_interactive() {
    echo -e "${BOLD}${G}=== Install AI Development Environment (non-interactive) ===${N}"
    echo ""

    for i in "${!ITEMS[@]}"; do
        if [ ${INSTALLED[$i]} -eq 0 ]; then
            IFS='|' read -r name check_cmd install_cmd desc <<< "${ITEMS[$i]}"
            echo -e "${COLOR_YELLOW}Installing: ${name}...${COLOR_RESET}"

            if [[ "$install_cmd" == "INSTALL_BREW" ]]; then
                install_brew || warn "Homebrew installation had issues"
            elif [[ "$install_cmd" == "CONFIGURE_MCP" ]]; then
                # Skip MCP config in non-interactive mode
                warn "Skipping MCP configuration (run ./install.sh manually to configure)"
            else
                eval "$install_cmd" 2>&1 || warn "$name installation had issues"
            fi

            setup_brew_path
            hash -r 2>/dev/null || true
            echo -e "${COLOR_GREEN}✓ ${name} done${COLOR_RESET}"
            echo ""
        else
            IFS='|' read -r name check_cmd install_cmd desc <<< "${ITEMS[$i]}"
            echo -e "${COLOR_GREEN}✓ ${name} already installed${COLOR_RESET}"
        fi
    done

    echo ""
    echo -e "${G}${BOLD}Installation complete!${N}"
    echo "Run ./install.sh again to configure MCP secrets."
}

# Auto mode: install all without menu
run_auto_mode() {
    echo -e "${COLOR_BOLD}${COLOR_GREEN}=== Install AI Development Environment ===${COLOR_RESET}"
    echo ""

    # Select all uninstalled items
    for i in "${!SELECTED[@]}"; do
        if [ ${INSTALLED[$i]} -eq 0 ]; then
            SELECTED[$i]=1
        fi
    done

    do_install
}

# Main
if $AUTO_MODE; then
    run_auto_mode
    exit 0
fi

if ! $TUI_SUPPORTED; then
    run_non_interactive
    exit 0
fi

hide_cursor

# Main loop
while true; do
    draw_menu

    read -rsn1 key 2>/dev/null || { run_non_interactive; exit 0; }

    case "$key" in
        A|k) ((CURRENT > MIN_POS)) && ((CURRENT--)) || true ;;
        B|j) ((CURRENT < TOTAL - 1)) && ((CURRENT++)) || true ;;
        ' ') toggle_current ;;
        a) select_all 1 ;;
        n) select_all 0 ;;
        q)
            echo ""
            echo -e "${COLOR_DIM}Cancelled${COLOR_RESET}"
            exit 0
            ;;
        '')
            # Count selected
            count=0
            for i in "${!SELECTED[@]}"; do
                if [ ${SELECTED[$i]} -eq 1 ] && [ ${INSTALLED[$i]} -eq 0 ]; then
                    ((count++)) || true
                fi
            done

            if [ $count -eq 0 ]; then
                continue
            fi

            echo ""
            echo -e "${COLOR_GREEN}Install $count item(s)? [Y/n]${COLOR_RESET} "
            read -rsn1 confirm || confirm="y"
            if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
                do_install
                exit 0
            fi
            ;;
        $'\x1b')
            read -rsn2 arrow 2>/dev/null || true
            case "$arrow" in
                '[A') ((CURRENT > MIN_POS)) && ((CURRENT--)) || true ;;
                '[B') ((CURRENT < TOTAL - 1)) && ((CURRENT++)) || true ;;
            esac
            ;;
    esac
done
