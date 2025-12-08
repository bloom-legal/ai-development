# Automated Project Synchronization

Your projects stay automatically updated using multiple sync strategies.

## Automatic Sync Methods

### 1. Git Hook (Automatic on Pull)
- **Trigger**: Runs automatically after `git pull` in global repo
- **Location**: `.git/hooks/post-merge`
- **What**: Syncs infrastructure changes to all projects
- **Log**: `/tmp/global-sync.log`

### 2. Daily Sync (LaunchAgent)
- **Trigger**: Runs daily at 9:00 AM
- **Location**: `~/Library/LaunchAgents/com.global.autosync.plist`
- **Setup**:
  ```bash
  launchctl load ~/Library/LaunchAgents/com.global.autosync.plist
  launchctl start com.global.autosync
  launchctl list | grep autosync
  ```
- **Uninstall**:
  ```bash
  launchctl unload ~/Library/LaunchAgents/com.global.autosync.plist
  rm ~/Library/LaunchAgents/com.global.autosync.plist
  ```

### 3. Manual Sync (On Demand)
- **Command**: `./auto-sync.sh`
- **Background**: `./auto-sync.sh --background`
- **Original**: `./sync-rules.sh sync`

## What Gets Synced

From `~/Development/global/template/` to all projects:

| Module | What | Scope |
|--------|------|-------|
| **CLAUDE.md** | Development principles | `~/.claude/CLAUDE.md` (global) |
| **MCP** | MCP server configs | Global (Cursor, Claude Code, Roo) |
| **Commands** | Slash commands | Per-project (auto-discovered) |
| **diet103** | Hooks, Skills, Agents | Per-project |
| **SpecKit** | Workflow templates | Per-project |
| **Rulesync** | Rules, `.aiignore` | Per-project |

## Command Discovery

Commands are auto-discovered from `template/.rulesync/commands/`:
- All `*.md` files synced to each project's `.rulesync/commands/` and `.claude/commands/`
- No hardcoded command lists
- Add new commands by dropping `.md` files into the directory

## Monitoring

```bash
# View latest sync log
cat /tmp/global-sync.log

# Check LaunchAgent logs
tail -f /tmp/global-autosync.log
tail -f /tmp/global-autosync.error.log

# Manual check
cd ~/Development/global
./check.sh
```

## Building Blocks

Enable/disable modules in `sync-rules.sh`:
```bash
ENABLE_DIET103=true    # Hooks + Skills + Agents
ENABLE_SPECKIT=true    # SpecKit templates
ENABLE_RULESYNC=true   # Rules and .aiignore
```

Commands are always synced (dynamic discovery from `.rulesync/commands/`).

## Update Workflow

1. Make changes in `~/Development/global/template/`
2. Commit and push (git hook runs sync automatically)
3. Or run `./auto-sync.sh` manually
4. All projects updated automatically

## Version Tracking

See `template/module-manifest.json` for module versions and sync status.

## Safety Features

- Logs all operations to `/tmp/`
- Pre-flight checks prevent broken deployments
- Modular - disable any building block
- Skip patterns: `global`, `_archives`, hidden folders
