#!/bin/bash
# Interactive uninstall script for AI development environment
# Navigate with arrow keys, space to toggle, enter to confirm
set -e

# Colors
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m' N='\033[0m'
DIM='\033[2m' BOLD='\033[1m'

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
    "This Repository|rm -rf ~/Development/global|AI development scripts"
)

# Selection state (1=selected, 0=not selected)
declare -a SELECTED
for i in "${!ITEMS[@]}"; do
    SELECTED[$i]=0
done

CURRENT=0
TOTAL=${#ITEMS[@]}

# Hide cursor
tput civis
trap 'tput cnorm; echo' EXIT

# Draw the menu
draw_menu() {
    clear
    echo -e "${BOLD}${R}=== Uninstall AI Development Environment ===${N}"
    echo -e "${DIM}Use ↑↓ to navigate, Space to toggle, Enter to confirm, q to quit${N}"
    echo ""

    for i in "${!ITEMS[@]}"; do
        IFS='|' read -r name cmd desc <<< "${ITEMS[$i]}"

        # Cursor indicator
        if [ $i -eq $CURRENT ]; then
            cursor=">"
            line_color="${BOLD}"
        else
            cursor=" "
            line_color=""
        fi

        # Checkbox
        if [ ${SELECTED[$i]} -eq 1 ]; then
            checkbox="${R}[x]${N}"
        else
            checkbox="[ ]"
        fi

        echo -e " ${line_color}${cursor} ${checkbox} ${name}${N} ${DIM}- ${desc}${N}"
    done

    echo ""

    # Count selected
    count=0
    for s in "${SELECTED[@]}"; do
        ((count += s))
    done

    if [ $count -gt 0 ]; then
        echo -e "${Y}$count item(s) selected for removal${N}"
    else
        echo -e "${DIM}No items selected${N}"
    fi
}

# Toggle current item
toggle_current() {
    if [ ${SELECTED[$CURRENT]} -eq 1 ]; then
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
    echo -e "${BOLD}${R}=== Uninstalling ===${N}"
    echo ""

    local any_selected=0
    for i in "${!ITEMS[@]}"; do
        if [ ${SELECTED[$i]} -eq 1 ]; then
            any_selected=1
            IFS='|' read -r name cmd desc <<< "${ITEMS[$i]}"
            echo -e "${Y}Removing: ${name}...${N}"
            eval "$cmd" 2>/dev/null || echo -e "${DIM}  (already removed or failed)${N}"
            echo -e "${G}✓ ${name} removed${N}"
            echo ""
        fi
    done

    if [ $any_selected -eq 0 ]; then
        echo -e "${DIM}Nothing selected to uninstall${N}"
    else
        echo -e "${G}${BOLD}Uninstall complete!${N}"
    fi

    echo ""
    echo "Press any key to exit..."
    read -rsn1
}

# Main loop
while true; do
    draw_menu

    # Read single keypress
    read -rsn1 key

    case "$key" in
        A|k) # Up arrow or k
            ((CURRENT > 0)) && ((CURRENT--))
            ;;
        B|j) # Down arrow or j
            ((CURRENT < TOTAL - 1)) && ((CURRENT++))
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
            echo -e "${DIM}Cancelled${N}"
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
            echo -e "${R}${BOLD}Are you sure you want to uninstall $any item(s)? [y/N]${N} "
            read -rsn1 confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                do_uninstall
                exit 0
            fi
            ;;
        $'\x1b') # Escape sequence (arrow keys)
            read -rsn2 arrow
            case "$arrow" in
                '[A') ((CURRENT > 0)) && ((CURRENT--)) ;;
                '[B') ((CURRENT < TOTAL - 1)) && ((CURRENT++)) ;;
            esac
            ;;
    esac
done
