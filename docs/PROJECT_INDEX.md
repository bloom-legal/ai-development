# Global - Project Index

> AI Development Environment Configuration Distribution System

## Overview

**Purpose**: One-command setup and synchronization of AI-assisted development tools across 56+ projects on Mac.

**Core Function**: Distributes standardized configurations for Claude Code, Cursor, and Roo Code editors, including MCP servers, rules, commands, hooks, and agents.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        GLOBAL REPO                              │
│                   (Source of Truth)                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  template/                    ← Source templates                │
│  ├── .claude/                 ← Claude Code config              │
│  │   ├── agents/              ← AI agent definitions            │
│  │   ├── hooks/               ← Pre/post tool hooks             │
│  │   └── settings.json        ← Hooks configuration             │
│  ├── .cursor/rules/           ← Cursor rules                    │
│  ├── .rulesync/               ← Distribution configs            │
│  │   ├── commands/            ← Custom slash commands           │
│  │   ├── rules/               ← Shared AI rules                 │
│  │   └── mcp.json.template    ← MCP server config               │
│  ├── .specify/                ← SpecKit templates               │
│  └── CLAUDE.md                ← Global AI instructions          │
│                                                                 │
│  scripts/                     ← Modular utilities               │
│  ├── bash/lib/                ← Shell modules                   │
│  └── project-sync/            ← JS sync utilities               │
│                                                                 │
│  *.sh                         ← CLI entry points                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ sync-rules.sh
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    GLOBAL CONFIGS                               │
│              (Shared across all projects)                       │
├─────────────────────────────────────────────────────────────────┤
│  ~/.claude/                   ← Claude Code (KISS)              │
│  │   ├── commands/            ← Slash commands                  │
│  │   ├── hooks/               ← Pre/post tool hooks             │
│  │   ├── agents/              ← Agent definitions               │
│  │   └── CLAUDE.md            ← Development principles          │
│  ~/.cursor/mcp.json           ← Cursor MCP config               │
│  ~/.claude.json               ← Claude Code MCP config          │
│  ~/Library/.../mcp_settings   ← Roo Code MCP config             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ sync-rules.sh sync
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   PROJECT CONFIGS                               │
│              (Cursor/Roo only - ~/Development/*)                │
├─────────────────────────────────────────────────────────────────┤
│  project/                                                       │
│  ├── .cursor/rules/           ← Cursor rules                    │
│  ├── .roo/rules/              ← Roo Code rules                  │
│  ├── .rulesync/               ← Rulesync config                 │
│  └── rulesync.jsonc           ← Project config                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Building Blocks

KISS architecture: global configs for Claude Code, per-project for Cursor/Roo.

| Scope | What | Location |
|-------|------|----------|
| **Global** | Commands, Hooks, Agents | `~/.claude/` |
| **Global** | MCP Servers | `~/.cursor/mcp.json`, `~/.claude.json` |
| **Per-Project** | Rules, .aiignore | `.rulesync/` (Cursor/Roo only) |
| **Per-Project** | SpecKit | `.specify/` |

Configuration in [scripts/lib/building-blocks.sh](scripts/lib/building-blocks.sh):
```bash
ENABLE_SPECKIT=true    # SpecKit templates
ENABLE_RULESYNC=true   # Rules for Cursor/Roo
```

---

## CLI Scripts

### Primary Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| [install.sh](install.sh) | Interactive installation | `./install.sh` |
| [uninstall.sh](uninstall.sh) | Clean removal | `./uninstall.sh` |
| [sync-rules.sh](sync-rules.sh) | Sync configs to projects | `./sync-rules.sh sync` |
| [check.sh](check.sh) | Verify setup | `./check.sh --fix` |
| [bootstrap.sh](bootstrap.sh) | One-liner fresh install | `curl ... \| bash` |

### sync-rules.sh Commands

```bash
./sync-rules.sh sync    # Full sync: MCPs + rules + commands to all projects
./sync-rules.sh mcp     # MCPs only to global configs
./sync-rules.sh init    # Initialize new projects
./sync-rules.sh clean   # Remove local MCP configs
./sync-rules.sh update  # Update tools and sync
```

---

## MCP Servers

Pre-configured Model Context Protocol servers:

| Server | Purpose | Secret Required |
|--------|---------|-----------------|
| context7 | Library documentation | No |
| sequential-thinking | Step-by-step reasoning | No |
| npm-helper | NPM package management | No |
| docker | Container management | No |
| puppeteer | Browser automation | No |
| jina | Web search/reading | Optional |
| postgres | Database queries | Yes |
| portainer | Stack management | Yes |
| chrome-devtools | Chrome debugging | No |
| github | GitHub API | Yes |
| google-workspace | Gmail/Calendar/Drive | Yes |

Configuration: [template/.rulesync/mcp.json.template](template/.rulesync/mcp.json.template)

---

## Custom Commands

Slash commands distributed to all projects:

| Command | Purpose | Location |
|---------|---------|----------|
| `/custom-libdoc` | Generate library feature docs | [custom-libdoc.md](template/.claude/commands/custom-libdoc.md) |
| `/custom-upgrade` | Safe dependency upgrades | [custom-upgrade.md](template/.claude/commands/custom-upgrade.md) |
| `/custom-refactor` | Parallel codebase refactoring | [custom-refactor.md](template/.claude/commands/custom-refactor.md) |
| `/custom-structure` | Project structure analysis | [custom-structure.md](template/.claude/commands/custom-structure.md) |
| `/custom-watchtower` | Docker auto-update config | [custom-watchtower.md](template/.claude/commands/custom-watchtower.md) |
| `/custom-initiate` | SpecKit initialization | [custom-initiate.md](template/.claude/commands/custom-initiate.md) |

---

## Hooks

Claude Code hooks in `~/.claude/hooks/` (global):

### post-tool-use-tracker.sh
- **Trigger**: After Edit, MultiEdit, Write tools
- **Purpose**: Track edited files for batch validation

### skill-activation-prompt.sh
- **Trigger**: On user prompt submission
- **Purpose**: Auto-suggest relevant commands based on context

---

## Agents

Pre-defined AI agent configurations:

| Agent | Purpose |
|-------|---------|
| [auto-error-resolver.md](template/.claude/agents/auto-error-resolver.md) | Automatic error diagnosis and fixing |
| [code-architecture-reviewer.md](template/.claude/agents/code-architecture-reviewer.md) | Architecture review and suggestions |
| [refactor-planner.md](template/.claude/agents/refactor-planner.md) | Refactoring strategy planning |

---

## Shell Modules

Modular bash libraries in [scripts/lib/](scripts/lib/):

| Module | Purpose |
|--------|---------|
| [common.sh](scripts/lib/common.sh) | Shared utilities, colors, logging |
| [building-blocks.sh](scripts/lib/building-blocks.sh) | Modular sync functions |
| [mcp-manager.sh](scripts/lib/mcp-manager.sh) | MCP config generation |
| [mcp-setup.sh](scripts/lib/mcp-setup.sh) | MCP server installation |
| [installation.sh](scripts/lib/installation.sh) | Tool installation |
| [tui.sh](scripts/lib/tui.sh) | Terminal UI components |

---

## Configuration Files

### Root Level

| File | Purpose |
|------|---------|
| `.env` | Secrets (gitignored) |
| `.env.example` | Secret template |
| `rulesync.jsonc` | This project's rulesync config |

### Template Level

| File | Purpose |
|------|---------|
| `template/CLAUDE.md` | Global AI instructions |
| `template/rulesync.jsonc` | Template rulesync config |
| `template/.rulesync/mcp.json.template` | MCP config with $VAR placeholders |

---

## Sync Flow

```
1. User runs: ./sync-rules.sh sync

2. Pre-flight check (check.sh)
   ↓
3. GLOBAL sync (once):
   - ~/.claude/commands/ ← template commands
   - ~/.claude/hooks/ ← tool hooks
   - ~/.claude/agents/ ← agent definitions
   - ~/.claude/CLAUDE.md ← principles
   - ~/.cursor/mcp.json ← MCP servers
   - ~/.claude.json ← Claude Code MCP
   ↓
4. PER-PROJECT sync (Cursor/Roo only):
   - .rulesync/rules/ ← AI rules
   - .rulesync/commands/ ← commands
   - npx rulesync generate
   ↓
5. Done! Global + 56 projects synced
```

---

## Development Principles

From [template/CLAUDE.md](template/CLAUDE.md):

- **DRY**: Don't Repeat Yourself
- **KISS**: Keep It Simple
- **YAGNI**: You Aren't Gonna Need It
- **Libraries over custom code**: Use well-maintained packages
- **Latest versions always**: Never install outdated deps
- **Edit over create**: Never create `-new`, `-v2` variants
- **Clean code only**: No commented code, no console.log

---

## Quick Reference

```bash
# Fresh Mac setup (one command)
curl -fsSL https://raw.githubusercontent.com/bloom-legal/ai-development/main/bootstrap.sh | bash

# Interactive install
./install.sh

# Sync everything
./sync-rules.sh sync

# Verify setup
./check.sh

# Fix issues
./check.sh --fix

# Sync MCPs only
./sync-rules.sh mcp
```

---

## File Tree

```
global/
├── docs/                       # Documentation
├── scripts/
│   ├── lib/                    # Shell modules
│   └── js/                     # JS utilities
├── template/                   # SOURCE OF TRUTH
│   ├── .claude/                # Claude Code (synced to ~/.claude/)
│   │   ├── commands/           # Slash commands
│   │   ├── agents/             # Agent definitions
│   │   ├── hooks/              # Tool hooks
│   │   └── settings.json       # Hooks config
│   ├── .rulesync/              # Cursor/Roo (per-project)
│   │   ├── rules/              # AI rules
│   │   └── mcp.json.template   # MCP template
│   ├── .specify/               # SpecKit templates
│   └── CLAUDE.md               # Development principles
├── sync-rules.sh               # Main sync script
├── check.sh                    # Verification
└── install.sh                  # Interactive installer
```

---

*Generated by /sc:index on 2025-12-10*
