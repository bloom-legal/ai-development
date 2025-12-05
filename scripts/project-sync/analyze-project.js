#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Framework detection patterns for package.json dependencies
const NODE_FRAMEWORKS = {
  'react': 'React',
  'next': 'Next.js',
  'vue': 'Vue',
  'nuxt': 'Nuxt',
  'svelte': 'Svelte',
  '@sveltejs/kit': 'SvelteKit',
  'express': 'Express',
  'fastify': 'Fastify',
  'koa': 'Koa',
  'hono': 'Hono',
  'prisma': 'Prisma',
  'drizzle-orm': 'Drizzle',
  '@tanstack/react-query': 'React Query',
  'tailwindcss': 'Tailwind',
  '@radix-ui': 'Radix UI',
  'shadcn': 'shadcn/ui',
  'socket.io': 'Socket.io',
  'playwright': 'Playwright',
  'vitest': 'Vitest',
  'jest': 'Jest',
  'puppeteer': 'Puppeteer',
  'electron': 'Electron',
  '@tauri-apps': 'Tauri',
  'vite': 'Vite',
  'webpack': 'Webpack',
  'esbuild': 'esbuild',
  'tsx': 'tsx',
  'zod': 'Zod',
  'trpc': 'tRPC',
  'graphql': 'GraphQL',
  'apollo': 'Apollo',
  'mongoose': 'Mongoose',
  'typeorm': 'TypeORM',
  'sequelize': 'Sequelize',
  'bullmq': 'BullMQ',
  'ioredis': 'Redis',
  'pg': 'PostgreSQL',
  'better-sqlite3': 'SQLite',
  'mysql2': 'MySQL',
  'mongodb': 'MongoDB',
  'next-auth': 'NextAuth',
  '@auth': 'Auth.js',
  'passport': 'Passport',
  'stripe': 'Stripe',
  'openai': 'OpenAI',
  '@anthropic-ai': 'Anthropic',
  '@mastra': 'Mastra',
  'langchain': 'LangChain',
  'commander': 'Commander',
  'yargs': 'Yargs',
  'oclif': 'oclif',
  'ink': 'Ink',
  'chalk': 'Chalk',
  'axios': 'Axios',
  'ky': 'Ky',
  'got': 'Got',
  'storybook': 'Storybook',
  'wasp': 'Wasp',
  'astro': 'Astro',
  'remix': 'Remix',
  'gatsby': 'Gatsby',
  '@vercel/ai': 'Vercel AI',
  'framer-motion': 'Framer Motion',
  'react-flow': 'React Flow',
  '@xyflow': 'XYFlow',
  'recharts': 'Recharts',
  'd3': 'D3',
  'three': 'Three.js',
};

// Python framework patterns
const PYTHON_FRAMEWORKS = {
  'fastapi': 'FastAPI',
  'django': 'Django',
  'flask': 'Flask',
  'streamlit': 'Streamlit',
  'sqlalchemy': 'SQLAlchemy',
  'pydantic': 'Pydantic',
  'pytest': 'pytest',
  'playwright': 'Playwright',
  'celery': 'Celery',
  'redis': 'Redis',
  'psycopg': 'PostgreSQL',
  'asyncpg': 'PostgreSQL',
  'pymongo': 'MongoDB',
  'httpx': 'httpx',
  'aiohttp': 'aiohttp',
  'beautifulsoup4': 'BeautifulSoup',
  'scrapy': 'Scrapy',
  'crewai': 'CrewAI',
  'langchain': 'LangChain',
  'openai': 'OpenAI',
  'anthropic': 'Anthropic',
  'typer': 'Typer',
  'click': 'Click',
  'rich': 'Rich',
  'pandas': 'Pandas',
  'numpy': 'NumPy',
  'polars': 'Polars',
  'alembic': 'Alembic',
};

// Config file detection
const CONFIG_DETECTORS = [
  { file: 'Dockerfile', tech: 'Docker' },
  { file: 'docker-compose.yml', tech: 'Docker' },
  { file: 'docker-compose.yaml', tech: 'Docker' },
  { file: 'tailwind.config.js', tech: 'Tailwind' },
  { file: 'tailwind.config.ts', tech: 'Tailwind' },
  { file: 'tsconfig.json', tech: 'TypeScript' },
  { file: 'rust-toolchain.toml', tech: 'Rust' },
  { file: 'Cargo.toml', tech: 'Rust' },
  { file: 'go.mod', tech: 'Go' },
  { file: '.swift-version', tech: 'Swift' },
  { file: 'Package.swift', tech: 'Swift' },
  { file: 'composer.json', tech: 'PHP' },
  { file: 'wp-config.php', tech: 'WordPress' },
  { file: 'mint.json', tech: 'Mintlify' },
];

// Patterns to detect from require/import statements
const REQUIRE_PATTERNS = {
  'axios': 'Axios',
  'express': 'Express',
  'chalk': 'Chalk',
  'commander': 'Commander',
  'inquirer': 'Inquirer',
  'puppeteer': 'Puppeteer',
  'playwright': 'Playwright',
  'cheerio': 'Cheerio',
  'lodash': 'Lodash',
  'moment': 'Moment',
  'dayjs': 'Day.js',
  'uuid': 'UUID',
  'dotenv': 'dotenv',
  'node-fetch': 'node-fetch',
  'got': 'Got',
  'socket.io': 'Socket.io',
  'ws': 'WebSocket',
  'jsonwebtoken': 'JWT',
  'bcrypt': 'bcrypt',
  'crypto': null, // built-in, skip
  'fs': null,
  'path': null,
  'https': null,
  'http': null,
  'child_process': null,
  'os': null,
  'url': null,
  'util': null,
  'stream': null,
  'events': null,
  'buffer': null,
  'querystring': null,
  'net': null,
  'tls': null,
  'dns': null,
  'readline': null,
  'zlib': null,
  'assert': null,
};

function findPackageJsonFiles(dir, depth = 0, maxDepth = 2) {
  const results = [];
  if (depth > maxDepth) return results;

  try {
    const entries = fs.readdirSync(dir, { withFileTypes: true });

    // Check for package.json at this level
    const pkgPath = path.join(dir, 'package.json');
    if (fs.existsSync(pkgPath)) {
      results.push(pkgPath);
    }

    // Check subdirectories (skip node_modules, .git, etc.)
    for (const entry of entries) {
      if (entry.isDirectory() &&
          !['node_modules', '.git', '.next', 'dist', 'build', '__pycache__', '.venv', 'venv'].includes(entry.name) &&
          !entry.name.startsWith('.')) {
        results.push(...findPackageJsonFiles(path.join(dir, entry.name), depth + 1, maxDepth));
      }
    }
  } catch (e) {
    // Ignore permission errors
  }

  return results;
}

function findPythonFiles(dir, depth = 0, maxDepth = 2) {
  const results = [];
  if (depth > maxDepth) return results;

  try {
    const entries = fs.readdirSync(dir, { withFileTypes: true });

    // Check for Python config files at this level
    for (const file of ['pyproject.toml', 'requirements.txt', 'setup.py']) {
      const filePath = path.join(dir, file);
      if (fs.existsSync(filePath)) {
        results.push(filePath);
      }
    }

    // Check subdirectories
    for (const entry of entries) {
      if (entry.isDirectory() &&
          !['node_modules', '.git', '__pycache__', '.venv', 'venv', 'dist', 'build'].includes(entry.name) &&
          !entry.name.startsWith('.')) {
        results.push(...findPythonFiles(path.join(dir, entry.name), depth + 1, maxDepth));
      }
    }
  } catch (e) {
    // Ignore permission errors
  }

  return results;
}

function findConfigFiles(dir, depth = 0, maxDepth = 2) {
  const results = [];
  if (depth > maxDepth) return results;

  try {
    const entries = fs.readdirSync(dir, { withFileTypes: true });

    // Check config files at this level
    for (const { file, tech } of CONFIG_DETECTORS) {
      if (fs.existsSync(path.join(dir, file))) {
        results.push({ file, tech, path: path.join(dir, file) });
      }
    }

    // Check subdirectories
    for (const entry of entries) {
      if (entry.isDirectory() &&
          !['node_modules', '.git', '__pycache__', '.venv', 'venv', 'dist', 'build'].includes(entry.name) &&
          !entry.name.startsWith('.')) {
        results.push(...findConfigFiles(path.join(dir, entry.name), depth + 1, maxDepth));
      }
    }
  } catch (e) {
    // Ignore permission errors
  }

  return results;
}

function findJsFiles(dir, depth = 0, maxDepth = 1) {
  const results = [];
  if (depth > maxDepth) return results;

  try {
    const entries = fs.readdirSync(dir, { withFileTypes: true });

    for (const entry of entries) {
      if (entry.isFile() && (entry.name.endsWith('.js') || entry.name.endsWith('.ts') || entry.name.endsWith('.mjs'))) {
        results.push(path.join(dir, entry.name));
      } else if (entry.isDirectory() &&
          !['node_modules', '.git', 'dist', 'build'].includes(entry.name) &&
          !entry.name.startsWith('.')) {
        results.push(...findJsFiles(path.join(dir, entry.name), depth + 1, maxDepth));
      }
    }
  } catch (e) {
    // Ignore permission errors
  }

  return results;
}

function extractDepsFromJsFile(filePath) {
  const deps = new Set();

  try {
    const content = fs.readFileSync(filePath, 'utf8');

    // Match require('...') and require("...")
    const requireMatches = content.matchAll(/require\s*\(\s*['"]([^'"]+)['"]\s*\)/g);
    for (const match of requireMatches) {
      const mod = match[1].split('/')[0]; // Get base module name
      if (REQUIRE_PATTERNS[mod] !== undefined) {
        if (REQUIRE_PATTERNS[mod] !== null) {
          deps.add(REQUIRE_PATTERNS[mod]);
        }
      } else if (!mod.startsWith('.') && !mod.startsWith('@')) {
        // Unknown third-party module - capitalize first letter
        deps.add(mod.charAt(0).toUpperCase() + mod.slice(1));
      }
    }

    // Match import ... from '...'
    const importMatches = content.matchAll(/import\s+.*?\s+from\s+['"]([^'"]+)['"]/g);
    for (const match of importMatches) {
      const mod = match[1].split('/')[0];
      if (REQUIRE_PATTERNS[mod] !== undefined) {
        if (REQUIRE_PATTERNS[mod] !== null) {
          deps.add(REQUIRE_PATTERNS[mod]);
        }
      } else if (!mod.startsWith('.') && !mod.startsWith('@')) {
        deps.add(mod.charAt(0).toUpperCase() + mod.slice(1));
      }
    }
  } catch (e) {
    // Ignore read errors
  }

  return deps;
}

async function analyzeProject(projectPath) {
  const stack = new Set();
  let foundNodeProject = false;
  let foundPythonProject = false;

  // Find and parse all package.json files (root + subdirs)
  const pkgFiles = findPackageJsonFiles(projectPath);
  for (const pkgPath of pkgFiles) {
    try {
      const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
      const allDeps = {
        ...pkg.dependencies,
        ...pkg.devDependencies,
      };

      for (const dep of Object.keys(allDeps || {})) {
        for (const [pattern, name] of Object.entries(NODE_FRAMEWORKS)) {
          if (dep === pattern || dep.startsWith(pattern + '/') || dep.startsWith('@' + pattern)) {
            stack.add(name);
          }
        }
      }

      foundNodeProject = true;
    } catch (e) {
      // Ignore parse errors
    }
  }

  // Find and parse Python config files (root + subdirs)
  const pythonFiles = findPythonFiles(projectPath);
  for (const pyFile of pythonFiles) {
    try {
      const content = fs.readFileSync(pyFile, 'utf8').toLowerCase();
      for (const [pattern, name] of Object.entries(PYTHON_FRAMEWORKS)) {
        if (content.includes(pattern)) {
          stack.add(name);
        }
      }
      foundPythonProject = true;
    } catch (e) {}
  }

  // Detect from config files (root + subdirs)
  const configFiles = findConfigFiles(projectPath);
  for (const { tech } of configFiles) {
    stack.add(tech);
  }

  // If no package.json found, try to detect from JS files directly
  if (!foundNodeProject) {
    const jsFiles = findJsFiles(projectPath);
    for (const jsFile of jsFiles) {
      const deps = extractDepsFromJsFile(jsFile);
      for (const dep of deps) {
        stack.add(dep);
      }
      if (deps.size > 0) {
        stack.add('Node.js');
      }
    }
  }

  // Add base language if we found projects
  if (foundNodeProject) {
    stack.add('Node.js');
  }
  if (foundPythonProject) {
    stack.add('Python');
  }

  return Array.from(stack).sort();
}

// CLI interface
async function main() {
  const projectPath = process.argv[2];

  if (!projectPath) {
    console.error('Usage: node analyze-project.js <project-path>');
    process.exit(1);
  }

  const stack = await analyzeProject(projectPath);
  console.log(JSON.stringify(stack));
}

main().catch(err => {
  console.error(err.message);
  process.exit(1);
});

module.exports = { analyzeProject };
