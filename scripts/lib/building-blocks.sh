#!/usr/bin/env bash
# Building block sync functions
# GLOBAL ONLY: Everything syncs to ~/.claude/ and global MCP configs
# No per-project sync - Cursor uses User Rules (Settings), Claude Code uses ~/.claude/

# Note: This module expects SCRIPT_DIR, TEMPLATE_DIR to be set by the caller
if [ -z "${COLOR_GREEN+x}" ]; then
    # shellcheck source=scripts/lib/common.sh
    source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
fi

# ============================================================================
# CONFIGURATION
# ============================================================================

ENABLE_SPECKIT=true  # SpecKit templates (still per-project, initialized on demand)

# ============================================================================
# GLOBAL SYNC FUNCTIONS
# ============================================================================

# Sync Claude Code global config (commands, hooks, agents)
# Everything lives in ~/.claude/ - no per-project sync needed
sync_global_claude_config() {
    local global_claude="$HOME/.claude"

    header "Syncing Claude Code config to $global_claude..."

    # Ensure directories exist
    mkdir -p "$global_claude"/{commands,hooks,agents}

    # Sync commands
    if [ -d "$TEMPLATE_DIR/.claude/commands" ]; then
        cp -f "$TEMPLATE_DIR/.claude/commands/"*.md "$global_claude/commands/" 2>/dev/null || true
        local count=$(ls -1 "$TEMPLATE_DIR/.claude/commands/"*.md 2>/dev/null | wc -l | tr -d ' ')
        log "  → Commands: $count files"
    fi

    # Sync hooks
    if [ -d "$TEMPLATE_DIR/.claude/hooks" ]; then
        cp -f "$TEMPLATE_DIR/.claude/hooks/"*.sh "$global_claude/hooks/" 2>/dev/null || true
        cp -f "$TEMPLATE_DIR/.claude/hooks/"*.ts "$global_claude/hooks/" 2>/dev/null || true
        cp -f "$TEMPLATE_DIR/.claude/hooks/package.json" "$global_claude/hooks/" 2>/dev/null || true
        cp -f "$TEMPLATE_DIR/.claude/hooks/tsconfig.json" "$global_claude/hooks/" 2>/dev/null || true
        chmod +x "$global_claude/hooks/"*.sh 2>/dev/null || true
        # Install hook dependencies
        (cd "$global_claude/hooks" && npm install --silent 2>/dev/null) || true
        log "  → Hooks synced"
    fi

    # Sync agents
    if [ -d "$TEMPLATE_DIR/.claude/agents" ]; then
        cp -f "$TEMPLATE_DIR/.claude/agents/"*.md "$global_claude/agents/" 2>/dev/null || true
        local count=$(ls -1 "$TEMPLATE_DIR/.claude/agents/"*.md 2>/dev/null | wc -l | tr -d ' ')
        log "  → Agents: $count files"
    fi

    # Sync settings.json (hooks configuration)
    [ -f "$TEMPLATE_DIR/.claude/settings.json" ] && \
        cp -f "$TEMPLATE_DIR/.claude/settings.json" "$global_claude/"

    log "✓ Claude Code global config synced"
}

# Initialize SpecKit in a project (on-demand, not bulk sync)
init_speckit() {
    [[ "$ENABLE_SPECKIT" != "true" ]] && return 0

    local dir="$1"

    if [ ! -d "$dir" ]; then
        warn "Directory not found: $dir"
        return 1
    fi

    if [ -f "$dir/.specify/scripts/bash/common.sh" ]; then
        log "SpecKit already initialized in $dir"
        return 0
    fi

    log "Initializing SpecKit in $dir..."
    (cd "$dir" && specify init --here --ai claude --force --no-git 2>/dev/null) || {
        warn "Failed to initialize SpecKit"
        return 1
    }
    log "✓ SpecKit initialized"
}
