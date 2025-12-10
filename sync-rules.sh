#!/bin/bash
# Sync modular building blocks across all projects
# MCPs are synced to GLOBAL configs (Cursor, Claude Code CLI, Roo Code)
# Rules and commands are synced to per-project configs
# Usage: ./sync-rules.sh [update|sync|init|mcp]
set -e

# Load common functions and modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/scripts/lib/common.sh"
# shellcheck source=scripts/lib/mcp-manager.sh
source "$SCRIPT_DIR/scripts/lib/mcp-manager.sh"
# shellcheck source=scripts/lib/building-blocks.sh
source "$SCRIPT_DIR/scripts/lib/building-blocks.sh"

# Config - derive paths from script location
export DEV_DIR="$(get_dev_folder)"
export TEMPLATE_DIR="$SCRIPT_DIR/template"
# SYNC_SKIP_PATTERN is defined in common.sh

# Paths defined in common.sh: CURSOR_MCP, CLAUDE_CODE_MCP, ROO_MCP, CLAUDE_GLOBAL_MD

# ============================================================================
# ORCHESTRATION FUNCTIONS
# ============================================================================

# Pre-flight check and remediation
preflight_check() {
    local check_script="$SCRIPT_DIR/scripts/check.sh"

    if [ ! -f "$check_script" ]; then
        warn "check.sh not found, skipping pre-flight check"
        return 0
    fi

    header "Pre-flight check..."
    if ! "$check_script" 2>/dev/null; then
        warn "Issues detected, attempting remediation..."
        "$check_script" --fix 2>/dev/null || true

        # Verify fix worked
        if ! "$check_script" 2>/dev/null; then
            warn "Some issues remain, continuing anyway..."
        else
            log "Remediation successful"
        fi
    else
        log "All checks passed"
    fi
}

# Display enabled building blocks
display_building_blocks() {
    header "Building Blocks Configuration:"
    log "  Claude Code: GLOBAL (~/.claude/) - commands, hooks, agents"
    log "  Cursor/Roo:  per-project - rules, commands"
    log "  SpecKit:     $([ "$ENABLE_SPECKIT" = "true" ] && echo "ENABLED" || echo "DISABLED")"
    echo ""
}

# ============================================================================
# MAIN ORCHESTRATION
# ============================================================================

header "=== Sync: Modular Building Blocks ==="
display_building_blocks

action="${1:-sync}"

# Run pre-flight check for sync operations (skip for mcp/clean/help to avoid loops)
# mcp is excluded because check.sh calls sync-rules.sh mcp to remediate
if [[ "$action" =~ ^(sync|generate|update)$ ]] && [[ -z "$SKIP_PREFLIGHT" ]]; then
    preflight_check
fi

if [[ "$action" == "update" ]]; then
    warn "Updating tools..."
    npm update -g rulesync 2>/dev/null || true
    echo ""
    action="sync"
fi

case "$action" in
    mcp)
        # Sync MCPs and CLAUDE.md to global configs only
        sync_global_mcps
        sync_global_claude_md
        ;;

    clean)
        # Remove local MCP configs
        clean_local_mcps
        ;;

    sync|generate)
        # GLOBAL: Sync MCPs, CLAUDE.md, and Claude Code config (once)
        header "Syncing GLOBAL configs..."
        sync_global_mcps
        sync_global_claude_md
        sync_global_claude_config
        echo ""

        # PER-PROJECT: Sync rules/commands for Cursor/Roo only
        header "Syncing per-project configs (Cursor/Roo)..."
        count=0
        init_count=0
        for dir in "$DEV_DIR"/*/; do
            name=$(basename "$dir")
            [[ "$name" =~ $SYNC_SKIP_PATTERN ]] && continue

            # Auto-initialize if no rulesync.jsonc exists
            if [ ! -f "$dir/rulesync.jsonc" ]; then
                log "Init: $name"
                copy_template "$dir"
                create_config "$dir"
                ((init_count++))
            fi

            log "$name"
            copy_template "$dir"
            update_config_remove_mcp "$dir"
            (cd "$dir" && npx rulesync generate 2>/dev/null) || true
            ((count++))
        done

        if [ $init_count -gt 0 ]; then
            header "=== Done! $count projects synced ($init_count newly initialized) ==="
        else
            header "=== Done! $count projects synced ==="
        fi
        ;;

    init)
        count=0
        for dir in "$DEV_DIR"/*/; do
            name=$(basename "$dir")
            [[ "$name" =~ $SYNC_SKIP_PATTERN ]] && continue
            [ -f "$dir/rulesync.jsonc" ] && continue

            log "Init: $name"
            copy_template "$dir"
            create_config "$dir"
            ((count++))
        done

        header "=== Done! $count projects initialized ==="
        ;;

    *)
        echo "Usage: $0 [update|sync|init|mcp|clean]"
        echo ""
        echo "Commands:"
        echo "  sync    - Sync MCPs + CLAUDE.md to global + rules/commands to projects (default)"
        echo "  mcp     - Sync MCPs + CLAUDE.md to global configs only"
        echo "  clean   - Remove local MCP configs from all projects"
        echo "  init    - Initialize new projects with rulesync"
        echo "  update  - Update tools and sync"
        echo ""
        echo "Building Blocks:"
        echo "  Edit scripts/lib/building-blocks.sh:"
        echo "  - ENABLE_SPECKIT   : SpecKit templates"
        echo "  - ENABLE_RULESYNC  : Rules and .aiignore"
        echo ""
        echo "  Commands, hooks, agents always sync to ~/.claude/ (global)"
        exit 1
        ;;
esac
