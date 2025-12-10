# Global Sync

All configs are **global** - no per-project sync needed.

## What Gets Synced

| Config | Location | Tool |
|--------|----------|------|
| Commands | `~/.claude/commands/` | Claude Code |
| Hooks | `~/.claude/hooks/` | Claude Code |
| Agents | `~/.claude/agents/` | Claude Code |
| CLAUDE.md | `~/.claude/CLAUDE.md` | Claude Code |
| MCP Servers | `~/.cursor/mcp.json` | Cursor |
| MCP Servers | `~/.claude.json` | Claude Code |

## Cursor Rules

Cursor uses **User Rules** (global, not per-project):

1. Open Cursor
2. Go to **Settings → Rules → User Rules**
3. Paste content from `template/CLAUDE.md`

This applies to ALL projects automatically.

## Usage

```bash
# Sync everything
./sync-rules.sh

# Sync MCP and CLAUDE.md only
./sync-rules.sh mcp

# Initialize SpecKit in a project
./sync-rules.sh speckit ~/Development/my-project
```

## Automatic Sync

### Git Hook (on pull)
```bash
# .git/hooks/post-merge
#!/bin/bash
cd "$(dirname "$0")/../.."
./sync-rules.sh
```

### Daily (LaunchAgent)
```bash
# Install
launchctl load ~/Library/LaunchAgents/com.global.autosync.plist

# Uninstall
launchctl unload ~/Library/LaunchAgents/com.global.autosync.plist
```

## Update Workflow

1. Edit files in `template/.claude/` or `template/CLAUDE.md`
2. Run `./sync-rules.sh`
3. Done - global configs updated instantly
