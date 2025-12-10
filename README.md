# AI Development Environment

One-command setup for AI-assisted development on Mac.

## Quick Start

Set up Claude Code and essential dev tools with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/joachimbrindeau/global/main/scripts/setup.sh | bash
```

That's it! The script will install everything you need for AI-assisted development.

### Requirements

- **macOS Monterey (12.0) or newer**
- Internet connection
- Admin password (for Homebrew installation)

### What Gets Installed

| Tool | Purpose |
|------|---------|
| Homebrew | macOS package manager |
| Node.js | JavaScript runtime |
| VS Code | Code editor |
| Cursor | AI-powered editor |
| jq | JSON processor |
| uv | Python package manager |
| Claude Code | AI coding assistant (CLI) |

The script is **idempotent**—safe to run multiple times. It skips already-installed components.

---

## Advanced Setup

For MCP server configuration and additional options:

**Interactive installer:**
```bash
./scripts/install.sh
```

This provides:
- MCP server secrets configuration
- Sync to Cursor, Claude Desktop, and Roo Code

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

## Troubleshooting

### Quick Start Script Issues

| Issue | Solution |
|-------|----------|
| "Permission denied" | Don't use `sudo`. Enter your password when prompted by Homebrew |
| "Command not found: claude" | Open a **new** terminal window after installation |
| "Network error" | Check internet connection; retry in a few minutes |
| "Unsupported macOS" | Requires macOS Monterey (12.0) or newer |
| Script hangs | Check network; Homebrew download can take several minutes |

### Re-running the Setup

The setup script is **idempotent**—safe to run multiple times:
- Already-installed components are skipped
- No duplicate PATH entries are added
- Claude Code is updated if a newer version exists

If something went wrong, simply run the command again:

```bash
curl -fsSL https://raw.githubusercontent.com/joachimbrindeau/global/main/scripts/setup.sh | bash
```

### Getting Help

- Open an issue: https://github.com/joachimbrindeau/global/issues
- Check Claude Code docs: https://claude.ai/docs

---

## How It Works

1. `mcp.json.template` contains MCP server configs with `$VAR` placeholders
2. `install.sh` / `sync-rules.sh` loads `.env` and generates `mcp.json` via envsubst
3. Generated config is synced to:
   - `~/.cursor/mcp.json`
   - `~/Library/Application Support/Claude/claude_desktop_config.json`
   - Roo Code global settings
