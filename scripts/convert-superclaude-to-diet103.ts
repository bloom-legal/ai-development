#!/usr/bin/env npx tsx

/**
 * SuperClaude → DIET103 Converter
 *
 * Converts SuperClaude command files into DIET103-compatible skills
 * with corresponding skill-rules.json entries for auto-activation.
 *
 * Usage:
 *   npx tsx scripts/convert-superclaude-to-diet103.ts
 *   npx tsx scripts/convert-superclaude-to-diet103.ts --dry-run
 *   npx tsx scripts/convert-superclaude-to-diet103.ts --command implement
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync } from 'fs';
import { join, basename } from 'path';

// ============================================================================
// CONFIGURATION
// ============================================================================

const SUPERCLAUDE_DIR = join(process.env.HOME || '', 'Development/global/backups/superclaude-20251203');
const SKILLS_DIR = join(process.env.HOME || '', 'Development/global/template/.claude/skills');
const SKILL_RULES_PATH = join(process.env.HOME || '', 'Development/global/template/.claude/skill-rules.json');

// Commands to skip (meta/utility commands)
const SKIP_COMMANDS = ['help.md', 'sc.md', 'load.md', 'save.md', 'reflect.md', 'select-tool.md'];

// Priority mapping based on command type
const PRIORITY_MAP: Record<string, 'critical' | 'high' | 'medium' | 'low'> = {
    'implement': 'critical',
    'analyze': 'high',
    'design': 'high',
    'test': 'high',
    'troubleshoot': 'high',
    'build': 'high',
    'cleanup': 'medium',
    'improve': 'medium',
    'document': 'medium',
    'explain': 'medium',
    'estimate': 'low',
    'brainstorm': 'low',
    'research': 'medium',
    'workflow': 'medium',
    'git': 'low',
    'index': 'low',
    'index-repo': 'low',
    'pm': 'medium',
    'recommend': 'low',
    'spawn': 'medium',
    'spec-panel': 'medium',
    'business-panel': 'medium',
    'task': 'medium',
    'agent': 'high',
};

// ============================================================================
// TYPES
// ============================================================================

interface SuperClaudeCommand {
    name: string;
    description: string;
    triggers: string[];
    behavioralFlow: string[];
    mcpIntegration: string[];
    toolCoordination: string[];
    keyPatterns: string[];
    examples: string[];
    boundaries: { will: string[]; willNot: string[] };
    rawContent: string;
}

interface SkillRule {
    type: 'domain' | 'guardrail' | 'workflow';
    enforcement: 'suggest' | 'block' | 'warn';
    priority: 'critical' | 'high' | 'medium' | 'low';
    description: string;
    promptTriggers: {
        keywords: string[];
        intentPatterns: string[];
    };
}

interface SkillRulesFile {
    version: string;
    description: string;
    skills: Record<string, SkillRule>;
    notes: Record<string, unknown>;
}

// ============================================================================
// PARSER
// ============================================================================

function parseSuperclaude(content: string, filename: string): SuperClaudeCommand {
    const name = basename(filename, '.md');

    // Extract YAML frontmatter
    const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---/);
    let description = '';
    if (frontmatterMatch) {
        const descMatch = frontmatterMatch[1].match(/description:\s*["']?([^"'\n]+)["']?/);
        if (descMatch) description = descMatch[1].trim();
    }

    // Extract triggers section
    const triggersMatch = content.match(/## Triggers\n([\s\S]*?)(?=\n## |\n#+ |$)/);
    const triggers = triggersMatch
        ? triggersMatch[1].split('\n').filter(l => l.startsWith('- ')).map(l => l.replace(/^- /, '').trim())
        : [];

    // Extract behavioral flow
    const flowMatch = content.match(/## Behavioral Flow\n([\s\S]*?)(?=\n## |\n#+ |$)/);
    const behavioralFlow = flowMatch
        ? flowMatch[1].split('\n').filter(l => /^\d+\./.test(l) || l.startsWith('- ')).map(l => l.replace(/^\d+\.\s*\*\*|\*\*/g, '').trim())
        : [];

    // Extract MCP integration
    const mcpMatch = content.match(/## MCP Integration\n([\s\S]*?)(?=\n## |\n#+ |$)/);
    const mcpIntegration = mcpMatch
        ? mcpMatch[1].split('\n').filter(l => l.startsWith('- ')).map(l => l.replace(/^- \*\*|\*\*/g, '').trim())
        : [];

    // Extract tool coordination
    const toolMatch = content.match(/## Tool Coordination\n([\s\S]*?)(?=\n## |\n#+ |$)/);
    const toolCoordination = toolMatch
        ? toolMatch[1].split('\n').filter(l => l.startsWith('- ')).map(l => l.replace(/^- \*\*|\*\*/g, '').trim())
        : [];

    // Extract key patterns
    const patternsMatch = content.match(/## Key Patterns\n([\s\S]*?)(?=\n## |\n#+ |$)/);
    const keyPatterns = patternsMatch
        ? patternsMatch[1].split('\n').filter(l => l.startsWith('- ')).map(l => l.replace(/^- \*\*|\*\*/g, '').trim())
        : [];

    // Extract examples
    const examplesMatch = content.match(/## Examples\n([\s\S]*?)(?=\n## Boundaries|\n#+ |$)/);
    const examples = examplesMatch ? [examplesMatch[1].trim()] : [];

    // Extract boundaries
    const boundariesMatch = content.match(/## Boundaries\n([\s\S]*?)$/);
    const boundaries = { will: [] as string[], willNot: [] as string[] };
    if (boundariesMatch) {
        const willMatch = boundariesMatch[1].match(/\*\*Will:\*\*\n([\s\S]*?)(?=\*\*Will Not:|\n#+ |$)/);
        const willNotMatch = boundariesMatch[1].match(/\*\*Will Not:\*\*\n([\s\S]*?)$/);
        if (willMatch) {
            boundaries.will = willMatch[1].split('\n').filter(l => l.startsWith('- ')).map(l => l.replace(/^- /, '').trim());
        }
        if (willNotMatch) {
            boundaries.willNot = willNotMatch[1].split('\n').filter(l => l.startsWith('- ')).map(l => l.replace(/^- /, '').trim());
        }
    }

    return {
        name,
        description,
        triggers,
        behavioralFlow,
        mcpIntegration,
        toolCoordination,
        keyPatterns,
        examples,
        boundaries,
        rawContent: content,
    };
}

// ============================================================================
// GENERATORS
// ============================================================================

function generateKeywords(cmd: SuperClaudeCommand): string[] {
    const keywords = new Set<string>();

    // Add command name
    keywords.add(cmd.name);
    keywords.add(cmd.name.replace(/-/g, ' '));

    // Extract keywords from triggers
    cmd.triggers.forEach(trigger => {
        const words = trigger.toLowerCase().match(/\b[a-z]{4,}\b/g) || [];
        words.forEach(w => keywords.add(w));
    });

    // Extract from description
    const descWords = cmd.description.toLowerCase().match(/\b[a-z]{4,}\b/g) || [];
    descWords.forEach(w => {
        if (!['with', 'that', 'this', 'from', 'into', 'across'].includes(w)) {
            keywords.add(w);
        }
    });

    // Extract key action words from behavioral flow
    const actionWords = ['analyze', 'build', 'create', 'design', 'develop', 'fix', 'generate',
                          'implement', 'improve', 'optimize', 'plan', 'refactor', 'test', 'validate'];
    cmd.behavioralFlow.forEach(step => {
        actionWords.forEach(word => {
            if (step.toLowerCase().includes(word)) keywords.add(word);
        });
    });

    return Array.from(keywords).slice(0, 20);
}

function generateIntentPatterns(cmd: SuperClaudeCommand): string[] {
    const patterns: string[] = [];

    // Action-based patterns
    const actions = '(create|add|build|implement|develop|make|write|generate|design)';
    const targets = cmd.triggers
        .map(t => t.match(/\b(component|API|feature|service|test|documentation|endpoint)\b/i)?.[1])
        .filter(Boolean)
        .map(t => t?.toLowerCase());

    if (targets.length > 0) {
        patterns.push(`${actions}.*?(${[...new Set(targets)].join('|')})`);
    }

    // Command-specific patterns
    switch (cmd.name) {
        case 'implement':
            patterns.push('(implement|build|create).*?(feature|component|API|service)');
            patterns.push('(add|develop).*?(functionality|capability)');
            break;
        case 'analyze':
            patterns.push('(analyze|review|assess|audit).*?(code|quality|security|performance)');
            patterns.push('(check|scan).*?(vulnerabilities|issues)');
            break;
        case 'design':
            patterns.push('(design|architect|plan).*?(system|architecture|API|component)');
            break;
        case 'test':
            patterns.push('(test|write tests|add tests).*');
            patterns.push('(unit|integration|e2e).*?test');
            break;
        case 'troubleshoot':
            patterns.push('(fix|debug|troubleshoot|resolve).*?(error|bug|issue|problem)');
            patterns.push('(why|what).*?(failing|broken|not working)');
            break;
        case 'build':
            patterns.push('(build|compile|bundle|package).*?(project|app|application)');
            break;
        case 'cleanup':
            patterns.push('(clean|cleanup|remove|delete).*?(dead code|unused|obsolete)');
            break;
        case 'document':
            patterns.push('(document|write docs|add documentation).*');
            break;
        case 'explain':
            patterns.push('(explain|describe|what does).*?(code|function|component)');
            patterns.push('how does.*?work');
            break;
        case 'improve':
            patterns.push('(improve|enhance|optimize).*?(code|performance|quality)');
            break;
        case 'research':
            patterns.push('(research|investigate|explore|find out).*');
            break;
        case 'estimate':
            patterns.push('(estimate|how long|time).*?(take|implement|build)');
            break;
    }

    return patterns.slice(0, 5);
}

function generateSkillContent(cmd: SuperClaudeCommand): string {
    const lines: string[] = [];

    // YAML frontmatter
    lines.push('---');
    lines.push(`name: sc-${cmd.name}`);
    lines.push(`description: ${cmd.description}`);
    lines.push('---');
    lines.push('');

    // Title
    lines.push(`# SuperClaude: ${cmd.name.charAt(0).toUpperCase() + cmd.name.slice(1)}`);
    lines.push('');
    lines.push('> Converted from SuperClaude Framework for DIET103 auto-activation');
    lines.push('');

    // Purpose
    lines.push('## Purpose');
    lines.push('');
    lines.push(cmd.description);
    lines.push('');

    // When to Use
    lines.push('## When to Use This Skill');
    lines.push('');
    cmd.triggers.forEach(trigger => {
        lines.push(`- ${trigger}`);
    });
    lines.push('');

    // Behavioral Flow
    if (cmd.behavioralFlow.length > 0) {
        lines.push('## Workflow');
        lines.push('');
        cmd.behavioralFlow.forEach((step, i) => {
            lines.push(`${i + 1}. ${step}`);
        });
        lines.push('');
    }

    // Tool & MCP Integration
    if (cmd.mcpIntegration.length > 0 || cmd.toolCoordination.length > 0) {
        lines.push('## Tools & Integration');
        lines.push('');
        if (cmd.mcpIntegration.length > 0) {
            lines.push('### MCP Servers');
            cmd.mcpIntegration.forEach(mcp => {
                lines.push(`- ${mcp}`);
            });
            lines.push('');
        }
        if (cmd.toolCoordination.length > 0) {
            lines.push('### Claude Code Tools');
            cmd.toolCoordination.forEach(tool => {
                lines.push(`- ${tool}`);
            });
            lines.push('');
        }
    }

    // Key Patterns
    if (cmd.keyPatterns.length > 0) {
        lines.push('## Key Patterns');
        lines.push('');
        cmd.keyPatterns.forEach(pattern => {
            lines.push(`- ${pattern}`);
        });
        lines.push('');
    }

    // Boundaries
    if (cmd.boundaries.will.length > 0 || cmd.boundaries.willNot.length > 0) {
        lines.push('## Boundaries');
        lines.push('');
        if (cmd.boundaries.will.length > 0) {
            lines.push('**Will:**');
            cmd.boundaries.will.forEach(b => lines.push(`- ${b}`));
            lines.push('');
        }
        if (cmd.boundaries.willNot.length > 0) {
            lines.push('**Will Not:**');
            cmd.boundaries.willNot.forEach(b => lines.push(`- ${b}`));
            lines.push('');
        }
    }

    // Manual Command Reference
    lines.push('---');
    lines.push('');
    lines.push(`> Manual activation: \`/sc:${cmd.name}\``);
    lines.push('');

    return lines.join('\n');
}

function generateSkillRule(cmd: SuperClaudeCommand): SkillRule {
    const priority = PRIORITY_MAP[cmd.name] || 'medium';

    // Determine type
    let type: 'domain' | 'guardrail' | 'workflow' = 'domain';
    if (['analyze', 'test', 'troubleshoot'].includes(cmd.name)) {
        type = 'guardrail';
    } else if (['workflow', 'spawn', 'task', 'pm'].includes(cmd.name)) {
        type = 'workflow';
    }

    return {
        type,
        enforcement: 'suggest',
        priority,
        description: cmd.description,
        promptTriggers: {
            keywords: generateKeywords(cmd),
            intentPatterns: generateIntentPatterns(cmd),
        },
    };
}

// ============================================================================
// MAIN
// ============================================================================

async function main() {
    const args = process.argv.slice(2);
    const dryRun = args.includes('--dry-run');

    // Parse --command argument
    let singleCommand: string | undefined;
    const commandArgIndex = args.indexOf('--command');
    const commandArgWithEquals = args.find(a => a.startsWith('--command='));
    if (commandArgWithEquals) {
        singleCommand = commandArgWithEquals.split('=')[1];
    } else if (commandArgIndex !== -1 && args[commandArgIndex + 1] && !args[commandArgIndex + 1].startsWith('--')) {
        singleCommand = args[commandArgIndex + 1];
    }

    console.log('🔄 SuperClaude → DIET103 Converter\n');
    console.log(`Mode: ${dryRun ? 'DRY RUN' : 'LIVE'}`);
    console.log(`Source: ${SUPERCLAUDE_DIR}`);
    console.log(`Target: ${SKILLS_DIR}`);
    console.log('');

    // Check source directory
    if (!existsSync(SUPERCLAUDE_DIR)) {
        console.error(`❌ Source directory not found: ${SUPERCLAUDE_DIR}`);
        process.exit(1);
    }

    // Get command files
    let files = readdirSync(SUPERCLAUDE_DIR).filter(f => f.endsWith('.md'));

    // Filter to single command if specified
    if (singleCommand) {
        files = files.filter(f => f === `${singleCommand}.md`);
        if (files.length === 0) {
            console.error(`❌ Command not found: ${singleCommand}`);
            process.exit(1);
        }
    }

    // Filter out skip list
    files = files.filter(f => !SKIP_COMMANDS.includes(f));

    console.log(`📂 Found ${files.length} commands to convert\n`);

    // Load existing skill rules
    let skillRules: SkillRulesFile;
    if (existsSync(SKILL_RULES_PATH)) {
        skillRules = JSON.parse(readFileSync(SKILL_RULES_PATH, 'utf-8'));
    } else {
        skillRules = {
            version: '1.0',
            description: 'Skill activation triggers for Claude Code',
            skills: {},
            notes: {},
        };
    }

    const converted: string[] = [];
    const newRules: Record<string, SkillRule> = {};

    for (const file of files) {
        const content = readFileSync(join(SUPERCLAUDE_DIR, file), 'utf-8');
        const cmd = parseSuperclaude(content, file);

        console.log(`📝 ${cmd.name}`);
        console.log(`   Description: ${cmd.description.slice(0, 60)}...`);
        console.log(`   Triggers: ${cmd.triggers.length}`);
        console.log(`   Priority: ${PRIORITY_MAP[cmd.name] || 'medium'}`);

        // Generate skill content
        const skillContent = generateSkillContent(cmd);
        const skillDir = join(SKILLS_DIR, `sc-${cmd.name}`);
        const skillPath = join(skillDir, 'SKILL.md');

        // Generate skill rule
        const rule = generateSkillRule(cmd);
        newRules[`sc-${cmd.name}`] = rule;

        if (dryRun) {
            console.log(`   Would create: ${skillPath}`);
            console.log(`   Keywords: ${rule.promptTriggers.keywords.slice(0, 5).join(', ')}...`);
        } else {
            mkdirSync(skillDir, { recursive: true });
            writeFileSync(skillPath, skillContent);
            console.log(`   ✅ Created: ${skillPath}`);
        }

        converted.push(cmd.name);
        console.log('');
    }

    // Merge new rules into existing
    const mergedRules = { ...skillRules.skills, ...newRules };
    skillRules.skills = mergedRules;

    if (dryRun) {
        console.log('📋 Would add these skill rules:');
        Object.keys(newRules).forEach(name => {
            console.log(`   - ${name}`);
        });
    } else {
        writeFileSync(SKILL_RULES_PATH, JSON.stringify(skillRules, null, 2) + '\n');
        console.log(`✅ Updated skill-rules.json with ${Object.keys(newRules).length} new rules`);
    }

    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`✨ Converted ${converted.length} commands`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (dryRun) {
        console.log('\nRun without --dry-run to apply changes.');
    } else {
        console.log('\nDone! Skills are now auto-activated via DIET103 hooks.');
        console.log('Manual commands still work: /sc:implement, /sc:analyze, etc.');
    }
}

main().catch(err => {
    console.error('Error:', err);
    process.exit(1);
});
