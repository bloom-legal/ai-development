#!/bin/bash
# Interactive installation script for AI development environment
# Navigate with arrow keys, space to toggle, enter to confirm
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors (with fallback for non-color terminals)
if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
    R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m' N='\033[0m'
    DIM='\033[2m' BOLD='\033[1m'
else
    R='' G='' Y='' B='' N='' DIM='' BOLD=''
fi

log() { echo -e "${G}✓ $1${N}"; }
warn() { echo -e "${Y}⚠ $1${N}"; }
error() { echo -e "${R}✗ $1${N}"; }

# Check if terminal supports TUI
TUI_SUPPORTED=true
if [[ ! -t 0 ]] || [[ ! -t 1 ]] || ! command -v tput &>/dev/null; then
    TUI_SUPPORTED=false
fi

# Setup brew PATH
setup_brew_path() {
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        export PATH="/opt/homebrew/bin:$PATH"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
        export PATH="/usr/local/bin:$PATH"
    fi
}

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

# Hide cursor (with error handling)
hide_cursor() {
    if $TUI_SUPPORTED; then
        tput civis 2>/dev/null || true
    fi
}

show_cursor() {
    if $TUI_SUPPORTED; then
        tput cnorm 2>/dev/null || true
    fi
}

trap 'show_cursor; echo' EXIT

# Draw the menu
draw_menu() {
    if ! $TUI_SUPPORTED; then
        return
    fi

    clear 2>/dev/null || printf '\033[2J\033[H'
    echo -e "${BOLD}${G}=== Install AI Development Environment ===${N}"
    echo -e "${DIM}↑↓ navigate | Space toggle | a=all | n=none | Enter confirm | q=quit${N}"
    echo ""

    # Select All option
    if [ $CURRENT -eq -1 ]; then
        echo -e " ${BOLD}> [${G}Select All${N}${BOLD}]${N}"
    else
        echo -e "   [${DIM}Select All${N}]"
    fi

    # Deselect All option
    if [ $CURRENT -eq -2 ]; then
        echo -e " ${BOLD}> [${R}Deselect All${N}${BOLD}]${N}"
    else
        echo -e "   [${DIM}Deselect All${N}]"
    fi

    echo ""

    for i in "${!ITEMS[@]}"; do
        IFS='|' read -r name check_cmd install_cmd desc <<< "${ITEMS[$i]}"

        # Cursor indicator
        if [ $i -eq $CURRENT ]; then
            cursor=">"
            line_color="${BOLD}"
        else
            cursor=" "
            line_color=""
        fi

        # Checkbox and status
        if [ ${INSTALLED[$i]} -eq 1 ]; then
            checkbox="${G}[✓]${N}"
            status="${DIM}(installed)${N}"
        elif [ ${SELECTED[$i]} -eq 1 ]; then
            checkbox="${Y}[x]${N}"
            status=""
        else
            checkbox="[ ]"
            status=""
        fi

        echo -e " ${line_color}${cursor} ${checkbox} ${name}${N} ${DIM}- ${desc}${N} ${status}"
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
        echo -e "${Y}$count item(s) selected for installation${N}"
    else
        echo -e "${G}Everything is already installed!${N}"
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

    # Create directories
    mkdir -p ~/.cursor 2>/dev/null || true
    mkdir -p ~/.claude/commands 2>/dev/null || true
    mkdir -p ~/Library/Application\ Support/Claude 2>/dev/null || true
    mkdir -p ~/Library/Application\ Support/Cursor/User/globalStorage/rooveterinaryinc.roo-code-nightly/settings 2>/dev/null || true
    mkdir -p ~/Development 2>/dev/null || true

    # Load existing .env
    if [ -f "$ENV_FILE" ]; then
        set -a
        source "$ENV_FILE" 2>/dev/null || true
        set +a
    fi

    echo ""
    echo -e "${B}Configure MCP server secrets (press Enter to skip/keep current):${N}"
    echo ""

    # PostgreSQL
    current_pg="${POSTGRES_CONNECTION:-}"
    printf "PostgreSQL connection [user:pass@host:port/db]"
    [ -n "$current_pg" ] && printf " (current: %s...)" "${current_pg:0:20}"
    printf ": "
    read -r input_pg || input_pg=""
    [ -n "$input_pg" ] && POSTGRES_CONNECTION="$input_pg"

    # Portainer Server
    current_server="${PORTAINER_SERVER:-}"
    printf "Portainer server hostname"
    [ -n "$current_server" ] && printf " (current: %s)" "$current_server"
    printf ": "
    read -r input_server || input_server=""
    [ -n "$input_server" ] && PORTAINER_SERVER="$input_server"

    # Portainer Token
    current_token="${PORTAINER_TOKEN:-}"
    printf "Portainer API token"
    [ -n "$current_token" ] && printf " (current: %s...)" "${current_token:0:10}"
    printf ": "
    read -r input_token || input_token=""
    [ -n "$input_token" ] && PORTAINER_TOKEN="$input_token"

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

    # Sync
    SKIP_PREFLIGHT=1 "$SCRIPT_DIR/sync-rules.sh" mcp 2>/dev/null || warn "MCP sync had warnings"
}

# Execute installation
do_install() {
    show_cursor
    clear 2>/dev/null || printf '\033[2J\033[H'
    echo -e "${BOLD}${G}=== Installing ===${N}"
    echo ""

    local any_selected=0
    for i in "${!ITEMS[@]}"; do
        if [ ${SELECTED[$i]} -eq 1 ] && [ ${INSTALLED[$i]} -eq 0 ]; then
            any_selected=1
            IFS='|' read -r name check_cmd install_cmd desc <<< "${ITEMS[$i]}"
            echo -e "${Y}Installing: ${name}...${N}"

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

            echo -e "${G}✓ ${name} done${N}"
            echo ""
        fi
    done

    if [ $any_selected -eq 0 ]; then
        echo -e "${G}Nothing to install - everything is already set up!${N}"
    else
        echo -e "${G}${BOLD}Installation complete!${N}"
        echo ""
        echo "Next steps:"
        echo "  1. Open a new terminal window (to refresh PATH)"
        echo "  2. Open Cursor and sign in"
        echo "  3. Run 'claude' in terminal to authenticate Claude Code CLI"
    fi

    echo ""
    echo "Press any key to exit..."
    read -rsn1 || true
}

# Non-interactive mode (for piped input)
run_non_interactive() {
    echo -e "${BOLD}${G}=== Install AI Development Environment (non-interactive) ===${N}"
    echo ""

    for i in "${!ITEMS[@]}"; do
        if [ ${INSTALLED[$i]} -eq 0 ]; then
            IFS='|' read -r name check_cmd install_cmd desc <<< "${ITEMS[$i]}"
            echo -e "${Y}Installing: ${name}...${N}"

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
            echo -e "${G}✓ ${name} done${N}"
            echo ""
        else
            IFS='|' read -r name check_cmd install_cmd desc <<< "${ITEMS[$i]}"
            echo -e "${G}✓ ${name} already installed${N}"
        fi
    done

    echo ""
    echo -e "${G}${BOLD}Installation complete!${N}"
    echo "Run ./install.sh again to configure MCP secrets."
}

# Main
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
            echo -e "${DIM}Cancelled${N}"
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
            echo -e "${G}Install $count item(s)? [Y/n]${N} "
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
