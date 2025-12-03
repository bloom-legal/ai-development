#!/bin/bash
# Interactive uninstall script for AI development environment
# Navigate with arrow keys, space to toggle, enter to confirm
set -e

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/bash/lib/common.sh"

# Check if terminal supports TUI
if check_tui_support; then
    TUI_SUPPORTED=true
else
    TUI_SUPPORTED=false
fi

# Items to uninstall: "name|command|description"
ITEMS=(
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
declare -a SELECTED
for i in "${!ITEMS[@]}"; do
    SELECTED[$i]=0
done

CURRENT=0
TOTAL=${#ITEMS[@]}
MIN_POS=-2  # -2=Deselect All, -1=Select All, 0+=items

# Use cursor functions from common library

trap 'show_cursor; echo' EXIT

# Draw the menu
draw_menu() {
    clear
    echo -e "${COLOR_BOLD}${COLOR_RED}=== Uninstall AI Development Environment ===${COLOR_RESET}"
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
        IFS='|' read -r name cmd desc <<< "${ITEMS[$i]}"

        # Cursor indicator
        if [ $i -eq $CURRENT ]; then
            cursor=">"
            line_color="${COLOR_BOLD}"
        else
            cursor=" "
            line_color=""
        fi

        # Checkbox
        if [ ${SELECTED[$i]} -eq 1 ]; then
            checkbox="${COLOR_RED}[x]${COLOR_RESET}"
        else
            checkbox="[ ]"
        fi

        echo -e " ${line_color}${cursor} ${checkbox} ${name}${COLOR_RESET} ${COLOR_DIM}- ${desc}${COLOR_RESET}"
    done

    echo ""

    # Count selected
    count=0
    for s in "${SELECTED[@]}"; do
        ((count += s))
    done

    if [ $count -gt 0 ]; then
        echo -e "${COLOR_YELLOW}$count item(s) selected for removal${COLOR_RESET}"
    else
        echo -e "${COLOR_DIM}No items selected${COLOR_RESET}"
    fi
}

# Toggle current item
toggle_current() {
    if [ $CURRENT -eq -1 ]; then
        # Select All
        select_all 1
    elif [ $CURRENT -eq -2 ]; then
        # Deselect All
        select_all 0
    elif [ ${SELECTED[$CURRENT]} -eq 1 ]; then
        SELECTED[$CURRENT]=0
    else
        SELECTED[$CURRENT]=1
    fi
}

# Select/deselect all
select_all() {
    local val=$1
    for i in "${!SELECTED[@]}"; do
        SELECTED[$i]=$val
    done
}

# Execute uninstall
do_uninstall() {
    clear
    echo -e "${COLOR_BOLD}${COLOR_RED}=== Uninstalling ===${COLOR_RESET}"
    echo ""

    local any_selected=0
    for i in "${!ITEMS[@]}"; do
        if [ ${SELECTED[$i]} -eq 1 ]; then
            any_selected=1
            IFS='|' read -r name cmd desc <<< "${ITEMS[$i]}"
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

    for i in "${!ITEMS[@]}"; do
        IFS='|' read -r name cmd desc <<< "${ITEMS[$i]}"
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
        A|k) # Up arrow or k
            ((CURRENT > MIN_POS)) && ((CURRENT--)) || true
            ;;
        B|j) # Down arrow or j
            ((CURRENT < TOTAL - 1)) && ((CURRENT++)) || true
            ;;
        ' ') # Space - toggle
            toggle_current
            ;;
        a) # Select all
            select_all 1
            ;;
        n) # Deselect all
            select_all 0
            ;;
        q) # Quit
            echo ""
            echo -e "${COLOR_DIM}Cancelled${COLOR_RESET}"
            exit 0
            ;;
        '') # Enter - confirm
            # Check if anything selected
            any=0
            for s in "${SELECTED[@]}"; do
                ((any += s))
            done

            if [ $any -eq 0 ]; then
                continue
            fi

            # Confirm
            echo ""
            echo -e "${COLOR_RED}${COLOR_BOLD}Are you sure you want to uninstall $any item(s)? [y/N]${COLOR_RESET} "
            read -rsn1 confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                do_uninstall
                exit 0
            fi
            ;;
        $'\x1b') # Escape sequence (arrow keys)
            read -rsn2 arrow 2>/dev/null || true
            case "$arrow" in
                '[A') ((CURRENT > MIN_POS)) && ((CURRENT--)) || true ;;
                '[B') ((CURRENT < TOTAL - 1)) && ((CURRENT++)) || true ;;
            esac
            ;;
    esac
done
