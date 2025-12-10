#!/bin/bash
# Sync global AI development configs
# GLOBAL ONLY - no per-project sync needed
# Usage: ./sync-rules.sh [sync|mcp|speckit]
set -e

# Load common functions and modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/scripts/lib/common.sh"
# shellcheck source=scripts/lib/mcp.sh
source "$SCRIPT_DIR/scripts/lib/mcp.sh"
# shellcheck source=scripts/lib/building-blocks.sh
source "$SCRIPT_DIR/scripts/lib/building-blocks.sh"

# Config
export TEMPLATE_DIR="$SCRIPT_DIR/template"

# ============================================================================
# MAIN
# ============================================================================

header "=== Global Sync ==="
echo ""
echo "Syncs to:"
echo "  ~/.claude/          Commands, hooks, agents, CLAUDE.md"
echo "  ~/.cursor/mcp.json  MCP servers"
echo "  ~/.claude.json      Claude Code MCP"
echo ""

action="${1:-sync}"

case "$action" in
    sync)
        # Full global sync
        sync_global_mcps
        sync_global_claude_md
        sync_global_claude_config
        echo ""
        header "Done! All global configs synced."
        echo ""
        echo "For Cursor: Paste CLAUDE.md content into Settings → Rules → User Rules"
        ;;

    mcp)
        # MCP and CLAUDE.md only
        sync_global_mcps
        sync_global_claude_md
        ;;

    speckit)
        # Initialize SpecKit in a specific project
        if [ -z "$2" ]; then
            echo "Usage: $0 speckit <project-path>"
            echo "Example: $0 speckit ~/Development/my-project"
            exit 1
        fi
        init_speckit "$2"
        ;;

    speckit-all)
        # Initialize SpecKit in ALL projects
        DEV_DIR="$(get_dev_folder)"
        header "Initializing SpecKit in all projects..."
        count=0
        for dir in "$DEV_DIR"/*/; do
            name=$(basename "$dir")
            [[ "$name" =~ $SYNC_SKIP_PATTERN ]] && continue

            if [ ! -f "$dir/.specify/scripts/bash/common.sh" ]; then
                log "Init: $name"
                (cd "$dir" && specify init --here --ai claude --force --no-git 2>/dev/null) || true
                ((count++))
            fi
        done
        header "Done! SpecKit initialized in $count projects."
        ;;

    *)
        echo "Usage: $0 [sync|mcp|speckit|speckit-all]"
        echo ""
        echo "Commands:"
        echo "  sync         - Sync all global configs (default)"
        echo "  mcp          - Sync MCP servers and CLAUDE.md only"
        echo "  speckit PATH - Initialize SpecKit in a project"
        echo "  speckit-all  - Initialize SpecKit in ALL projects"
        echo ""
        echo "Global configs:"
        echo "  ~/.claude/commands/    Slash commands"
        echo "  ~/.claude/hooks/       Tool hooks"
        echo "  ~/.claude/agents/      Agent definitions"
        echo "  ~/.claude/CLAUDE.md    Development principles"
        echo "  ~/.cursor/mcp.json     MCP servers (Cursor)"
        echo "  ~/.claude.json         MCP servers (Claude Code)"
        echo ""
        echo "For Cursor rules: Settings → Rules → User Rules"
        exit 1
        ;;
esac
