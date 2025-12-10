# Quick Reference Card

## Daily Commands

```bash
./sync-rules.sh sync    # Sync everything to all projects
./sync-rules.sh mcp     # Sync MCPs to global configs only
./scripts/check.sh              # Verify setup
./scripts/check.sh --fix        # Auto-fix issues
```

## Custom Slash Commands

| Command | What it does |
|---------|--------------|
| `/custom-libdoc lodash` | Generate library feature docs |
| `/custom-upgrade` | Upgrade deps safely |
| `/custom-refactor` | Parallel codebase refactor |
| `/custom-structure` | Analyze project structure |

## Paths

| What | Where |
|------|-------|
| Commands | `template/.claude/commands/` |
| Hooks | `template/.claude/hooks/` |
| Agents | `template/.claude/agents/` |
| Rules | `template/.rulesync/rules/` |
| MCP template | `template/.rulesync/mcp.json.template` |
| CLAUDE.md | `template/CLAUDE.md` |
| Secrets | `.env` |

## Adding a New Command

1. Create `template/.claude/commands/custom-name.md`
2. Add frontmatter:
   ```yaml
   ---
   description: "One-liner for help menu"
   targets: ["*"]
   ---
   ```
3. Run `./sync-rules.sh sync`

## Adding a New MCP Server

1. Edit `template/.rulesync/mcp.json.template`
2. Add secrets to `.env` if needed
3. Run `./sync-rules.sh mcp`

## Building Blocks Toggle

Edit `scripts/lib/building-blocks.sh`:
```bash
ENABLE_SPECKIT=true    # .specify templates
ENABLE_RULESYNC=true   # rules, .aiignore
```

Note: Commands, hooks, agents are always synced to global `~/.claude/`

## Troubleshooting

```bash
# Check what's wrong
./scripts/check.sh

# Fix automatically
./scripts/check.sh --fix

# Regenerate MCP configs
./sync-rules.sh mcp

# Full re-sync
./sync-rules.sh sync
```
