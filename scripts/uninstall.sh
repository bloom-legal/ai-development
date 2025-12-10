#!/bin/bash
# Interactive uninstall script for AI development environment
# Navigate with arrow keys, space to toggle, enter to confirm
set -e

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/lib/common.sh"
source "$SCRIPT_DIR/scripts/lib/tui.sh"

# Check if terminal supports TUI
if check_tui_support; then
    TUI_SUPPORTED=true
else
    TUI_SUPPORTED=false
fi

# Items to uninstall: "name|command|description"
TUI_ITEMS=(
    "Claude Code CLI|npm uninstall -g @anthropic-ai/claude-code|Terminal AI assistant"
    "Cursor App|brew uninstall --cask cursor|AI-powered editor"
    "VS Code App|brew uninstall --cask visual-studio-code|Code editor"
    "Node.js|brew uninstall node|JavaScript runtime"
    "jq|brew uninstall jq|JSON processor"
    "uv|brew uninstall uv|Python package manager"
    "MCP Configs|rm -f ~/.cursor/mcp.json \"$HOME/Library/Application Support/Claude/claude_desktop_config.json\" \"$HOME/Library/Application Support/Cursor/User/globalStorage/rooveterinaryinc.roo-code-nightly/settings/mcp_settings.json\"|Global MCP configurations"
    "Claude Commands|rm -rf ~/.claude/commands|Claude Code custom commands"
    "This Repository|rm -rf \"$(get_dev_folder)/global\"|AI development scripts"
)

# Selection state (1=selected, 0=not selected)
declare -a TUI_SELECTED
for i in "${!TUI_ITEMS[@]}"; do
    TUI_SELECTED[$i]=0
done

# Initialize TUI state
tui_init TUI_ITEMS
TUI_TITLE="=== Uninstall AI Development Environment ==="
TUI_INSTRUCTIONS="↑↓ navigate | Space toggle | a=all | n=none | Enter confirm | q=quit"
TUI_TITLE_COLOR="${COLOR_RED}"
TUI_CHECKBOX_SELECTED="${COLOR_RED}[x]${COLOR_RESET}"

trap 'show_cursor; echo' EXIT

# Custom item renderer for uninstall menu
uninstall_item_renderer() {
    local i=$1
    IFS='|' read -r name cmd desc <<< "${TUI_ITEMS[$i]}"

    # Cursor indicator
    local cursor=" "
    local line_color=""
    if [ "$i" -eq "$TUI_CURRENT" ]; then
        cursor=">"
        line_color="${COLOR_BOLD}"
    fi

    # Checkbox
    local checkbox="[ ]"
    if [ "${TUI_SELECTED[$i]}" -eq 1 ]; then
        checkbox="${TUI_CHECKBOX_SELECTED}"
    fi

    echo -e " ${line_color}${cursor} ${checkbox} ${name}${COLOR_RESET} ${COLOR_DIM}- ${desc}${COLOR_RESET}"
}

# Draw menu wrapper
draw_menu() {
    clear
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
        uninstall_item_renderer "$i"
    done

    echo ""

    # Count selected
    local count
    count=$(tui_count_selected)

    if [ "$count" -gt 0 ]; then
        echo -e "${COLOR_YELLOW}$count item(s) selected for removal${COLOR_RESET}"
    else
        echo -e "${COLOR_DIM}No items selected${COLOR_RESET}"
    fi
}

# Execute uninstall
do_uninstall() {
    clear
    echo -e "${COLOR_BOLD}${COLOR_RED}=== Uninstalling ===${COLOR_RESET}"
    echo ""

    local any_selected=0
    for i in "${!TUI_ITEMS[@]}"; do
        if [ "${TUI_SELECTED[$i]}" -eq 1 ]; then
            any_selected=1
            IFS='|' read -r name cmd desc <<< "${TUI_ITEMS[$i]}"
            echo -e "${COLOR_YELLOW}Removing: ${name}...${COLOR_RESET}"
            eval "$cmd" 2>/dev/null || echo -e "${COLOR_DIM}  (already removed or failed)${COLOR_RESET}"
            echo -e "${COLOR_GREEN}✓ ${name} removed${COLOR_RESET}"
            echo ""
        fi
    done

    if [ $any_selected -eq 0 ]; then
        echo -e "${COLOR_DIM}Nothing selected to uninstall${COLOR_RESET}"
    else
        echo -e "${COLOR_GREEN}${COLOR_BOLD}Uninstall complete!${COLOR_RESET}"
    fi

    echo ""
    echo "Press any key to exit..."
    read -rsn1
}

# Non-interactive list mode
run_list_mode() {
    echo -e "${COLOR_BOLD}${COLOR_RED}=== Uninstall AI Development Environment ===${COLOR_RESET}"
    echo ""
    echo "Installed components:"
    echo ""

    for i in "${!TUI_ITEMS[@]}"; do
        IFS='|' read -r name cmd desc <<< "${TUI_ITEMS[$i]}"
        echo "  $((i+1)). $name - $desc"
    done

    echo ""
    echo "Run ./uninstall.sh in an interactive terminal to select items to remove."
}

# Main
if ! $TUI_SUPPORTED; then
    run_list_mode
    exit 0
fi

hide_cursor

# Main loop
while true; do
    draw_menu

    # Read single keypress
    read -rsn1 key 2>/dev/null || { run_list_mode; exit 0; }

    case "$key" in
        A|k)
            # Up arrow or k
            tui_move_up
            ;;
        B|j)
            # Down arrow or j
            tui_move_down
            ;;
        ' ')
            # Space - toggle
            tui_toggle_current
            ;;
        a)
            # Select all
            tui_select_all 1
            ;;
        n)
            # Deselect all
            tui_select_all 0
            ;;
        q)
            # Quit
            echo ""
            echo -e "${COLOR_DIM}Cancelled${COLOR_RESET}"
            exit 0
            ;;
        '')
            # Enter - confirm
            count=$(tui_count_selected)

            if [ "$count" -eq 0 ]; then
                continue
            fi

            # Confirm
            echo ""
            echo -e "${COLOR_RED}${COLOR_BOLD}Are you sure you want to uninstall $count item(s)? [y/N]${COLOR_RESET} "
            read -rsn1 confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                do_uninstall
                exit 0
            fi
            ;;
        $'\x1b')
            # Escape sequence (arrow keys)
            read -rsn2 arrow 2>/dev/null || true
            case "$arrow" in
                '[A') tui_move_up ;;
                '[B') tui_move_down ;;
            esac
            ;;
    esac
done
