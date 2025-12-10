---
description: "Generate comprehensive library feature documentation for AI consumption"
targets: ["*"]
---

# /custom-libdoc - Library Feature Documentation Generator

> **Mission**: Generate AI-optimized library documentation by combining Context7, npm, and web sources. Output one feature per line for easy scanning.

## Usage

```bash
/custom-libdoc <library>[@version]
```

**Examples**:
- `/custom-libdoc lodash`
- `/custom-libdoc react@18`
- `/custom-libdoc @types/node`
- `/custom-libdoc express --quick`

---

## Pre-Flight Protocol

**CRITICAL**: Ensure output directory exists:

```bash
mkdir -p ~/.claude/library-docs
```

**Parse input**:
- Extract library name and optional version from argument
- Sanitize for filename: `@scope/pkg` → `scope-pkg.md`

---

## Execution Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    PHASE 1: DISCOVERY                       │
│                   [Parallel Subagents]                      │
│                                                             │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ 📚 CONTEXT7      │  │ 📦 NPM           │                │
│  │    RESEARCHER    │  │    INSPECTOR     │                │
│  │                  │  │                  │                │
│  │ • Resolve lib ID │  │ • Package details│                │
│  │ • Get code docs  │  │ • Keywords       │                │
│  │ • Get info docs  │  │ • Description    │                │
│  └──────────────────┘  └──────────────────┘                │
│                                                             │
│  ┌──────────────────┐                                      │
│  │ 🌐 WEB           │                                      │
│  │    HARVESTER     │                                      │
│  │                  │                                      │
│  │ • Official docs  │                                      │
│  │ • GitHub README  │                                      │
│  │ • Feature lists  │                                      │
│  └──────────────────┘                                      │
│                                                             │
│  Output: Raw features from all sources                      │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    PHASE 2: ANALYSIS                        │
│                   [Sequential]                              │
│                                                             │
│  🔍 FEATURE EXTRACTOR → 🧹 DEDUPLICATOR                     │
│                                                             │
│  • Normalize feature names                                  │
│  • Categorize by type (Array, Object, String, etc.)        │
│  • Remove duplicates across sources                         │
│  • Limit to 15 features per category                        │
│                                                             │
│  Output: Deduplicated, categorized feature list             │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    PHASE 3: GENERATION                      │
│                   [Sequential]                              │
│                                                             │
│  📝 DOCUMENT GENERATOR → 💾 FILE WRITER                     │
│                                                             │
│  Output: ~/.claude/library-docs/LIBRARY_NAME.md             │
└─────────────────────────────────────────────────────────────┘
```

---

## Subagent Definitions

<subagents>
<agent name="CONTEXT7_RESEARCHER" emoji="📚">
<mission>Fetch structured documentation from Context7 MCP</mission>
<process>
1. Call `mcp__context7__resolve-library-id` with library name
2. Select best match by benchmark score
3. Call `mcp__context7__get-library-docs` with mode='code'
4. Call `mcp__context7__get-library-docs` with mode='info'
5. Iterate through pages if content is paginated
6. Extract function names, methods, API patterns
</process>
<output>Structured feature list with method signatures</output>
<fallback>If not found in Context7, return empty with flag for other sources</fallback>
</agent>

<agent name="NPM_INSPECTOR" emoji="📦">
<mission>Extract package metadata and infer capabilities</mission>
<process>
1. Call `mcp__npm-helper__get_package_details` with package name
2. Extract: description, keywords, version, license, repository
3. Parse description for feature hints
4. Use keywords as capability indicators
5. Check for TypeScript support (@types or bundled)
</process>
<output>Package metadata + inferred features from keywords/description</output>
<fallback>If package not found, suggest similar names</fallback>
</agent>

<agent name="WEB_HARVESTER" emoji="🌐">
<mission>Scrape official docs and GitHub for feature lists</mission>
<process>
1. Search: `mcp__jina__search_web` "{library} official documentation features"
2. Search: `mcp__jina__search_web` "{library} GitHub README"
3. Read top 3 results with `mcp__jina__read_url`
4. Extract bullet points, feature sections, API tables
5. Focus on "Features", "Capabilities", "API Reference" sections
</process>
<output>Feature lists from official sources</output>
<fallback>If no official docs, rely on GitHub README only</fallback>
</agent>
</subagents>

---

## Feature Extraction Rules

**Include**:
- Function/method names with brief description
- Core capabilities (e.g., "Tree-shakeable", "TypeScript support")
- API categories (e.g., "Array Methods", "HTTP Client")
- Configuration options
- Plugin/middleware support

**Exclude**:
- Generic marketing phrases ("Popular library", "Well-maintained")
- Installation instructions (covered separately)
- Version history
- Contributor information

**Format**:
- One feature per line
- Use backticks for method names: `debounce()`
- Keep descriptions under 10 words
- Group by category

---

## Output Document Template

```markdown
# {Library} v{version}

> {One-line description from npm}

**Updated**: {ISO timestamp} | **Sources**: {sources used}

---

## Core Capabilities
- {High-level capability 1}
- {High-level capability 2}
- {High-level capability 3}

---

## Features

### {Category 1}
- `method1()` - {brief description}
- `method2()` - {brief description}
- `method3()`

### {Category 2}
- `feature1` - {brief description}
- `feature2`

---

## Quick Start

```bash
npm install {library}
# or
pnpm add {library}
```

---

## TypeScript

{YES - bundled types | YES - @types/{library} | NO}

---

## Metadata
- **Package**: {name}
- **Version**: {version}
- **License**: {license}
- **Repository**: {url}
- **Documentation**: {docs url}
- **Context7 ID**: {id or "Not available"}

---

## Generation Info
- **Generated**: {timestamp}
- **Command**: `/custom-libdoc {input}`
- **Sources**: {list of sources that provided data}
```

---

## File Writing Protocol

**Target**: `~/.claude/library-docs/{SANITIZED_NAME}.md`

**Filename Rules**:
- Lowercase the library name
- Replace `@` with empty string
- Replace `/` with `-`
- Examples:
  - `lodash` → `lodash.md`
  - `@types/node` → `types-node.md`
  - `@tanstack/react-query` → `tanstack-react-query.md`

**Behavior**:
- If file exists: **Overwrite** (no `-v2` variants)
- Always update timestamp
- Preserve no manual edits (regenerate from scratch)

---

## Execution Modes

### Default
Full analysis with all three sources. Best for first-time documentation.

### `--quick`
Context7 + npm only. Skip web scraping. Faster but less comprehensive.

### `--update`
Force refresh even if file was recently generated.

---

## Error Handling

### Library Not Found
```
Library "{input}" not found in any source.

Suggestions:
- Check spelling
- Try without version: /custom-libdoc {name}
- Search npm: npm search {input}
```

### Partial Data
```
Generated with partial data.
Missing: {source}
Available: {sources}
```

### No Features Extracted
Create minimal doc with metadata only and link to external docs.

---

## Success Output

```
Library documentation generated

File: ~/.claude/library-docs/{name}.md
Package: {name}@{version}
Features: {count} documented
Sources: {list}

View: cat ~/.claude/library-docs/{name}.md
Update: /custom-libdoc {name} --update
```

---

## Constraints

<constraints>
<rule>Always write to ~/.claude/library-docs/ - no other locations</rule>
<rule>One file per library - overwrite existing, never create duplicates</rule>
<rule>Maximum 15 features per category for readability</rule>
<rule>One feature per line - no multi-line descriptions</rule>
<rule>Prioritize Context7 data when sources conflict</rule>
<rule>Include generation timestamp for freshness tracking</rule>
<rule>Skip --quick mode web scraping entirely, don't fall back</rule>
</constraints>
