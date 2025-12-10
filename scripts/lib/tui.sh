#!/usr/bin/env bash
# TUI (Text User Interface) Menu Library
# Reusable menu system for interactive shell scripts
# Source this file after common.sh

# shellcheck disable=SC2155

# Check if common.sh is loaded (use +x to check if SET, not if non-empty)
if [ -z "${COLOR_GREEN+x}" ]; then
    _TUI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$_TUI_DIR/common.sh"
fi

# ============================================================================
# MENU STATE MANAGEMENT
# ============================================================================

# Global menu state (set by calling script)
# Note: Using simple assignment for bash 3.x compatibility (declare -g requires bash 4.2+)
TUI_CURRENT=0      # Current cursor position
TUI_TOTAL=0        # Total number of items
TUI_MIN_POS=-2     # Minimum position (-2=Deselect All, -1=Select All)

# Arrays (must be declared by calling script)
# TUI_ITEMS=()      # Array of items: "name|field2|field3|..."
# TUI_SELECTED=()   # Selection state: 1=selected, 0=not selected
# TUI_INSTALLED=()  # Optional: Install state: 1=installed, 0=not installed

# Menu configuration (set by calling script)
TUI_TITLE=""           # Menu title
TUI_INSTRUCTIONS=""    # Menu instructions
TUI_TITLE_COLOR="${COLOR_GREEN}"  # Title color (default green)
TUI_CHECKBOX_SELECTED="${COLOR_YELLOW}[x]${COLOR_RESET}"  # Selected checkbox
TUI_CHECKBOX_EMPTY="[ ]"  # Empty checkbox

# ============================================================================
# MENU DRAWING FUNCTIONS
# ============================================================================

# Draw the menu
# Usage: tui_draw_menu [custom_item_renderer]
#   custom_item_renderer: Optional function name to call for each item
#                        Function receives: index, name, remaining_fields
tui_draw_menu() {
    local item_renderer="${1:-tui_default_item_renderer}"

    clear 2>/dev/null || printf '\033[2J\033[H'

    # Draw title
    echo -e "${COLOR_BOLD}${TUI_TITLE_COLOR}${TUI_TITLE}${COLOR_RESET}"

    # Draw instructions
    if [ -n "$TUI_INSTRUCTIONS" ]; then
        echo -e "${COLOR_DIM}${TUI_INSTRUCTIONS}${COLOR_RESET}"
    fi
    echo ""

    # Draw Select All option
    if [ $TUI_CURRENT -eq -1 ]; then
        echo -e " ${COLOR_BOLD}> [${COLOR_GREEN}Select All${COLOR_RESET}${COLOR_BOLD}]${COLOR_RESET}"
    else
        echo -e "   [${COLOR_DIM}Select All${COLOR_RESET}]"
    fi

    # Draw Deselect All option
    if [ $TUI_CURRENT -eq -2 ]; then
        echo -e " ${COLOR_BOLD}> [${COLOR_RED}Deselect All${COLOR_RESET}${COLOR_BOLD}]${COLOR_RESET}"
    else
        echo -e "   [${COLOR_DIM}Deselect All${COLOR_RESET}]"
    fi

    echo ""

    # Draw items using custom renderer
    for i in "${!TUI_ITEMS[@]}"; do
        "$item_renderer" "$i"
    done

    echo ""

    # Draw footer with selection count
    tui_draw_footer
}

# Default item renderer (can be overridden)
# Arguments: index
tui_default_item_renderer() {
    local i=$1
    local item="${TUI_ITEMS[$i]}"

    # Parse first field as name
    local name
    name=$(echo "$item" | cut -d'|' -f1)

    # Cursor indicator
    local cursor=" "
    local line_color=""
    if [ "$i" -eq "$TUI_CURRENT" ]; then
        cursor=">"
        line_color="${COLOR_BOLD}"
    fi

    # Checkbox
    local checkbox="$TUI_CHECKBOX_EMPTY"
    if [ "${TUI_SELECTED[$i]}" -eq 1 ]; then
        checkbox="$TUI_CHECKBOX_SELECTED"
    fi

    echo -e " ${line_color}${cursor} ${checkbox} ${name}${COLOR_RESET}"
}

# Draw footer with selection count
tui_draw_footer() {
    local count=0

    # Count selected items
    for s in "${TUI_SELECTED[@]}"; do
        ((count += s)) || true
    done

    if [ $count -gt 0 ]; then
        echo -e "${COLOR_YELLOW}$count item(s) selected${COLOR_RESET}"
    else
        echo -e "${COLOR_DIM}No items selected${COLOR_RESET}"
    fi
}

# ============================================================================
# MENU INTERACTION FUNCTIONS
# ============================================================================

# Toggle current item selection
tui_toggle_current() {
    if [ $TUI_CURRENT -eq -1 ]; then
        # Select All
        tui_select_all 1
    elif [ $TUI_CURRENT -eq -2 ]; then
        # Deselect All
        tui_select_all 0
    else
        # Toggle individual item
        if [ "${TUI_SELECTED[$TUI_CURRENT]}" -eq 1 ]; then
            TUI_SELECTED[$TUI_CURRENT]=0
        else
            TUI_SELECTED[$TUI_CURRENT]=1
        fi
    fi
}

# Toggle current item (with installed check)
# Only toggles if item is not installed
tui_toggle_current_uninstalled() {
    if [ $TUI_CURRENT -eq -1 ]; then
        # Select All
        tui_select_all_uninstalled 1
    elif [ $TUI_CURRENT -eq -2 ]; then
        # Deselect All
        tui_select_all_uninstalled 0
    elif [ "${TUI_INSTALLED[$TUI_CURRENT]}" -eq 0 ]; then
        # Toggle only if not installed
        if [ "${TUI_SELECTED[$TUI_CURRENT]}" -eq 1 ]; then
            TUI_SELECTED[$TUI_CURRENT]=0
        else
            TUI_SELECTED[$TUI_CURRENT]=1
        fi
    fi
}

# Select or deselect all items
# Arguments: value (1=select, 0=deselect)
tui_select_all() {
    local val=$1
    for i in "${!TUI_SELECTED[@]}"; do
        TUI_SELECTED[$i]=$val
    done
}

# Select or deselect all uninstalled items
# Arguments: value (1=select, 0=deselect)
tui_select_all_uninstalled() {
    local val=$1
    for i in "${!TUI_SELECTED[@]}"; do
        if [ "${TUI_INSTALLED[$i]}" -eq 0 ]; then
            TUI_SELECTED[$i]=$val
        fi
    done
}

# Move cursor up
tui_move_up() {
    ((TUI_CURRENT > TUI_MIN_POS)) && ((TUI_CURRENT--)) || true
}

# Move cursor down
tui_move_down() {
    ((TUI_CURRENT < TUI_TOTAL - 1)) && ((TUI_CURRENT++)) || true
}

# ============================================================================
# MENU EVENT LOOP
# ============================================================================

# Main menu event loop
# Arguments:
#   $1: draw_function - Function to call to draw menu (default: tui_draw_menu)
#   $2: toggle_function - Function to call on toggle (default: tui_toggle_current)
#   $3: confirm_callback - Function to call on Enter (receives selected count)
# Returns: 0 on confirm, 1 on quit
tui_run_menu_loop() {
    local draw_func="${1:-tui_draw_menu}"
    local toggle_func="${2:-tui_toggle_current}"
    local confirm_callback="${3:-}"

    hide_cursor
    trap 'show_cursor; echo' EXIT

    while true; do
        "$draw_func"

        # Read single keypress
        read -rsn1 key 2>/dev/null || return 1

        case "$key" in
            A|k)
                # Up arrow or k (vim)
                tui_move_up
                ;;
            B|j)
                # Down arrow or j (vim)
                tui_move_down
                ;;
            ' ')
                # Space - toggle
                "$toggle_func"
                ;;
            a)
                # Select all
                if [ -n "${TUI_INSTALLED+x}" ]; then
                    tui_select_all_uninstalled 1
                else
                    tui_select_all 1
                fi
                ;;
            n)
                # Deselect all
                if [ -n "${TUI_INSTALLED+x}" ]; then
                    tui_select_all_uninstalled 0
                else
                    tui_select_all 0
                fi
                ;;
            q)
                # Quit
                echo ""
                echo -e "${COLOR_DIM}Cancelled${COLOR_RESET}"
                return 1
                ;;
            '')
                # Enter - confirm
                local count=0
                for s in "${TUI_SELECTED[@]}"; do
                    ((count += s)) || true
                done

                if [ $count -eq 0 ]; then
                    continue
                fi

                # Call confirm callback if provided
                if [ -n "$confirm_callback" ]; then
                    "$confirm_callback" "$count" && return 0 || continue
                else
                    return 0
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
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Initialize TUI with items array
# Arguments: items_array_name
tui_init() {
    local items_ref=$1

    # Get array length using eval for bash 3.x compatibility
    eval "TUI_TOTAL=\${#${items_ref}[@]}"
    TUI_CURRENT=0
    TUI_MIN_POS=-2
}

# Count selected items
tui_count_selected() {
    local count=0
    for s in "${TUI_SELECTED[@]}"; do
        ((count += s)) || true
    done
    echo "$count"
}

# Count selected uninstalled items
tui_count_selected_uninstalled() {
    local count=0
    for i in "${!TUI_SELECTED[@]}"; do
        if [ "${TUI_SELECTED[$i]}" -eq 1 ] && [ "${TUI_INSTALLED[$i]}" -eq 0 ]; then
            ((count++)) || true
        fi
    done
    echo "$count"
}
