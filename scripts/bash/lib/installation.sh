#!/usr/bin/env bash
# Installation module - Package installation functions
# Source this file: source "$(dirname "${BASH_SOURCE[0]}")/lib/installation.sh"

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/scripts/bash/lib/common.sh"

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
    echo -e "${COLOR_BOLD}${COLOR_GREEN}=== Install AI Development Environment (non-interactive) ===${COLOR_RESET}"
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
    echo -e "${COLOR_GREEN}${COLOR_BOLD}Installation complete!${COLOR_RESET}"
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
