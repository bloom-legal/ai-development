# AI Development Environment

One-command setup for AI-assisted development on Mac. Installs and configures Cursor, Claude Code CLI, and MCP servers.

## Quick Start

**Fresh Mac (one-click, no prompts):**
```bash
curl -fsSL https://raw.githubusercontent.com/bloom-legal/ai-development/main/bootstrap.sh | bash
```

**Existing clone (interactive menu):**
```bash
./scripts/install.sh
```

## What Gets Installed

- **Homebrew** - Package manager
- **Node.js** - Required for MCP servers
- **VS Code** - Editor
- **Cursor** - AI-powered editor
- **Claude Code CLI** - Terminal AI assistant
- **jq, uv** - Dependencies for MCP servers

## MCP Servers

Pre-configured Model Context Protocol servers synced to Cursor, Claude Desktop, and Roo Code:

| Server | Description |
|--------|-------------|
| context7 | Library documentation lookup |
| sequential-thinking | Step-by-step reasoning |
| npm-helper | NPM package search and updates |
| postgres | PostgreSQL database queries |
| docker | Docker container management |
| puppeteer | Browser automation |
| jina | Web search and URL reading |
| portainer | Portainer stack management |
| chrome-devtools | Chrome debugging via CDP |

## Configuration

The bootstrap one-liner skips secrets configuration for a truly hands-free install. To configure MCP server secrets later, run the interactive installer:

```bash
./scripts/install.sh
```

This prompts for optional secrets:

```
Configure MCP server secrets (press Enter to skip, 's' to skip all):

PostgreSQL connection [user:pass@host:port/db]:
Portainer server hostname:
Portainer API token:
```

Press Enter to skip any value. Re-run anytime to update secrets.

## Commands

```bash
./scripts/install.sh                    # Interactive installation with menu
./scripts/install.sh --auto             # Install all, prompt for secrets
./scripts/install.sh --auto --skip-secrets  # Install all, no prompts (one-click)
./scripts/uninstall.sh                  # Interactive uninstall with checklist
./scripts/check.sh                      # Verify setup
./scripts/check.sh --fix                # Auto-fix issues
./sync-rules.sh mcp             # Sync MCP configs to all tools
./sync-rules.sh sync            # Sync rules + commands to projects
```

## File Structure

```
.env.example                      # Template for secrets
.env                              # Your secrets (gitignored)
template/.rulesync/
  mcp.json.template               # MCP config with $VAR placeholders
  mcp.json                        # Generated config (gitignored)
```

## How It Works

1. `mcp.json.template` contains MCP server configs with `$VAR` placeholders
2. `install.sh` / `sync-rules.sh` loads `.env` and generates `mcp.json` via envsubst
3. Generated config is synced to:
   - `~/.cursor/mcp.json`
   - `~/Library/Application Support/Claude/claude_desktop_config.json`
   - Roo Code global settings
