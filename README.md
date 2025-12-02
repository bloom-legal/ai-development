# AI Development Environment

One-command setup for AI-assisted development on Mac. Installs and configures Cursor, Claude Code CLI, and MCP servers.

## Quick Start

**Fresh Mac (one-liner):**
```bash
curl -fsSL https://raw.githubusercontent.com/bloom-legal/ai-development/main/bootstrap.sh | bash
```

**Existing clone:**
```bash
./install.sh
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

The install script prompts for secrets interactively:

```
Configure MCP server secrets (press Enter to skip/keep current):

PostgreSQL connection [user:pass@host:port/db]:
Portainer server hostname:
Portainer API token:
```

Press Enter to skip any value. Re-run `./install.sh` anytime to update secrets.

## Commands

```bash
./install.sh          # Full installation
./check.sh            # Verify setup
./check.sh --fix      # Auto-fix issues
./sync-rules.sh mcp   # Sync MCP configs to all tools
./sync-rules.sh sync  # Sync rules + commands to projects
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
