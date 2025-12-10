# Automated Project Synchronization

Your projects stay automatically updated using multiple sync strategies.

## KISS Architecture

| Config | Location | Scope |
|--------|----------|-------|
| **Commands, Hooks, Agents** | `~/.claude/` | Global (all projects) |
| **MCP Servers** | `~/.cursor/mcp.json`, `~/.claude.json` | Global |
| **CLAUDE.md** | `~/.claude/CLAUDE.md` | Global |
| **Rules, .aiignore** | Per-project `.rulesync/` | Cursor/Roo only |

## Automatic Sync Methods

### 1. Git Hook (Automatic on Pull)
- **Trigger**: Runs automatically after `git pull` in global repo
- **Location**: `.git/hooks/post-merge`
- **What**: Syncs infrastructure changes
- **Log**: `/tmp/global-sync.log`

### 2. Daily Sync (LaunchAgent)
- **Trigger**: Runs daily at 9:00 AM
- **Location**: `~/Library/LaunchAgents/com.global.autosync.plist`
- **Setup**:
  ```bash
  launchctl load ~/Library/LaunchAgents/com.global.autosync.plist
  launchctl start com.global.autosync
  ```
- **Uninstall**:
  ```bash
  launchctl unload ~/Library/LaunchAgents/com.global.autosync.plist
  rm ~/Library/LaunchAgents/com.global.autosync.plist
  ```

### 3. Manual Sync (On Demand)
- **Command**: `./sync-rules.sh sync`
- **Background**: `./scripts/auto-sync.sh --background`

## What Gets Synced

### Global (once)
- `~/.claude/commands/` - Slash commands
- `~/.claude/hooks/` - Pre/post tool hooks
- `~/.claude/agents/` - Agent definitions
- `~/.claude/CLAUDE.md` - Development principles
- `~/.cursor/mcp.json` - MCP servers
- `~/.claude.json` - Claude Code MCP config

### Per-Project (Cursor/Roo only)
- `.rulesync/rules/` - AI rules
- `.rulesync/commands/` - Commands for Cursor/Roo
- `.rulesync/.aiignore` - Ignore patterns

## Monitoring

```bash
# View latest sync log
cat /tmp/global-sync.log

# Manual check
./scripts/check.sh
```

## Building Blocks

Edit `scripts/lib/building-blocks.sh`:
```bash
ENABLE_SPECKIT=true    # SpecKit templates
ENABLE_RULESYNC=true   # Rules and .aiignore
```

## Update Workflow

1. Make changes in `~/Development/global/template/`
2. Run `./sync-rules.sh sync`
3. Global configs updated immediately
4. Per-project configs synced for Cursor/Roo

## Safety Features

- Pre-flight checks prevent broken deployments
- Skip patterns: `global`, `_archives`, hidden folders
