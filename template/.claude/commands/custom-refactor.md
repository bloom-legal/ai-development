---
description: "Launch parallel refactoring subagents to systematically clean and improve codebase quality"
targets: ["*"]
---

# /custom-refactor - Parallel Refactoring Army

> **Mission**: Fast, systematic codebase refactoring through parallel subagent waves ensuring zero regressions.

## Pre-Flight Safety Protocol

**CRITICAL**: Execute before ANY refactoring:

```bash
# 1. Verify clean working tree
git status --porcelain
```

**If NOT empty:**
- 🛑 STOP and ask: "Commit changes before refactoring? [y/n]"
- If yes: `git commit -am "chore: pre-refactor checkpoint"`
- If no: abort

```bash
# 2. Create safety branch
git checkout -b refactor/$(date +%Y%m%d-%H%M%S)

# 3. Verify tests pass
npm test || pnpm test || yarn test || bun test
```

**If tests fail**: 🛑 STOP - Fix tests first.

---

## Parallel Execution Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    WAVE 0: FOUNDATION                       │
│                   [Sequential - Required]                   │
│                                                             │
│  🔍 DEAD CODE HUNTER → 🏗️ STRUCTURE ARCHITECT              │
│                                                             │
│  Commit: "refactor: remove dead code and reorganize"        │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    WAVE 1: SEMANTICS                        │
│                   [Parallel Subagents]                      │
│                                                             │
│  ┌──────────────────┐    ┌──────────────────┐              │
│  │ 🏷️ NAMING        │    │ 🔒 TYPE          │              │
│  │    GUARDIAN      │    │    GUARDIAN      │              │
│  │                  │    │                  │              │
│  │ • Variables      │    │ • Remove any     │              │
│  │ • Functions      │    │ • Add returns    │              │
│  │ • Booleans       │    │ • Strict null    │              │
│  └──────────────────┘    └──────────────────┘              │
│                                                             │
│  Commit: "refactor: improve naming and type safety"         │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    WAVE 2: ARCHITECTURE                     │
│                   [Parallel Subagents]                      │
│                                                             │
│  ┌──────────────────┐    ┌──────────────────┐              │
│  │ 📦 DRY           │    │ 🎯 SOLID         │              │
│  │    ENFORCER      │    │    ENFORCER      │              │
│  │                  │    │                  │              │
│  │ • Dedup code     │    │ • Split large    │              │
│  │ • Extract utils  │    │ • DI patterns    │              │
│  │ • Shared hooks   │    │ • Interfaces     │              │
│  └──────────────────┘    └──────────────────┘              │
│                                                             │
│  Commit: "refactor: consolidate and apply SOLID"            │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    WAVE 3: POLISH                           │
│                   [Parallel Subagents]                      │
│                                                             │
│  ┌──────────────────┐    ┌──────────────────┐              │
│  │ 🧹 STYLE         │    │ 📝 IMPORT        │              │
│  │    ENFORCER      │    │    OPTIMIZER     │              │
│  │                  │    │                  │              │
│  │ • async/await    │    │ • Sort imports   │              │
│  │ • Early returns  │    │ • Remove unused  │              │
│  │ • Modern syntax  │    │ • Fix circular   │              │
│  └──────────────────┘    └──────────────────┘              │
│                                                             │
│  Commit: "refactor: polish style and optimize imports"      │
└─────────────────────────────────────────────────────────────┘
```

---

## Subagent Definitions

### 🔍 DEAD CODE HUNTER
**Targets:** Unused imports/exports, unreachable code, commented code, unused deps
**Tools:** `npx knip`, `npx depcheck`

### 🏗️ STRUCTURE ARCHITECT  
**Targets:** Misplaced files, deep hierarchies (max 3), empty dirs
**Naming:** `kebab-case` folders, `PascalCase` components, `camelCase` utils

### 🏷️ NAMING GUARDIAN
**Targets:** Expressive names, boolean prefixes (`is/has/can/should`), action verbs
**Pattern:** Find → Determine meaning → Replace ALL atomically

### 🔒 TYPE GUARDIAN
**Targets:** Replace `any` with proper types, explicit returns, strict null checks
**Tools:** `npx tsc --noEmit --strict`

### 📦 DRY ENFORCER
**Targets:** Duplicate blocks (>5 lines), repeated patterns, copy-paste components
**Rule:** Abstract only if used 3+ times

### 🎯 SOLID ENFORCER
**Targets:** Single responsibility (max 50 lines/fn, 300 lines/file), DI, interfaces
**Pattern:** Split → Extract → Inject

### 🧹 CODE STYLE ENFORCER
**Targets:** `.then()` → `async/await`, `var` → `const/let`, optional chaining
**Tools:** `npx eslint --fix .`, `npx prettier --write .`

### 📝 IMPORT OPTIMIZER
**Targets:** Unused imports, sort order, circular deps
**Tools:** `npx madge --circular --extensions ts,tsx src/`

---

## Execution Protocol

### Wave Execution
```
For each wave:
  1. Spawn parallel subagents using Task tool
  2. Each subagent works on distinct file sets to avoid conflicts
  3. Wait for all subagents to complete
  4. Merge results and resolve any conflicts
  5. Run tests: npm test
  6. If pass: commit wave
  7. If fail: fix regressions before proceeding
```

### Parallel Task Spawning Pattern
```
Task: "NAMING GUARDIAN - Analyze and rename identifiers in src/features/"
Task: "TYPE GUARDIAN - Strengthen types in src/features/"
```

### File Set Partitioning
To avoid conflicts, partition by domain:
- Subagent A: `src/features/auth/**`
- Subagent B: `src/features/users/**`  
- Subagent C: `src/shared/**`

---

## Execution Modes

### `--full` (default)
All 4 waves with parallel subagents within each wave.

### `--quick`
Wave 0 (dead code + structure) + Wave 3 (style + imports) only.

### `--safe`
Run tests after EACH subagent, auto-revert on failure.

### `--dry-run`
Analyze and report, no modifications.

### `--focus [wave]`
Run specific wave only: `foundation`, `semantics`, `architecture`, `polish`

### `--sequential`
Disable parallelism, run all agents one by one (slower but safer).

---

## Post-Refactoring Validation

```bash
npm test && npx tsc --noEmit && npx eslint . && npm run build
```

### Summary Report
```
## Refactoring Complete

### Wave Results
- Wave 0: X files cleaned, Y files moved
- Wave 1: X identifiers renamed, Y types fixed  
- Wave 2: X abstractions created, Y violations fixed
- Wave 3: X files formatted, Y imports optimized

### Commits (4 total)
1. refactor: remove dead code and reorganize
2. refactor: improve naming and type safety
3. refactor: consolidate and apply SOLID
4. refactor: polish style and optimize imports

### Status: ✅ All checks passing
```

---

## Abort Protocol

On critical issue:
1. 🛑 STOP all subagents
2. `git stash` uncommitted changes
3. Report issue and wait for user decision
4. Rollback option: `git checkout main && git branch -D refactor/*`

---

## Performance Tips

- **Parallel tool calls**: Always batch file reads/greps when analyzing
- **Domain partitioning**: Split work by feature folders to avoid merge conflicts
- **Incremental commits**: 4 wave commits vs 8 agent commits = faster
- **Early termination**: `--quick` mode for time-sensitive refactors
