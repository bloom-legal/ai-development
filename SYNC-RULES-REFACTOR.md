# sync-rules.sh Refactoring - Modular Building Blocks

## Overview

The `sync-rules.sh` script has been refactored to support **modular building blocks** that can be independently enabled, disabled, and upgraded. This design supports the transition from SuperClaude to diet103 while maintaining backward compatibility.

## Architecture

### Building Blocks

The script now manages five independent building blocks:

| Building Block | Status | Description |
|---------------|---------|-------------|
| **SuperClaude** | `DISABLED` (deprecated) | Legacy SuperClaude commands from `~/.claude/commands/sc/` |
| **diet103** | `DISABLED` (not implemented) | Next-generation infrastructure for hooks, skills, and capabilities |
| **SpecKit** | `ENABLED` | SpecKit templates and `.specify/` infrastructure |
| **Custom** | `ENABLED` | Project-specific custom commands (`custom-refactor.md`, `custom-upgrade.md`) |
| **Rulesync** | `ENABLED` | Rulesync rules and base configuration |

### Configuration

Enable/disable building blocks at the top of `sync-rules.sh`:

```bash
# Building Block Configuration
ENABLE_SUPERCLAUDE=false  # SuperClaude commands (deprecated)
ENABLE_DIET103=false      # diet103 infrastructure (not yet implemented)
ENABLE_SPECKIT=true       # SpecKit templates and infrastructure
ENABLE_CUSTOM=true        # Custom project-specific commands
ENABLE_RULESYNC=true      # Rulesync rules and configuration
```

## Modular Sync Functions

Each building block has its own independent sync function:

### 1. `sync_superclaude()`
**Purpose**: Sync SuperClaude commands from Claude Code to template and projects

**Status**: DISABLED (deprecated)

**What it does**:
- Reads commands from `~/.claude/commands/sc/`
- Converts from Claude Code format to Rulesync format
- Copies to both `.rulesync/commands/` and `.claude/commands/`

**Files synced**:
- All `*.md` files from `~/.claude/commands/sc/` (except README.md)

**When to enable**: Only for legacy SuperClaude users during migration

---

### 2. `sync_diet103()`
**Purpose**: Sync diet103 infrastructure, hooks, skills, and configurations

**Status**: DISABLED (not yet implemented)

**What it will do** (TODO):
- Sync diet103 hooks (`.diet103/hooks/`)
- Sync diet103 skills (`.diet103/skills/`)
- Sync diet103 configuration files

**When to enable**: When diet103 is integrated into the project

---

### 3. `sync_speckit()`
**Purpose**: Initialize and sync SpecKit templates and infrastructure

**Status**: ENABLED

**What it does**:
- Initializes SpecKit if not already initialized
- Creates `.specify/` directory structure
- Runs `specify init --here --ai claude --force --no-git`

**Files synced**:
- `.specify/scripts/bash/common.sh` (created by SpecKit)
- `.specify/templates/` (created by SpecKit)
- `.specify/memory/` (created by SpecKit)

**When to disable**: For projects not using SpecKit

---

### 4. `sync_custom()`
**Purpose**: Sync custom project-specific commands

**Status**: ENABLED

**What it does**:
- Copies custom commands from template to projects
- Syncs to both `.rulesync/commands/` and `.claude/commands/`

**Files synced**:
- `custom-refactor.md` - Parallel refactoring with subagents
- `custom-upgrade.md` - Dependency upgrade with compatibility checks

**When to disable**: For projects that don't need custom commands

---

### 5. `sync_rulesync()`
**Purpose**: Sync rulesync rules and base configuration

**Status**: ENABLED

**What it does**:
- Copies rules from `template/.rulesync/rules/` to project
- Copies `.aiignore` file
- Sets up rulesync base infrastructure

**Files synced**:
- All `*.md` files in `.rulesync/rules/`
- `.rulesync/.aiignore`

**When to disable**: Never (rulesync is mandatory for all projects)

---

### 6. `sync_hooks()`
**Purpose**: Sync diet103 git hooks and automation scripts

**Status**: DISABLED (not yet implemented)

**What it will do** (TODO):
- Sync pre-commit hooks
- Sync post-checkout hooks
- Sync other git automation

**When to enable**: When diet103 hooks are implemented

---

### 7. `sync_skills()`
**Purpose**: Sync diet103 AI-powered skills and capabilities

**Status**: DISABLED (not yet implemented)

**What it will do** (TODO):
- Sync diet103 skills from framework
- Install skill dependencies
- Configure skill settings

**When to enable**: When diet103 skills are implemented

## Migration Path

### Phase 1: Current State (Now)
```bash
ENABLE_SUPERCLAUDE=false  # Disabled - deprecated
ENABLE_DIET103=false      # Not implemented yet
ENABLE_SPECKIT=true       # Active
ENABLE_CUSTOM=true        # Active
ENABLE_RULESYNC=true      # Active
```

### Phase 2: diet103 Integration (Future)
```bash
ENABLE_SUPERCLAUDE=false  # Removed entirely
ENABLE_DIET103=true       # Implement and enable
ENABLE_SPECKIT=true       # Keep
ENABLE_CUSTOM=true        # Keep
ENABLE_RULESYNC=true      # Keep
```

### Phase 3: Full diet103 (Future)
```bash
# SuperClaude removed from codebase
ENABLE_DIET103=true       # Fully integrated
ENABLE_SPECKIT=true       # Keep
ENABLE_CUSTOM=true        # Keep
ENABLE_RULESYNC=true      # Keep
```

## Usage

### Check Configuration
```bash
./sync-rules.sh --help
```

Output shows enabled building blocks:
```
=== Building Blocks Configuration: ===
  SuperClaude:  DISABLED
  diet103:      DISABLED
  SpecKit:      ENABLED
  Custom:       ENABLED
  Rulesync:     ENABLED
```

### Sync All Projects
```bash
./sync-rules.sh sync
```

This will:
1. Display building blocks configuration
2. Run preflight check
3. Sync enabled building blocks to all projects
4. Run rulesync generate

### Sync Only MCPs
```bash
./sync-rules.sh mcp
```

### Initialize New Projects
```bash
./sync-rules.sh init
```

### Clean Local MCPs
```bash
./sync-rules.sh clean
```

## Development Guidelines

### Adding a New Building Block

1. **Add Configuration Flag**
```bash
ENABLE_NEWBLOCK=false  # Description
```

2. **Create Sync Function**
```bash
# Sync newblock functionality
# Description of what it does
sync_newblock() {
    [[ "$ENABLE_NEWBLOCK" != "true" ]] && return 0

    local dir="$1"

    # Implementation here
    log "  Syncing newblock..."

    # Copy files, create directories, etc.
}
```

3. **Call from copy_template()**
```bash
copy_template() {
    local dir="$1"

    # ... existing code ...

    sync_newblock "$dir"  # Add new building block
}
```

4. **Update display_building_blocks()**
```bash
display_building_blocks() {
    header "Building Blocks Configuration:"
    # ... existing blocks ...
    log "  NewBlock:     $([ "$ENABLE_NEWBLOCK" = "true" ] && echo "ENABLED" || echo "DISABLED")"
    echo ""
}
```

5. **Update Help Text**
```bash
echo "  - ENABLE_NEWBLOCK     : Description"
```

### Removing a Building Block

1. Set flag to `false` by default
2. Mark function as deprecated in comments
3. After transition period, remove:
   - Configuration flag
   - Sync function
   - Function call from `copy_template()`
   - Display line from `display_building_blocks()`
   - Help text

## Benefits

### 1. Independent Upgrades
Each building block can be upgraded independently without affecting others.

Example: Upgrade diet103 without touching SpecKit or Custom commands.

### 2. Clean Migration
Smooth transition from SuperClaude to diet103:
- Disable SuperClaude
- Implement diet103
- Enable diet103
- Remove SuperClaude code

### 3. Project Flexibility
Projects can enable/disable building blocks based on needs:
- Minimal projects: Only Rulesync
- Standard projects: Rulesync + SpecKit + Custom
- Full projects: All building blocks

### 4. Easier Testing
Test each building block in isolation:
```bash
# Test only SpecKit
ENABLE_SUPERCLAUDE=false
ENABLE_DIET103=false
ENABLE_SPECKIT=true
ENABLE_CUSTOM=false
ENABLE_RULESYNC=false
```

### 5. Clear Dependencies
Each sync function is self-contained and explicitly declares what it syncs.

## File Structure

### Template Structure
```
template/
├── .rulesync/
│   ├── commands/          # SuperClaude + Custom commands (if enabled)
│   ├── rules/             # Rulesync rules
│   ├── .aiignore          # Rulesync ignore file
│   └── mcp.json.template  # MCP configuration template
├── .claude/
│   └── commands/          # Full commands for Claude Code
└── .specify/              # SpecKit infrastructure (created by sync_speckit)
```

### Project Structure (After Sync)
```
project/
├── .rulesync/
│   ├── commands/          # Synced commands (Custom only if SuperClaude disabled)
│   ├── rules/             # Synced rules
│   └── .aiignore          # Synced ignore file
├── .claude/
│   └── commands/          # Full commands for Claude Code
├── .specify/              # SpecKit infrastructure (if enabled)
└── .diet103/              # diet103 infrastructure (when implemented)
    ├── hooks/
    └── skills/
```

## Testing

### Verify Building Blocks
```bash
./sync-rules.sh --help
# Check that correct blocks are ENABLED/DISABLED
```

### Test MCP Sync
```bash
./sync-rules.sh mcp
# Verify MCPs are synced to global configs
```

### Test Project Sync
```bash
# Create a test project
mkdir -p ~/Development/test-project
./sync-rules.sh sync
# Verify only enabled building blocks are synced
```

### Test Custom Commands
```bash
# Check that custom commands are synced
ls -la ~/Development/test-project/.claude/commands/custom-*.md
ls -la ~/Development/test-project/.rulesync/commands/custom-*.md
```

### Test SpecKit
```bash
# Check that SpecKit is initialized
ls -la ~/Development/test-project/.specify/
```

## Troubleshooting

### Building Block Not Syncing

1. Check if it's enabled:
```bash
grep "ENABLE_BLOCKNAME" sync-rules.sh
```

2. Check if sync function returns early:
```bash
# Add debug logging to sync function
log "  DEBUG: Syncing blockname for $dir"
```

3. Verify source files exist:
```bash
ls -la template/.rulesync/commands/custom-*.md
ls -la template/.claude/commands/custom-*.md
```

### SuperClaude Commands Still Syncing

SuperClaude is disabled by default. If commands are still syncing:

1. Verify flag is false:
```bash
grep "ENABLE_SUPERCLAUDE" sync-rules.sh
# Should show: ENABLE_SUPERCLAUDE=false
```

2. Check if function is being called:
```bash
grep "sync_superclaude" sync-rules.sh
# Should only be in definition and conditional calls
```

### diet103 Not Working

diet103 is not yet implemented. The sync functions are placeholders:
- `sync_diet103()` - Returns with TODO message
- `sync_hooks()` - Returns 0 (no-op)
- `sync_skills()` - Returns 0 (no-op)

Wait for diet103 implementation before enabling.

## Future Enhancements

### 1. Per-Project Configuration
Allow projects to override global building block settings:

```bash
# project/.rulesync/config.sh
ENABLE_SPECKIT=false  # Disable SpecKit for this project
```

### 2. Building Block Versions
Track versions of each building block:

```bash
SUPERCLAUDE_VERSION="deprecated"
DIET103_VERSION="0.1.0"
SPECKIT_VERSION="1.2.0"
```

### 3. Dependency Management
Declare dependencies between building blocks:

```bash
# diet103 requires rulesync
[[ "$ENABLE_DIET103" == "true" && "$ENABLE_RULESYNC" != "true" ]] && {
    warn "diet103 requires rulesync, enabling..."
    ENABLE_RULESYNC=true
}
```

### 4. Building Block Registry
External registry of available building blocks:

```json
{
  "blocks": {
    "superclaude": {
      "status": "deprecated",
      "version": "1.0.0"
    },
    "diet103": {
      "status": "beta",
      "version": "0.1.0"
    }
  }
}
```

## Summary

The refactored `sync-rules.sh` provides:

1. **Modular Architecture**: Independent building blocks
2. **Clean Migration**: Smooth SuperClaude → diet103 transition
3. **Project Flexibility**: Enable/disable blocks per project
4. **Future-Proof**: Easy to add/remove building blocks
5. **Clear Separation**: Each block has dedicated sync function
6. **Backward Compatible**: Existing functionality preserved

All existing functionality is maintained while providing a clear path for future upgrades and migrations.
