# Claude Code Permissions Configuration

Your default permissions are now configured for maximum productivity with minimal interruptions.

## 🚀 Permission Mode: `bypassPermissions` (YOLO Mode)

All allowed tools execute **automatically without prompts**.

## ✅ Allowed Tools (15 categories)

### File Operations
- `Edit:*` - Edit existing files
- `Write:*` - Create new files
- `MultiEdit:*` - Batch edit multiple files
- `NotebookEdit:*` - Edit Jupyter notebooks

### Execution
- `Bash:*` - Execute shell commands

### Exploration & Research
- `Read:*` - Read any file
- `Glob:*` - Find files by pattern
- `Grep:*` - Search file contents
- `Task:*` - Launch specialized agents (explore, plan, etc.)

### Web Access
- `WebSearch:*` - Search the web
- `WebFetch:*` - Fetch web content

### Project Management
- `TodoWrite:*` - Track tasks
- `Skill:*` - Execute skills
- `SlashCommand:*` - Run custom commands

### MCP Tools
- `mcp__*` - All MCP server tools (context7, jina, puppeteer, docker, postgres, etc.)

## 🎯 Benefits

### For Regular Mode
- **No approval prompts** for read operations (Read, Glob, Grep)
- **Auto-execute** web searches and fetches
- **Instant** task/agent launching
- **Fast** file exploration

### For Plan Mode
- **Full access** to exploration tools
- **No interruptions** during codebase analysis
- **Automatic** file reading and searching
- **Seamless** agent delegation

## 📊 Before vs After

| Operation | Before | After |
|-----------|--------|-------|
| Read file | ❓ Prompt | ✅ Auto |
| Search code | ❓ Prompt | ✅ Auto |
| Launch agent | ❓ Prompt | ✅ Auto |
| Web search | ❓ Prompt | ✅ Auto |
| File edit | ✅ Auto | ✅ Auto |
| Bash command | ✅ Auto | ✅ Auto |

## 🔧 Configuration

**Location**: `.claude/settings.json` in each project

```json
{
  "permissions": {
    "allow": [
      "Edit:*",
      "Write:*",
      "MultiEdit:*",
      "NotebookEdit:*",
      "Bash:*",
      "Read:*",
      "Glob:*",
      "Grep:*",
      "Task:*",
      "WebSearch:*",
      "WebFetch:*",
      "TodoWrite:*",
      "Skill:*",
      "SlashCommand:*",
      "mcp__*"
    ],
    "defaultMode": "bypassPermissions"
  }
}
```

## 🔐 Security Notes

- Permissions are **project-scoped** to `$CLAUDE_PROJECT_DIR`
- Sandbox mode still applies to Bash commands (unless explicitly disabled)
- MCP tools inherit their own security boundaries
- Git operations still require explicit confirmation for destructive actions

## 🔄 Updating Permissions

To add/remove tools from the allow list:

1. Edit `~/Development/global/template/.claude/settings.json`
2. Run `./auto-sync.sh` or `./sync-rules.sh sync`
3. Changes propagate to all 49 projects

## 💡 Available Permission Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| `bypassPermissions` | Auto-execute all allowed tools | **Current** - Maximum productivity |
| `acceptEdits` | Auto-accept file edits only | Safer for destructive operations |
| `default` | Prompt for everything | Maximum control |
| `dontAsk` | Never prompt (deprecated) | Legacy mode |
| `plan` | Plan mode only | Exploration without execution |

## 📝 Notes

- Current mode synced to **49/49 projects**
- Auto-sync ensures consistency across all projects
- No more approval fatigue during exploration
- Plan mode can now fully explore codebases without interruption
