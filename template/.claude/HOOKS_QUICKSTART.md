# Claude Code Hooks & Skills - Quick Start

## What Are Hooks?

Hooks automatically run at specific points in your Claude Code workflow:
- **Before** Claude sees your prompt (UserPromptSubmit)
- **After** Claude edits files (PostToolUse)
- **When** Claude stops responding (Stop)

## Installed Hooks

### 1. Skill Auto-Activation
**When:** Before each prompt
**What:** Analyzes your prompt and suggests relevant skills

Example:
```
You: "Create a new API endpoint for users"
Hook: Detects "API", "endpoint" → Suggests backend-dev-guidelines skill
```

### 2. File Modification Tracker
**When:** After Edit/Write operations
**What:** Tracks which files were changed, enforces guardrails

Example:
```
Claude: [Edits UserProfile.tsx with MUI v6 syntax]
Hook: Detects deprecated pattern → Blocks edit → Suggests MUI v7 syntax
```

## Installed Skills

### Backend Development
- **Trigger:** "API", "endpoint", "service", "repository", "controller"
- **Path:** `.claude/skills/backend-dev-guidelines/`
- **Use when:** Building Node.js/Express/TypeScript backends

### Frontend Development
- **Trigger:** "component", "React", "MUI", "UI", "page"
- **Path:** `.claude/skills/frontend-dev-guidelines/`
- **Use when:** Building React/TypeScript frontends
- **Special:** Blocks deprecated MUI patterns

### Route Testing
- **Trigger:** "test route", "API testing", "JWT", "auth"
- **Path:** `.claude/skills/route-tester/`
- **Use when:** Testing authenticated endpoints

### Error Tracking
- **Trigger:** "error handling", "Sentry", "monitoring"
- **Path:** `.claude/skills/error-tracking/`
- **Use when:** Setting up error tracking

### Skill Developer
- **Trigger:** "create skill", "skill system"
- **Path:** `.claude/skills/skill-developer/`
- **Use when:** Creating new skills

## Manual Skill Usage

You can always invoke skills manually:

```bash
/skill backend-dev-guidelines
/skill frontend-dev-guidelines
/skill route-tester
/skill error-tracking
/skill skill-developer
```

## Customization

### Change When Skills Activate

Edit `.claude/skills/skill-rules.json`:

```json
{
  "skills": {
    "backend-dev-guidelines": {
      "promptTriggers": {
        "keywords": ["api", "endpoint", "YOUR_KEYWORD"],
        "intentPatterns": ["(create|add).*?(route|endpoint)"]
      },
      "fileTriggers": {
        "pathPatterns": ["YOUR_PROJECT/src/**/*.ts"]
      }
    }
  }
}
```

### Add Your Own Skill

1. Create directory: `.claude/skills/my-skill/`
2. Add `SKILL.md` with content
3. Add to `skill-rules.json`:
   ```json
   {
     "skills": {
       "my-skill": {
         "type": "domain",
         "enforcement": "suggest",
         "priority": "high",
         "promptTriggers": {
           "keywords": ["my", "keywords"]
         }
       }
     }
   }
   ```

## Troubleshooting

### "Hooks not running"
```bash
# Make hooks executable
chmod +x .claude/hooks/*.sh

# Reinstall dependencies
cd .claude/hooks && npm install
```

### "Skills not suggesting"
1. Check your keywords match `skill-rules.json`
2. Update path patterns to match your project
3. Try manual invocation: `/skill skill-name`

### "TypeScript errors in hooks"
```bash
cd .claude/hooks
npm run check
```

## Learn More

- Full documentation: `../DIET103_INTEGRATION.md`
- Skill system: `.claude/skills/README.md`
- Agents: `.claude/agents/*.md`

## Quick Tips

1. **Let hooks work** - They'll suggest skills automatically
2. **Trust guardrails** - If frontend-dev-guidelines blocks an edit, there's a good reason
3. **Customize paths** - Update `skill-rules.json` to match your project structure
4. **Create skills** - Use `/skill skill-developer` to learn how
