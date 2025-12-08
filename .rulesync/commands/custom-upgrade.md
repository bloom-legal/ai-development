---
description: "Upgrade all dependencies to latest versions with compatibility checks and breaking change fixes"
targets: ["*"]
---

# /custom-upgrade - Dependency Upgrade Army

> **Mission**: Safely upgrade all dependencies to latest versions, detect breaking changes, and fix them automatically.

## Pre-Flight Safety Protocol

**CRITICAL**: Execute before ANY upgrades:

```bash
# 1. Verify clean working tree
git status --porcelain
```

**If NOT empty:**
- 🛑 STOP and ask: "Commit changes before upgrading? [y/n]"
- If yes: `git commit -am "chore: pre-upgrade checkpoint"`
- If no: abort

```bash
# 2. Create safety branch
git checkout -b upgrade/$(date +%Y%m%d-%H%M%S)

# 3. Verify tests pass (baseline)
npm test || pnpm test || yarn test || bun test

# 4. Verify build works (baseline)
npm run build || pnpm build || yarn build || bun run build
```

**If baseline fails**: 🛑 STOP - Fix existing issues first.

---

## Upgrade Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    PHASE 1: ANALYSIS                        │
│                   [Parallel Subagents]                      │
│                                                             │
│  ┌──────────────────┐    ┌──────────────────┐              │
│  │ 📊 AUDIT         │    │ 📚 CHANGELOG     │              │
│  │    ANALYZER      │    │    RESEARCHER    │              │
│  │                  │    │                  │              │
│  │ • List outdated  │    │ • Fetch changelogs│             │
│  │ • Check vulns    │    │ • Identify breaks │             │
│  │ • Map deps       │    │ • Document migration│           │
│  └──────────────────┘    └──────────────────┘              │
│                                                             │
│  Output: Upgrade plan with risk assessment                  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    PHASE 2: UPGRADE                         │
│                   [Sequential by Risk]                      │
│                                                             │
│  Low Risk → Medium Risk → High Risk → Breaking Changes      │
│                                                             │
│  Each step: Upgrade → Test → Fix → Commit                   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    PHASE 3: FIXES                           │
│                   [Parallel Subagents]                      │
│                                                             │
│  ┌──────────────────┐    ┌──────────────────┐              │
│  │ 🔧 TYPE          │    │ 🔄 API           │              │
│  │    FIXER         │    │    MIGRATOR      │              │
│  │                  │    │                  │              │
│  │ • Fix type errors│    │ • Update imports │              │
│  │ • Update generics│    │ • Rename methods │              │
│  │ • Add missing    │    │ • Update params  │              │
│  └──────────────────┘    └──────────────────┘              │
│                                                             │
│  Commit: "fix: resolve breaking changes from upgrades"      │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    PHASE 4: VALIDATION                      │
│                   [Sequential - Required]                   │
│                                                             │
│  TypeCheck → Lint → Test → Build → E2E (if available)       │
│                                                             │
│  Commit: "chore: upgrade dependencies to latest versions"   │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Analysis Subagents

### 📊 AUDIT ANALYZER
**Mission**: Map all dependencies and identify upgrade candidates

**Commands:**
```bash
# Detect package manager
if [ -f "pnpm-lock.yaml" ]; then PM="pnpm"; 
elif [ -f "yarn.lock" ]; then PM="yarn";
elif [ -f "bun.lockb" ]; then PM="bun";
else PM="npm"; fi

# List outdated packages
$PM outdated --json 2>/dev/null || $PM outdated

# Security audit
$PM audit --json 2>/dev/null || $PM audit

# Dependency tree analysis
$PM list --depth=0
```

**Output Format:**
```
Package          Current   Wanted    Latest    Risk Level
────────────────────────────────────────────────────────
react            18.2.0    18.2.0    19.0.0    🔴 HIGH (major)
typescript       5.3.0     5.3.0     5.6.0     🟡 MEDIUM (minor)
lodash           4.17.21   4.17.21   4.17.21   🟢 LOW (patch)
```

### 📚 CHANGELOG RESEARCHER
**Mission**: Research breaking changes for major upgrades

**For each major upgrade:**
1. Fetch changelog via Context7 MCP or npm info
2. Identify breaking changes
3. Document migration steps required
4. Estimate fix complexity

**Output Format:**
```markdown
## react 18.2.0 → 19.0.0

### Breaking Changes
- [ ] `ReactDOM.render` removed, use `createRoot`
- [ ] Automatic batching behavior changed
- [ ] New JSX transform required

### Migration Steps
1. Update ReactDOM.render calls
2. Review useEffect dependencies
3. Update testing-library

### Estimated Effort: 2-4 hours
```

---

## Phase 2: Upgrade Strategy

### Risk-Based Upgrade Order

**🟢 LOW RISK (Patch versions)**
```bash
# Upgrade all patch versions at once
$PM update  # Updates to latest within semver range
```
Commit: `chore(deps): update patch versions`

**🟡 MEDIUM RISK (Minor versions)**
```bash
# Upgrade minor versions one category at a time
# 1. Dev dependencies first (lower risk)
$PM add -D typescript@latest eslint@latest prettier@latest

# 2. Test after each batch
$PM test
```
Commit: `chore(deps): update minor versions`

**🔴 HIGH RISK (Major versions)**
```bash
# Upgrade one major version at a time
# Order by dependency (upgrade peer deps first)

# Example: React ecosystem
$PM add react@latest react-dom@latest
$PM add @types/react@latest @types/react-dom@latest
$PM test
# Fix any issues before proceeding
```
Commit per major: `chore(deps): upgrade [package] to v[X]`

---

## Phase 3: Breaking Change Fixers

### 🔧 TYPE FIXER
**Mission**: Fix TypeScript errors after upgrades

**Detection:**
```bash
npx tsc --noEmit 2>&1 | head -100
```

**Common Fixes:**
| Error Pattern | Fix |
|--------------|-----|
| `Property 'X' does not exist` | Add to interface or use optional chaining |
| `Type 'X' is not assignable` | Update type annotation or add type assertion |
| `Generic type requires N arguments` | Add missing type parameters |
| `Module has no exported member` | Update import to new export name |

**Auto-Fix Pattern:**
```typescript
// Before: Property 'userId' does not exist on type 'Session'
session.userId

// After: Add optional chaining or type guard
(session as AuthSession).userId
// OR update Session interface
```

### 🔄 API MIGRATOR  
**Mission**: Update code to new API patterns

**Common Migrations:**

**React 18 → 19:**
```typescript
// Before
import ReactDOM from 'react-dom';
ReactDOM.render(<App />, document.getElementById('root'));

// After
import { createRoot } from 'react-dom/client';
createRoot(document.getElementById('root')!).render(<App />);
```

**Next.js 14 → 15:**
```typescript
// Before: pages/api/route.ts
export default function handler(req, res) { }

// After: app/api/route/route.ts
export async function GET(request: Request) { }
```

**Express 4 → 5:**
```typescript
// Before
app.del('/resource/:id', handler);

// After  
app.delete('/resource/:id', handler);
```

**Prisma:**
```typescript
// Before
await prisma.user.findOne({ where: { id } });

// After
await prisma.user.findUnique({ where: { id } });
```

---

## Phase 4: Validation Pipeline

```bash
# 1. Type Check
npx tsc --noEmit
if [ $? -ne 0 ]; then echo "❌ Type errors"; exit 1; fi

# 2. Lint
npx eslint . --max-warnings 0
if [ $? -ne 0 ]; then echo "❌ Lint errors"; exit 1; fi

# 3. Unit Tests
$PM test
if [ $? -ne 0 ]; then echo "❌ Test failures"; exit 1; fi

# 4. Build
$PM run build
if [ $? -ne 0 ]; then echo "❌ Build failed"; exit 1; fi

# 5. E2E Tests (if available)
if [ -f "playwright.config.ts" ] || [ -f "cypress.config.ts" ]; then
  $PM run test:e2e
fi

echo "✅ All validations passed"
```

---

## Execution Modes

### `--full` (default)
Upgrade everything: patches → minors → majors with full fix cycle.

### `--safe`
Only patches and minors. Skip major version upgrades.

### `--security`
Only upgrade packages with known vulnerabilities.

### `--dry-run`
Analyze and report what would be upgraded, no changes.

### `--interactive`
Ask for confirmation before each major upgrade.

### `--focus [package]`
Upgrade specific package and its peer dependencies only.

---

## Package-Specific Strategies

### React Ecosystem
```
Order: react → react-dom → @types/react → react-router → state-management
```

### Next.js
```
Order: next → react → eslint-config-next → @next/* packages
Note: Check next.config.js for deprecated options
```

### TypeScript
```
Order: typescript → @types/* → ts-node → build tools
Note: May require tsconfig.json updates
```

### Testing Libraries
```
Order: jest/vitest → @testing-library/* → msw → cypress/playwright
Note: Check for deprecated matchers
```

### Build Tools
```
Order: vite/webpack → plugins → loaders
Note: Config file format may change
```

---

## Rollback Protocol

If upgrades cause unfixable issues:

```bash
# Option 1: Revert specific package
$PM add package@previous-version

# Option 2: Revert all changes
git checkout -- package.json package-lock.json
$PM install

# Option 3: Full rollback
git checkout main
git branch -D upgrade/*
```

---

## Summary Report

```markdown
## Upgrade Summary

### Packages Upgraded
- 🟢 Patches: 12 packages
- 🟡 Minors: 8 packages  
- 🔴 Majors: 3 packages

### Breaking Changes Fixed
- TypeScript errors: 23 fixed
- API migrations: 5 completed
- Config updates: 2 files

### Security
- Vulnerabilities before: 4 (2 high, 2 moderate)
- Vulnerabilities after: 0

### Commits Created
1. `chore(deps): update patch versions`
2. `chore(deps): update minor versions`
3. `chore(deps): upgrade react to v19`
4. `fix: resolve react 19 breaking changes`
5. `chore(deps): upgrade typescript to v5.6`

### Validation Status
- [x] TypeScript: clean
- [x] ESLint: clean
- [x] Tests: 142/142 passing
- [x] Build: success
- [x] E2E: 28/28 passing
```

---

## Context7 MCP Integration

For each major upgrade, use Context7 to fetch:
- Official migration guides
- Breaking change documentation
- New API patterns and best practices

```
Query: "How to migrate from [package] v[old] to v[new]"
```

---

## Performance Tips

- **Parallel analysis**: Run audit and changelog research simultaneously
- **Batch patches**: Upgrade all patch versions in one commit
- **Cache research**: Store migration guides for common packages
- **Incremental validation**: Test after each major upgrade, not at the end
