# Quick Reference

## Commands

```bash
./sync-rules.sh              # Sync all global configs
./sync-rules.sh mcp          # Sync MCP servers only
./sync-rules.sh speckit-all  # Init SpecKit in all projects
./scripts/check.sh           # Verify setup
./scripts/check.sh --fix     # Auto-fix issues
```

## Custom Slash Commands

| Command | What it does |
|---------|--------------|
| `/custom-libdoc lodash` | Generate library docs |
| `/custom-upgrade` | Upgrade deps safely |
| `/custom-refactor` | Parallel codebase refactor |
| `/custom-structure` | Analyze project structure |

## Paths

| What | Source | Destination |
|------|--------|-------------|
| Commands | `template/.claude/commands/` | `~/.claude/commands/` |
| Hooks | `template/.claude/hooks/` | `~/.claude/hooks/` |
| Agents | `template/.claude/agents/` | `~/.claude/agents/` |
| CLAUDE.md | `template/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| MCP | `template/.rulesync/mcp.json.template` | `~/.cursor/mcp.json` |
| Secrets | `.env` | (used for MCP generation) |

## Adding a New Command

1. Create `template/.claude/commands/custom-name.md`
2. Run `./sync-rules.sh`
3. Done - available globally in Claude Code

## Adding a New MCP Server

1. Edit `template/.rulesync/mcp.json.template`
2. Add secrets to `.env` if needed
3. Run `./sync-rules.sh mcp`

## Cursor Rules Setup

Cursor uses **User Rules** (one-time setup):

1. Open Cursor → Settings → Rules → User Rules
2. Paste content from `template/CLAUDE.md`
3. Done - applies to all projects

## Troubleshooting

```bash
./scripts/check.sh           # Check what's wrong
./scripts/check.sh --fix     # Fix automatically
./sync-rules.sh mcp          # Regenerate MCP configs
./sync-rules.sh              # Full re-sync
```
