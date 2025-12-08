#!/usr/bin/env bash
# Building block sync functions
# Independent modules for diet103, SpecKit, rulesync, and commands

# Note: This module expects SCRIPT_DIR, TEMPLATE_DIR to be set by the caller
# Load common functions if not already loaded
if [ -z "${COLOR_GREEN:-}" ]; then
    # shellcheck source=scripts/bash/lib/common.sh
    source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
fi

# ============================================================================
# BUILDING BLOCK CONFIGURATION
# ============================================================================
# Enable/disable independent building blocks
# Set to false to exclude a building block from sync operations

ENABLE_DIET103=true       # diet103 infrastructure (hooks + skills + agents)
ENABLE_SPECKIT=true       # SpecKit templates and infrastructure
ENABLE_RULESYNC=true      # Rulesync rules and configuration

# ============================================================================
# MODULAR SYNC FUNCTIONS - Independent Building Blocks
# ============================================================================

# Sync diet103 infrastructure
# Includes hooks, skills, and diet103-specific configurations
sync_diet103() {
    [[ "$ENABLE_DIET103" != "true" ]] && return 0

    local dir="$1"

    # Sync hooks (auto-activation system)
    if [ -d "$TEMPLATE_DIR/.claude/hooks" ]; then
        mkdir -p "$dir/.claude/hooks"
        cp -rf "$TEMPLATE_DIR/.claude/hooks/"* "$dir/.claude/hooks/" 2>/dev/null || true
        chmod +x "$dir/.claude/hooks/"*.sh 2>/dev/null || true
        # Install hook dependencies quietly
        (cd "$dir/.claude/hooks" && npm install --silent 2>/dev/null) || true
    fi

    # Sync skills (production-tested patterns)
    if [ -d "$TEMPLATE_DIR/.claude/skills" ]; then
        mkdir -p "$dir/.claude/skills"
        cp -rf "$TEMPLATE_DIR/.claude/skills/"* "$dir/.claude/skills/" 2>/dev/null || true
    fi

    # Sync agents (specialized helpers)
    if [ -d "$TEMPLATE_DIR/.claude/agents" ]; then
        mkdir -p "$dir/.claude/agents"
        cp -rf "$TEMPLATE_DIR/.claude/agents/"* "$dir/.claude/agents/" 2>/dev/null || true
    fi

    # Sync skill-rules.json (activation configuration)
    [ -f "$TEMPLATE_DIR/.claude/skill-rules.json" ] && \
        cp -f "$TEMPLATE_DIR/.claude/skill-rules.json" "$dir/.claude/"

    # Sync settings.json (hooks configuration)
    [ -f "$TEMPLATE_DIR/.claude/settings.json" ] && \
        cp -f "$TEMPLATE_DIR/.claude/settings.json" "$dir/.claude/"
}

# Sync SpecKit templates and infrastructure
# Initializes and syncs SpecKit .specify directory
sync_speckit() {
    [[ "$ENABLE_SPECKIT" != "true" ]] && return 0

    local dir="$1"

    # Initialize SpecKit if not already initialized
    if [ ! -f "$dir/.specify/scripts/bash/common.sh" ]; then
        log "  Initializing SpecKit..."
        (cd "$dir" && specify init --here --ai claude --force --no-git 2>/dev/null) || true
    fi
}

# Sync all commands from .rulesync/commands/ to project
# Single source of truth: template/.rulesync/commands/
sync_commands() {
    local dir="$1"
    local count=0

    # Ensure directories exist
    mkdir -p "$dir/.rulesync/commands"
    mkdir -p "$dir/.claude/commands"

    # Copy ALL commands from .rulesync/commands/ (dynamic discovery)
    if [ -d "$TEMPLATE_DIR/.rulesync/commands" ]; then
        for cmd in "$TEMPLATE_DIR/.rulesync/commands/"*.md; do
            [ -f "$cmd" ] || continue
            local name
            name=$(basename "$cmd")

            # Copy to rulesync for Cursor/Roo
            cp -f "$cmd" "$dir/.rulesync/commands/" 2>/dev/null || true

            # Copy to .claude for Claude Code
            cp -f "$cmd" "$dir/.claude/commands/" 2>/dev/null || true

            ((count++))
        done
    fi

    [ $count -gt 0 ] && log "    ✓ $count commands synced"
}

# Sync rulesync rules and base configuration
# Rules are shared prompts/context loaded by AI editors
sync_rulesync() {
    [[ "$ENABLE_RULESYNC" != "true" ]] && return 0

    local dir="$1"

    # Copy rulesync rules
    if [ -d "$TEMPLATE_DIR/.rulesync/rules" ]; then
        cp -f "$TEMPLATE_DIR/.rulesync/rules/"*.md "$dir/.rulesync/rules/" 2>/dev/null || true
    fi

    # Copy .aiignore
    if [ -f "$TEMPLATE_DIR/.rulesync/.aiignore" ]; then
        cp -f "$TEMPLATE_DIR/.rulesync/.aiignore" "$dir/.rulesync/"
    fi
}

# Copy template files to project using modular sync functions
copy_template() {
    local dir="$1"

    # Create base directory structure
    mkdir -p "$dir/.rulesync"/{rules,commands}
    mkdir -p "$dir/.claude/commands"

    # Sync each building block independently
    sync_speckit "$dir"        # SpecKit templates and infrastructure
    sync_commands "$dir"       # All commands (dynamic discovery)
    sync_rulesync "$dir"       # Rulesync rules and configuration
    sync_diet103 "$dir"        # diet103 infrastructure (hooks, skills, agents)

    # Remove local MCP config if it exists (use global instead)
    rm -f "$dir/.rulesync/mcp.json" 2>/dev/null || true
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
