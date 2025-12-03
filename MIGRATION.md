# SuperClaude to diet103 Migration

## Overview

This document tracks the removal of SuperClaude commands in preparation for diet103 integration.

**Migration Date:** December 3, 2025

## What Was Removed

### SuperClaude Commands (30 files)

All SuperClaude commands have been removed from `template/.rulesync/commands/`:

1. agent.md
2. analyze.md
3. brainstorm.md
4. build.md
5. business-panel.md
6. cleanup.md
7. design.md
8. document.md
9. estimate.md
10. explain.md
11. git.md
12. help.md
13. implement.md
14. improve.md
15. index-repo.md
16. index.md
17. load.md
18. pm.md
19. recommend.md
20. reflect.md
21. research.md
22. save.md
23. sc.md (main dispatcher)
24. select-tool.md
25. spawn.md
26. spec-panel.md
27. task.md
28. test.md
29. troubleshoot.md
30. workflow.md

### Files Preserved

The following custom and SpecKit commands were preserved:

- custom-refactor.md
- custom-upgrade.md
- All speckit.* commands (if present)

## Backup Location

All removed files have been backed up to:

```
/Users/joachimbrindeau/Development/global/backups/superclaude-20251203/
```

## Code Changes

### sync-rules.sh

The `update_superclaude()` function has been disabled:

```bash
# Update SuperClaude commands from Claude Code
# DISABLED: SuperClaude has been replaced by diet103
update_superclaude() {
    # SuperClaude commands are no longer synced
    # This function is disabled as part of diet103 migration
    return 0
}
```

This prevents the function from syncing SuperClaude commands from `~/.claude/commands/sc/` to the template directory.

## Impact

### What Still Works

- Custom commands (custom-refactor, custom-upgrade)
- SpecKit commands
- MCP synchronization
- Rulesync functionality
- Project initialization and sync

### What Was Removed

- All `/sc:*` commands (e.g., `/sc:research`, `/sc:analyze`, `/sc:implement`)
- SuperClaude main dispatcher (`/sc`)
- Automatic sync of SuperClaude commands from `~/.claude/commands/sc/`

## Next Steps

1. Integrate diet103 infrastructure
2. Map diet103 commands to replace SuperClaude functionality
3. Update documentation to reference diet103 instead of SuperClaude
4. Remove SuperClaude references from CLAUDE.md and other documentation files

## Rollback Instructions

If you need to restore SuperClaude commands:

```bash
# Restore from backup
cp backups/superclaude-20251203/*.md template/.rulesync/commands/

# Re-enable update_superclaude() in sync-rules.sh
# (Manually edit the function to restore original behavior)

# Sync to all projects
./sync-rules.sh sync
```

## Notes

- The original SuperClaude commands in `~/.claude/commands/sc/` remain untouched
- Only the template directory commands were removed
- This prevents propagation of SuperClaude commands to new and existing projects
- Existing projects will retain their SuperClaude commands until the next sync
