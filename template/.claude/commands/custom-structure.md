---
description: "Review folder and file structure for cleanliness, organization, and naming. Generate comprehensive improvement plan."
targets: ["*"]
---

# /custom-structure - Structure Review & Improvement Planner

> **Mission**: Analyze project structure for cleanliness, logical organization, and naming conventions. Generate a long-term perfection plan.

## Pre-Flight Protocol

**CRITICAL**: Execute before analysis:

```bash
# 1. Verify we're at project root
ls -la package.json || ls -la Cargo.toml || ls -la go.mod || ls -la docker-compose.yml || ls -la Makefile
```

**If no project markers found:**
- STOP and ask: "This doesn't appear to be a project root. Continue anyway? [y/n]"

---

## Analysis Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    PHASE 1: DISCOVERY                       │
│                   [Sequential - Required]                   │
│                                                             │
│  🗺️ STRUCTURE MAPPER → 🔍 PROJECT IDENTIFIER               │
│                                                             │
│  Output: Complete tree + project type classification        │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    PHASE 2: AUDIT                           │
│                   [Parallel Subagents]                      │
│                                                             │
│  ┌──────────────────┐    ┌──────────────────┐              │
│  │ 🏷️ NAMING        │    │ 📂 ORGANIZATION  │              │
│  │    AUDITOR       │    │    AUDITOR       │              │
│  │                  │    │                  │              │
│  │ • File casing    │    │ • Root clutter   │              │
│  │ • Dir patterns   │    │ • Depth issues   │              │
│  │ • Extensions     │    │ • Orphan files   │              │
│  └──────────────────┘    └──────────────────┘              │
│                                                             │
│  ┌──────────────────┐    ┌──────────────────┐              │
│  │ 🔄 REDUNDANCY    │    │ 📋 STANDARDS     │              │
│  │    DETECTOR      │    │    CHECKER       │              │
│  │                  │    │                  │              │
│  │ • Duplicate cfg  │    │ • README presence│              │
│  │ • Dead files     │    │ • Config/data    │              │
│  │ • AI tool bloat  │    │ • Src/build sep  │              │
│  └──────────────────┘    └──────────────────┘              │
│                                                             │
│  Output: Issues table with severity ratings                 │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    PHASE 3: PLANNING                        │
│                   [Sequential - Required]                   │
│                                                             │
│  📐 ARCHITECT → 📝 DOCUMENTER                               │
│                                                             │
│  Output: STRUCTURE_PLAN.md with full migration roadmap      │
└─────────────────────────────────────────────────────────────┘
```

---

## Subagent Definitions

<subagents>
<agent name="STRUCTURE_MAPPER" emoji="🗺️"><mission>Map complete directory tree with metadata</mission><commands><cmd>tree -L 5 --dirsfirst -a --noreport</cmd><cmd>find . -type f | wc -l</cmd><cmd>find . -type d | wc -l</cmd><cmd>find . -type f -name ".*" | head -20</cmd></commands><output>Full tree structure with file/dir counts</output></agent>
<agent name="PROJECT_IDENTIFIER" emoji="🔍"><mission>Classify project type and expected structure</mission><detection><type name="node">package.json</type><type name="rust">Cargo.toml</type><type name="go">go.mod</type><type name="python">pyproject.toml, setup.py, requirements.txt</type><type name="docker">docker-compose.yml, Dockerfile</type><type name="monorepo">packages/, apps/, pnpm-workspace.yaml</type></detection><output>Project type + expected canonical structure</output></agent>
<agent name="NAMING_AUDITOR" emoji="🏷️"><mission>Audit naming conventions for consistency</mission><checks><check name="files">kebab-case for configs, PascalCase for components, camelCase for utils</check><check name="dirs">lowercase, plural for collections (components/, utils/), singular for domains (auth/, user/)</check><check name="extensions">.yml vs .yaml, .ts vs .tsx, .js vs .mjs consistency</check><check name="antipatterns">-new, -v2, -copy, -backup, -old, .bak suffixes</check></checks><output>Naming violations list with suggested corrections</output></agent>
<agent name="ORGANIZATION_AUDITOR" emoji="📂"><mission>Audit structural organization</mission><checks><check name="root_clutter">Count root files, identify candidates for subdirectories</check><check name="depth">Flag depth > 4, identify flattening opportunities</check><check name="orphans">Files that don't belong with siblings</check><check name="empty">Empty directories to remove or populate</check><check name="hidden">Consolidation opportunities for .claude, .cursor, .roo, .specify, .rulesync</check></checks><output>Organization issues with recommended moves</output></agent>
<agent name="REDUNDANCY_DETECTOR" emoji="🔄"><mission>Find duplicate and dead content</mission><checks><check name="configs">Duplicate configs across directories</check><check name="generated">node_modules, dist, build, .cache in wrong places or ungitignored</check><check name="dead">Commented files, unused configs, orphaned tests</check><check name="backup">.bak, .backup, .old files to delete</check></checks><output>Redundancy list with delete/consolidate recommendations</output></agent>
<agent name="STANDARDS_CHECKER" emoji="📋"><mission>Verify adherence to project structure standards</mission><checks><check name="readme">README.md at root and major directories</check><check name="config_data">Stateful services have config/ and data/ separation</check><check name="src_build">Source and build output are separated</check><check name="tests">Test files colocated or in dedicated __tests__/ folder consistently</check><check name="gitignore">.gitignore covers generated files, secrets, IDE configs</check></checks><output>Standards compliance report</output></agent>
</subagents>

---

## Output Document Structure

<document path="STRUCTURE_PLAN.md">
<section name="Executive Summary">One paragraph overview of current state and primary recommendations</section>
<section name="Current State"><subsection name="Tree">Full annotated tree with issue markers (⚠️ ❌ ✅)</subsection><subsection name="Statistics">File count, dir count, depth stats, extension breakdown</subsection><subsection name="Project Type">Detected type and expected canonical structure</subsection></section>
<section name="Issues Found"><table><columns>Location | Issue Type | Severity | Description | Recommendation</columns><severity_levels>🔴 CRITICAL | 🟡 WARNING | 🔵 SUGGESTION</severity_levels></table></section>
<section name="Target Structure"><subsection name="Proposed Tree">Ideal structure with rationale comments</subsection><subsection name="Naming Standards">Conventions to adopt going forward</subsection></section>
<section name="Migration Plan"><subsection name="Phase 1">Critical fixes (delete dead files, remove backups)</subsection><subsection name="Phase 2">Structural moves (git mv commands)</subsection><subsection name="Phase 3">Consolidation (merge configs, dedupe)</subsection><subsection name="Phase 4">Polish (rename for consistency)</subsection></section>
<section name="Maintenance Guidelines"><subsection name="Gitignore Additions">Lines to add</subsection><subsection name="Pre-commit Hooks">Optional enforcement</subsection><subsection name="CI Checks">Optional automated validation</subsection></section>
</document>

---

## Execution Modes

### `--full` (default)
Complete analysis with all subagents, generate full STRUCTURE_PLAN.md.

### `--quick`
Discovery + Naming + Organization only. Skip redundancy deep scan.

### `--focus [path]`
Analyze specific directory only (e.g., `--focus src/`).

### `--dry-run`
Print findings to console, don't create STRUCTURE_PLAN.md.

### `--severity [level]`
Filter output: `critical`, `warning`, `all` (default: all).

---

## Constraints

<constraints>
<rule>DO NOT execute any file operations - analysis and planning only</rule>
<rule>Respect git history - all move recommendations use `git mv`</rule>
<rule>Flag subjective decisions for user input rather than auto-deciding</rule>
<rule>Consider backwards compatibility for public APIs, URLs, import paths</rule>
<rule>Preserve working functionality - never recommend breaking changes without migration path</rule>
</constraints>

---

## Example Issue Table

```markdown
| Location | Issue | Severity | Description | Recommendation |
|----------|-------|----------|-------------|----------------|
| `.env.bak` | Backup file | 🔴 | Backup file at root | Delete or add to .gitignore |
| `services/grafana/` | Missing README | 🟡 | No documentation | Add README.md |
| `logs/` | Ungitignored | 🔵 | Logs committed to repo | Add to .gitignore |
| `.claude/hooks/node_modules/` | Generated in repo | 🔴 | Dependencies committed | Delete + gitignore |
```

---

## Post-Analysis

After generating STRUCTURE_PLAN.md:
1. Review plan with user
2. If approved, offer to execute Phase 1 (safe deletions)
3. Subsequent phases require explicit confirmation
