#!/usr/bin/env bash
# Building block sync functions
# KISS Architecture: Global configs for Claude Code, per-project for Cursor/Roo only

# Note: This module expects SCRIPT_DIR, TEMPLATE_DIR to be set by the caller
# Load common functions if not already loaded (use +x to check if SET)
if [ -z "${COLOR_GREEN+x}" ]; then
    # shellcheck source=scripts/lib/common.sh
    source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
fi

# ============================================================================
# BUILDING BLOCK CONFIGURATION
# ============================================================================
# Claude Code: Everything is GLOBAL at ~/.claude/ (no per-project sync needed)
# Cursor/Roo: Rules still need per-project sync (they don't support global)

ENABLE_SPECKIT=true       # SpecKit templates and infrastructure
ENABLE_RULESYNC=true      # Rulesync rules for Cursor/Roo (per-project)

# ============================================================================
# GLOBAL SYNC FUNCTIONS - Claude Code (runs once, not per-project)
# ============================================================================

# Sync Claude Code global config (commands, hooks, agents)
# Called ONCE, not for each project - everything lives in ~/.claude/
sync_global_claude_config() {
    local global_claude="$HOME/.claude"

    # Ensure directories exist
    mkdir -p "$global_claude"/{commands,hooks,agents}

    # Sync commands to global (source: template/.claude/commands/)
    if [ -d "$TEMPLATE_DIR/.claude/commands" ]; then
        cp -f "$TEMPLATE_DIR/.claude/commands/"*.md "$global_claude/commands/" 2>/dev/null || true
        log "  → Commands: $global_claude/commands/"
    fi

    # Sync hooks to global
    if [ -d "$TEMPLATE_DIR/.claude/hooks" ]; then
        cp -f "$TEMPLATE_DIR/.claude/hooks/"*.sh "$global_claude/hooks/" 2>/dev/null || true
        cp -f "$TEMPLATE_DIR/.claude/hooks/"*.ts "$global_claude/hooks/" 2>/dev/null || true
        cp -f "$TEMPLATE_DIR/.claude/hooks/package.json" "$global_claude/hooks/" 2>/dev/null || true
        cp -f "$TEMPLATE_DIR/.claude/hooks/tsconfig.json" "$global_claude/hooks/" 2>/dev/null || true
        chmod +x "$global_claude/hooks/"*.sh 2>/dev/null || true
        # Install hook dependencies
        (cd "$global_claude/hooks" && npm install --silent 2>/dev/null) || true
        log "  → Hooks: $global_claude/hooks/"
    fi

    # Sync agents to global
    if [ -d "$TEMPLATE_DIR/.claude/agents" ]; then
        cp -f "$TEMPLATE_DIR/.claude/agents/"*.md "$global_claude/agents/" 2>/dev/null || true
        log "  → Agents: $global_claude/agents/"
    fi

    # Sync skill-rules.json
    [ -f "$TEMPLATE_DIR/.claude/skill-rules.json" ] && \
        cp -f "$TEMPLATE_DIR/.claude/skill-rules.json" "$global_claude/"

    # Sync settings.json (hooks configuration)
    [ -f "$TEMPLATE_DIR/.claude/settings.json" ] && \
        cp -f "$TEMPLATE_DIR/.claude/settings.json" "$global_claude/"

    log "✓ Claude Code global config synced"
}

# ============================================================================
# PER-PROJECT SYNC FUNCTIONS - Cursor/Roo only
# ============================================================================

# Sync SpecKit templates and infrastructure
sync_speckit() {
    [[ "$ENABLE_SPECKIT" != "true" ]] && return 0

    local dir="$1"

    # Initialize SpecKit if not already initialized
    if [ ! -f "$dir/.specify/scripts/bash/common.sh" ]; then
        log "  Initializing SpecKit..."
        (cd "$dir" && specify init --here --ai claude --force --no-git 2>/dev/null) || true
    fi
}

# Sync commands to Cursor/Roo (source: template/.claude/commands/)
sync_commands_cursor_roo() {
    local dir="$1"
    local count=0

    mkdir -p "$dir/.rulesync/commands"

    if [ -d "$TEMPLATE_DIR/.claude/commands" ]; then
        for cmd in "$TEMPLATE_DIR/.claude/commands/"*.md; do
            [ -f "$cmd" ] || continue
            cp -f "$cmd" "$dir/.rulesync/commands/" 2>/dev/null || true
            ((count++))
        done
    fi

    [ $count -gt 0 ] && log "    ✓ $count commands synced (Cursor/Roo)"
}

# Sync rulesync rules and base configuration
# Rules are shared prompts/context loaded by Cursor/Roo editors
sync_rulesync() {
    [[ "$ENABLE_RULESYNC" != "true" ]] && return 0

    local dir="$1"

    # Copy rulesync rules
    if [ -d "$TEMPLATE_DIR/.rulesync/rules" ]; then
        mkdir -p "$dir/.rulesync/rules"
        cp -f "$TEMPLATE_DIR/.rulesync/rules/"*.md "$dir/.rulesync/rules/" 2>/dev/null || true
    fi

    # Copy .aiignore
    if [ -f "$TEMPLATE_DIR/.rulesync/.aiignore" ]; then
        cp -f "$TEMPLATE_DIR/.rulesync/.aiignore" "$dir/.rulesync/"
    fi
}

# Copy template files to project (Cursor/Roo only - Claude Code is global)
copy_template() {
    local dir="$1"

    # Create base directory structure for Cursor/Roo
    mkdir -p "$dir/.rulesync"/{rules,commands}

    # Sync per-project components (Cursor/Roo only)
    sync_speckit "$dir"              # SpecKit templates
    sync_commands_cursor_roo "$dir"  # Commands for Cursor/Roo
    sync_rulesync "$dir"             # Rules for Cursor/Roo

    # Remove local MCP config if it exists (use global instead)
    rm -f "$dir/.rulesync/mcp.json" 2>/dev/null || true

    # Remove old per-project Claude Code configs (now global)
    rm -rf "$dir/.claude/commands" 2>/dev/null || true
    rm -rf "$dir/.claude/hooks" 2>/dev/null || true
    rm -rf "$dir/.claude/agents" 2>/dev/null || true
}

# Create rulesync config (without MCP feature)
create_config() {
    cat > "$1/rulesync.jsonc" << 'EOF'
{
  "$schema": "https://raw.githubusercontent.com/dyoshikawa/rulesync/main/schema.json",
  "targets": ["cursor", "roo"],
  "features": ["rules", "ignore", "commands"],
  "simulateCommands": true,
  "delete": true
}
EOF
}
