# Development Principles

Principles only. Implementation details belong in project-specific skills.

## Core Principles

### DRY - Don't Repeat Yourself
Eliminate redundancy. If code exists, use it. If it's duplicated, consolidate it.

### KISS - Keep It Simple
Favor simple, clear solutions. Complexity is a cost, not a feature.

### YAGNI - You Aren't Gonna Need It
No speculative features. Build what's needed now, not what might be needed later.

## Dependencies & Libraries

### Prefer Libraries Over Custom Code
Use well-maintained libraries instead of writing custom implementations. Less code to maintain = fewer bugs.

### Always Use Latest Versions
Before installing any dependency:
1. Check the latest version using Context7 or npm
2. Install the latest stable version
3. Never install outdated versions

### Library Documentation Workflow
Before implementing with any library:
1. **Check local docs first**: Read `~/.claude/library-docs/{library-name}.md` if it exists
2. **Generate if missing**: Run `/custom-libdoc {library}` to create documentation
3. **Fall back to Context7**: Use Context7 MCP for real-time queries not covered in local docs

Local docs are AI-optimized summaries with features, methods, and quick-start info. Always prefer them over raw Context7 queries for faster context loading.

## Quality Mandate

### Never Skip, Never Downgrade
- Never bypass problems with workarounds
- Never downgrade to "make it work"
- Always fix the root cause
- Always improve what you touch

### Refactor Relentlessly
Refactoring is not optional. When you see:
- Duplication: consolidate
- Complexity: simplify
- Dead code: delete
- Outdated patterns: modernize

### Edit Over Create
Always edit existing files. Never create:
- `-new`, `-v2`, `-fixed`, `-enhanced`, `-copy` variants
- Duplicate implementations
- Parallel solutions

### Clean Code Only
- No commented-out code (delete it or create an issue)
- No console.log in production (use proper logging)
- No fallback mechanisms or backwards compatibility layers
