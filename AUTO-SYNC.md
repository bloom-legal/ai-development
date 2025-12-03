# Automated Project Synchronization

Your 49 projects stay automatically updated using multiple sync strategies:

## 🔄 Automatic Sync Methods

### 1. Git Hook (Automatic on Pull)
- **Trigger**: Runs automatically after `git pull` in global repo
- **Location**: `.git/hooks/post-merge`
- **What**: Syncs infrastructure changes to all 49 projects
- **Setup**: ✅ Already configured
- **Log**: `/tmp/global-sync.log`

### 2. Daily Sync (LaunchAgent)
- **Trigger**: Runs daily at 9:00 AM
- **Location**: `~/Library/LaunchAgents/com.global.autosync.plist`
- **Setup**:
  ```bash
  # Load the agent
  launchctl load ~/Library/LaunchAgents/com.global.autosync.plist

  # Start immediately (optional)
  launchctl start com.global.autosync

  # Check status
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

## 📊 What Gets Synced

From `~/Development/global/template/` to all 49 projects:

| Module | Synced |
|--------|--------|
| **diet103** | Hooks, Skills, Agents |
| **SpecKit** | Templates, Infrastructure |
| **Rulesync** | Rules, Commands |
| **Custom** | Project-specific commands |
| **MCP** | Global MCP configs |

## 🔍 Monitoring

Check sync status:
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

## 🎯 Sync Behavior

1. **Pre-flight check** - Validates all prerequisites
2. **Health check** - Ensures 49 projects configured correctly
3. **Module sync** - Copies template changes to all projects
4. **Rulesync generation** - Generates Cursor/Roo commands
5. **Verification** - Confirms sync success

## 🛠️ Modular Building Blocks

Enable/disable modules in `sync-rules.sh`:
```bash
ENABLE_DIET103=true       # Hooks + Skills + Agents
ENABLE_SPECKIT=true       # SpecKit templates
ENABLE_CUSTOM=true        # Custom commands
ENABLE_RULESYNC=true      # Rulesync config
ENABLE_SUPERCLAUDE=false  # Deprecated
```

## 📦 Update Workflow

To update infrastructure:
1. Make changes in `~/Development/global/template/`
2. Commit and push (git hook runs sync automatically)
3. Or run `./auto-sync.sh` manually
4. All 49 projects updated automatically

## 🔐 Safety Features

- Dry-run mode available: `./sync-rules.sh --dry-run`
- Logs all operations to `/tmp/`
- Pre-flight checks prevent broken deployments
- Modular - disable any building block
- Skip patterns: `global`, `_archives`, hidden folders

## 💡 Tips

- **After template updates**: Sync runs automatically via git hook
- **Check before PR**: Run `./check.sh` to validate all projects
- **Force sync**: `./sync-rules.sh sync` (no background)
- **View config**: `./check.sh` shows full system state
