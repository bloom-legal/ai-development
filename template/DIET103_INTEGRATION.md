# diet103 Claude Code Infrastructure Integration

This template integrates production-tested hooks, skills, and agents from [diet103's Claude Code Infrastructure Showcase](https://github.com/diet103/claude-code-infrastructure-showcase).

## What Was Integrated

### 1. Hooks (Auto-Activation System)

Location: `.claude/hooks/`

**Essential Hooks:**
- `skill-activation-prompt.sh` + `skill-activation-prompt.ts` - Auto-activates skills based on user prompts and file context
- `post-tool-use-tracker.sh` - Tracks tool usage for skill enforcement
- `package.json` - Hook dependencies (TypeScript, tsx)
- `tsconfig.json` - TypeScript configuration for hooks

**Dependencies Installed:**
```json
{
  "@types/node": "^20.11.0",
  "tsx": "^4.7.0",
  "typescript": "^5.3.3"
}
```

### 2. Skills (Production Patterns)

Location: `.claude/skills/`

**5 Production-Ready Skills:**

1. **backend-dev-guidelines/** - Node.js/Express/TypeScript patterns
   - Services & repositories
   - Routing & controllers
   - Database patterns (Prisma)
   - Middleware & validation
   - Configuration management
   - Error handling & Sentry
   - Architecture overview

2. **frontend-dev-guidelines/** - React/TypeScript/MUI v7 patterns
   - Component patterns
   - Styling guide (MUI v7 compatible)
   - TypeScript standards
   - Data fetching
   - Routing
   - Performance optimization
   - Loading & error states
   - File organization

3. **route-tester/** - API testing with authentication
   - JWT cookie-based auth testing
   - Route testing patterns

4. **error-tracking/** - Sentry integration patterns
   - Error tracking setup
   - Performance monitoring

5. **skill-developer/** - Meta-skill for creating new skills
   - Skill development guide
   - Hook system documentation
   - Skill rules configuration

**Skill Rules Configuration:**
- `skill-rules.json` - Defines activation triggers for all skills
  - Keyword matching
  - Intent pattern recognition (regex)
  - File path triggers
  - Content pattern matching
  - Enforcement modes: suggest, block, warn

### 3. Agents (Specialized Assistants)

Location: `.claude/agents/`

**3 Useful Agents:**

1. **code-architecture-reviewer.md** - Reviews system architecture
2. **refactor-planner.md** - Plans code refactoring strategies
3. **auto-error-resolver.md** - Diagnoses and resolves errors

## Configuration

### settings.json

The template includes a configured `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Edit:*",
      "Write:*",
      "MultiEdit:*",
      "NotebookEdit:*",
      "Bash:*"
    ],
    "defaultMode": "acceptEdits"
  },
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/skill-activation-prompt.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|MultiEdit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/post-tool-use-tracker.sh"
          }
        ]
      }
    ]
  }
}
```

### How Hooks Work

1. **UserPromptSubmit Hook** - Runs before Claude processes your prompt
   - Analyzes your prompt keywords and intent
   - Checks if you're editing specific file types
   - Suggests relevant skills automatically

2. **PostToolUse Hook** - Runs after Claude uses Edit/Write tools
   - Tracks which files were modified
   - Can enforce guardrails (e.g., frontend-dev-guidelines blocks MUI v6 patterns)
   - Maintains session state for skill usage

## Customization

### Modify Skill Triggers

Edit `.claude/skills/skill-rules.json` to customize when skills activate:

```json
{
  "skills": {
    "your-skill-name": {
      "type": "domain",           // or "guardrail"
      "enforcement": "suggest",    // suggest, block, or warn
      "priority": "high",          // critical, high, medium, low
      "promptTriggers": {
        "keywords": ["api", "endpoint"],
        "intentPatterns": ["(create|add).*?(route|endpoint)"]
      },
      "fileTriggers": {
        "pathPatterns": ["src/**/*.ts"],
        "contentPatterns": ["router\\."]
      }
    }
  }
}
```

### Add Your Own Skills

1. Create a new directory in `.claude/skills/`
2. Add a `SKILL.md` with your skill content
3. Add entry to `skill-rules.json` with triggers
4. Test with sample prompts

Example structure:
```
.claude/skills/
├── your-skill-name/
│   ├── SKILL.md              # Main skill content
│   └── resources/            # Additional resources
│       ├── patterns.md
│       └── examples.md
```

### Adjust Path Patterns

The default skills assume these project structures:
- Backend: `blog-api/src/`, `auth-service/src/`, `backend/`, `api/`, `server/`
- Frontend: `frontend/src/`, `client/src/`, `src/`

To customize for your project:

1. Edit `.claude/skills/skill-rules.json`
2. Update `pathPatterns` to match your structure:
   ```json
   "fileTriggers": {
     "pathPatterns": [
       "packages/api/**/*.ts",
       "apps/backend/**/*.ts"
     ]
   }
   ```

## File Structure Created

```
template/.claude/
├── agents/
│   ├── auto-error-resolver.md
│   ├── code-architecture-reviewer.md
│   └── refactor-planner.md
├── commands/                     # (existing)
├── hooks/
│   ├── node_modules/
│   ├── package-lock.json
│   ├── package.json
│   ├── post-tool-use-tracker.sh  (executable)
│   ├── skill-activation-prompt.sh (executable)
│   ├── skill-activation-prompt.ts
│   └── tsconfig.json
├── memories/                     # (existing)
├── skills/
│   ├── backend-dev-guidelines/
│   │   ├── SKILL.md
│   │   └── resources/
│   │       ├── architecture-overview.md
│   │       ├── async-and-errors.md
│   │       ├── complete-examples.md
│   │       ├── configuration.md
│   │       ├── database-patterns.md
│   │       ├── middleware-guide.md
│   │       ├── routing-and-controllers.md
│   │       ├── sentry-and-monitoring.md
│   │       └── services-and-repositories.md
│   ├── frontend-dev-guidelines/
│   │   ├── SKILL.md
│   │   └── resources/
│   │       ├── common-patterns.md
│   │       ├── complete-examples.md
│   │       ├── component-patterns.md
│   │       ├── data-fetching.md
│   │       ├── file-organization.md
│   │       ├── loading-and-error-states.md
│   │       ├── performance.md
│   │       ├── routing-guide.md
│   │       ├── styling-guide.md
│   │       └── typescript-standards.md
│   ├── route-tester/
│   ├── error-tracking/
│   ├── skill-developer/
│   ├── README.md
│   └── skill-rules.json
├── settings.json
└── settings.local.json
```

## Usage Examples

### Example 1: Backend Development

When you say:
> "Create a new user service with repository pattern"

The hook automatically suggests `backend-dev-guidelines` skill because:
- Keywords match: "service", "repository"
- Intent pattern matches: "create.*service"

### Example 2: Frontend Guardrails

When you edit a `.tsx` file containing MUI Grid code:
> "Update the user profile component"

If you try to use deprecated MUI v6 patterns (e.g., `<Grid xs={6}>`), the `frontend-dev-guidelines` skill will **block** the edit and remind you to use MUI v7 syntax (`<Grid size={6}>`).

### Example 3: Manual Skill Usage

You can always invoke skills manually:
```
/skill backend-dev-guidelines
```

## Testing the Integration

1. **Test hook activation:**
   ```bash
   cd .claude/hooks
   npm run check  # TypeScript compilation check
   ```

2. **Test skill activation:**
   - Open a project
   - Say "create a new API endpoint"
   - Should see backend-dev-guidelines suggestion

3. **Verify file structure:**
   ```bash
   ls -la .claude/hooks/
   ls -la .claude/skills/
   ls -la .claude/agents/
   ```

## Troubleshooting

### Hooks Not Running

1. Check that scripts are executable:
   ```bash
   chmod +x .claude/hooks/*.sh
   ```

2. Verify dependencies are installed:
   ```bash
   cd .claude/hooks && npm install
   ```

3. Check Claude Code settings recognize the hooks:
   ```bash
   cat .claude/settings.json
   ```

### Skills Not Activating

1. Check `skill-rules.json` syntax:
   ```bash
   cat .claude/skills/skill-rules.json | jq .
   ```

2. Verify skill directories have `SKILL.md` files
3. Check path patterns match your project structure

### TypeScript Errors in Hooks

```bash
cd .claude/hooks
npm run check
```

## Benefits

### Auto-Activation
- No need to remember to use skills
- Context-aware suggestions
- Proactive guidance

### Guardrails
- Prevent deprecated patterns (e.g., MUI v6)
- Enforce best practices
- Block problematic code before commit

### Production-Tested
- Patterns from real projects
- Comprehensive coverage
- Battle-tested in diet103's workflow

## Credits

Infrastructure sourced from: https://github.com/diet103/claude-code-infrastructure-showcase

Created by diet103, integrated into this template for universal use.

## Next Steps

1. Review `.claude/skills/README.md` for skill system overview
2. Customize `skill-rules.json` for your project structure
3. Add project-specific skills as needed
4. Review agent files in `.claude/agents/` for specialized workflows

## License

Original infrastructure: MIT License (diet103)
Template integration: Same license as this template
