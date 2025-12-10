#!/bin/bash
# Interactive installation script for AI development environment
# Navigate with arrow keys, space to toggle, enter to confirm
# Use --auto flag to install all without menu (still prompts for MCP secrets)
set -e

# Load common functions and modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/scripts/lib/common.sh"
source "$SCRIPT_DIR/scripts/lib/tui.sh"
source "$SCRIPT_DIR/scripts/lib/installation.sh"
source "$SCRIPT_DIR/scripts/lib/mcp.sh"

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
TUI_ITEMS=(
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
declare -a TUI_SELECTED
declare -a TUI_INSTALLED

# Check what's already installed
check_installed() {
    for i in "${!TUI_ITEMS[@]}"; do
        IFS='|' read -r name check_cmd install_cmd desc <<< "${TUI_ITEMS[$i]}"
        if [[ "$check_cmd" == "ALWAYS_INSTALL" ]]; then
            TUI_INSTALLED[$i]=0
            TUI_SELECTED[$i]=1
        elif eval "$check_cmd" &>/dev/null; then
            TUI_INSTALLED[$i]=1
            TUI_SELECTED[$i]=0
        else
            TUI_INSTALLED[$i]=0
            TUI_SELECTED[$i]=1
        fi
    done
}

check_installed

# Initialize TUI state
tui_init TUI_ITEMS
TUI_TITLE="=== Install AI Development Environment ==="
TUI_INSTRUCTIONS="↑↓ navigate | Space toggle | a=all | n=none | Enter confirm | q=quit"
TUI_TITLE_COLOR="${COLOR_GREEN}"

trap 'show_cursor; echo' EXIT

# Custom item renderer for install menu
install_item_renderer() {
    local i=$1
    IFS='|' read -r name check_cmd install_cmd desc <<< "${TUI_ITEMS[$i]}"

    # Cursor indicator
    local cursor=" "
    local line_color=""
    if [ "$i" -eq "$TUI_CURRENT" ]; then
        cursor=">"
        line_color="${COLOR_BOLD}"
    fi

    # Checkbox and status
    local checkbox status
    if [ "${TUI_INSTALLED[$i]}" -eq 1 ]; then
        checkbox="${COLOR_GREEN}[✓]${COLOR_RESET}"
        status="${COLOR_DIM}(installed)${COLOR_RESET}"
    elif [ "${TUI_SELECTED[$i]}" -eq 1 ]; then
        checkbox="${COLOR_YELLOW}[x]${COLOR_RESET}"
        status=""
    else
        checkbox="[ ]"
        status=""
    fi

    echo -e " ${line_color}${cursor} ${checkbox} ${name}${COLOR_RESET} ${COLOR_DIM}- ${desc}${COLOR_RESET} ${status}"
}

# Custom footer for install menu
install_draw_footer() {
    # Count selected (not already installed)
    local count=0
    for i in "${!TUI_SELECTED[@]}"; do
        if [ "${TUI_SELECTED[$i]}" -eq 1 ] && [ "${TUI_INSTALLED[$i]}" -eq 0 ]; then
            ((count++)) || true
        fi
    done

    if [ $count -gt 0 ]; then
        echo -e "${COLOR_YELLOW}$count item(s) selected for installation${COLOR_RESET}"
    else
        echo -e "${COLOR_GREEN}Everything is already installed!${COLOR_RESET}"
    fi
}

# Draw menu wrapper
draw_menu() {
    if ! $TUI_SUPPORTED; then
        return
    fi

    clear 2>/dev/null || printf '\033[2J\033[H'
    echo -e "${COLOR_BOLD}${TUI_TITLE_COLOR}${TUI_TITLE}${COLOR_RESET}"
    echo -e "${COLOR_DIM}${TUI_INSTRUCTIONS}${COLOR_RESET}"
    echo ""

    # Select All option
    if [ $TUI_CURRENT -eq -1 ]; then
        echo -e " ${COLOR_BOLD}> [${COLOR_GREEN}Select All${COLOR_RESET}${COLOR_BOLD}]${COLOR_RESET}"
    else
        echo -e "   [${COLOR_DIM}Select All${COLOR_RESET}]"
    fi

    # Deselect All option
    if [ $TUI_CURRENT -eq -2 ]; then
        echo -e " ${COLOR_BOLD}> [${COLOR_RED}Deselect All${COLOR_RESET}${COLOR_BOLD}]${COLOR_RESET}"
    else
        echo -e "   [${COLOR_DIM}Deselect All${COLOR_RESET}]"
    fi

    echo ""

    # Draw items
    for i in "${!TUI_ITEMS[@]}"; do
        install_item_renderer "$i"
    done

    echo ""
    install_draw_footer
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
        A|k) tui_move_up ;;
        B|j) tui_move_down ;;
        ' ') tui_toggle_current_uninstalled ;;
        a) tui_select_all_uninstalled 1 ;;
        n) tui_select_all_uninstalled 0 ;;
        q)
            echo ""
            echo -e "${COLOR_DIM}Cancelled${COLOR_RESET}"
            exit 0
            ;;
        '')
            # Count selected
            count=$(tui_count_selected_uninstalled)

            if [ "$count" -eq 0 ]; then
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
                '[A') tui_move_up ;;
                '[B') tui_move_down ;;
            esac
            ;;
    esac
done
