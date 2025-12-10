# Global - Project Index

> AI Development Environment - Global Configuration

## Overview

**Purpose**: Global configs for Claude Code and Cursor - no per-project sync.

**Architecture**: Everything syncs to `~/.claude/` and `~/.cursor/` once.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     TEMPLATE (Source)                           │
├─────────────────────────────────────────────────────────────────┤
│  template/                                                      │
│  ├── .claude/                                                   │
│  │   ├── commands/         Slash commands                       │
│  │   ├── hooks/            Tool hooks                           │
│  │   ├── agents/           Agent definitions                    │
│  │   └── settings.json     Hooks config                         │
│  ├── .rulesync/                                                 │
│  │   └── mcp.json.template MCP server config                    │
│  └── CLAUDE.md             Development principles               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ ./sync-rules.sh
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     GLOBAL CONFIGS                              │
├─────────────────────────────────────────────────────────────────┤
│  ~/.claude/                                                     │
│  ├── commands/             Slash commands                       │
│  ├── hooks/                Tool hooks                           │
│  ├── agents/               Agent definitions                    │
│  └── CLAUDE.md             Development principles               │
│                                                                 │
│  ~/.cursor/mcp.json        MCP servers (Cursor)                 │
│  ~/.claude.json            MCP servers (Claude Code)            │
│                                                                 │
│  Cursor Settings           User Rules (paste CLAUDE.md)         │
└─────────────────────────────────────────────────────────────────┘
```

---

## CLI Usage

```bash
./sync-rules.sh              # Sync all global configs
./sync-rules.sh mcp          # Sync MCP servers only
./sync-rules.sh speckit PATH # Initialize SpecKit in project
./scripts/install.sh         # Interactive setup
./scripts/check.sh           # Verify setup
```

---

## MCP Servers

| Server | Purpose |
|--------|---------|
| context7 | Library documentation |
| sequential-thinking | Step-by-step reasoning |
| npm-helper | NPM package management |
| docker | Container management |
| puppeteer | Browser automation |
| postgres | Database queries |
| portainer | Stack management |
| github | GitHub API |

Config: [template/.rulesync/mcp.json.template](../template/.rulesync/mcp.json.template)

---

## Commands

| Command | Purpose |
|---------|---------|
| `/custom-libdoc` | Generate library docs |
| `/custom-upgrade` | Safe dependency upgrades |
| `/custom-refactor` | Parallel refactoring |
| `/custom-structure` | Project structure analysis |

Location: [template/.claude/commands/](../template/.claude/commands/)

---

## Hooks

| Hook | Trigger |
|------|---------|
| post-tool-use-tracker | After file edits |
| skill-activation-prompt | On user prompt |

Location: [template/.claude/hooks/](../template/.claude/hooks/)

---

## Shell Modules

| Module | Purpose |
|--------|---------|
| common.sh | Utilities, logging |
| building-blocks.sh | Sync functions |
| mcp.sh | MCP config |
| installation.sh | Tool installation |
| tui.sh | Terminal UI |

Location: [scripts/lib/](../scripts/lib/)

---

## File Tree

```
global/
├── sync-rules.sh            # Main CLI
├── bootstrap.sh             # Remote install
├── scripts/
│   ├── install.sh           # Interactive setup
│   ├── uninstall.sh         # Clean removal
│   ├── check.sh             # Verify setup
│   └── lib/                 # Shell modules
├── template/
│   ├── .claude/             # → ~/.claude/
│   │   ├── commands/
│   │   ├── hooks/
│   │   └── agents/
│   ├── .rulesync/
│   │   └── mcp.json.template
│   └── CLAUDE.md
└── docs/
```

---

## Cursor Setup

Cursor uses **User Rules** (global):

1. Open Cursor → Settings → Rules → User Rules
2. Paste content from `template/CLAUDE.md`
3. Done - applies to all projects

---

*Updated 2025-12-10*
