#!/usr/bin/env node
/* 
   CORE ORCHESTRATOR (JS) - PRODUCTION READY
   =========================================
   - Loads agent manifests and Knowledge Base (KB)
   - Resolves intents to specific agents and actions
   - Validates input for security and schema compliance
   - Aggregates advisory/mandatory checklists based on priority rules
   - Evaluates "when" conditions for context-aware rules
   - Structured logging (JSON) for observability
*/

const fs = require('fs');
const path = require('path');

// --- Logger ---
const logger = {
  info: (msg, meta) => console.log(JSON.stringify({ level: 'INFO', timestamp: new Date(), msg, ...meta })),
  error: (msg, meta) => console.error(JSON.stringify({ level: 'ERROR', timestamp: new Date(), msg, ...meta })),
  warn: (msg, meta) => console.warn(JSON.stringify({ level: 'WARN', timestamp: new Date(), msg, ...meta }))
};

// --- Utils ---

function parseArgs(argv) {
  const out = { flags: {} };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const key = a.replace(/^--/, '');
      const next = argv[i + 1];
      if (!next || next.startsWith('--')) { out.flags[key] = true; } else { out.flags[key] = next; i++; }
    }
  }
  return out;
}

function readJsonSafe(p) {
  try {
    return JSON.parse(fs.readFileSync(p, 'utf-8'));
  } catch (e) {
    // Only log if file exists but is invalid, silent if missing (optional)
    if (fs.existsSync(p)) logger.warn(`Failed to parse JSON file: ${p}`, { error: e.message });
    return null;
  }
}

function loadManifests() {
  const base = path.resolve(process.cwd(), 'agents');
  const manifests = [];
  if (!fs.existsSync(base)) return manifests;
  for (const entry of fs.readdirSync(base)) {
    const dir = path.join(base, entry);
    if (!fs.statSync(dir).isDirectory()) continue;
    const man = path.join(dir, 'manifest.json');
    if (fs.existsSync(man)) {
      const obj = readJsonSafe(man);
      if (obj) manifests.push({ name: entry, manifest: obj, path: dir });
    }
  }
  return manifests;
}

function loadKb() {
  const kbPath = path.resolve(process.cwd(), 'agents/kb/recipes.jsonl');
  if (!fs.existsSync(kbPath)) return [];
  try {
    const lines = fs.readFileSync(kbPath, 'utf-8').split(/\r?\n/).filter(Boolean);
    return lines.map(l => {
      try { return JSON.parse(l); } catch { return null; }
    }).filter(Boolean);
  } catch (e) {
    logger.error("Failed to load KB", { error: e.message });
    return [];
  }
}

function loadGoals() {
  const goalsPath = path.resolve(process.cwd(), 'agents/goals.json');
  if (!fs.existsSync(goalsPath)) return null;
  return readJsonSafe(goalsPath);
}

// Utility: convert wildcard pattern (simple * and **) to RegExp
function wildcardToRegExp(pattern) {
  let p = pattern.replace(/[-/\\^$+?.()|[\]{}]/g, '\\$&');
  p = p.replace(/\\\*\\\*/g, '.*'); // ** -> .*
  p = p.replace(/\\\*/g, '[^/]*');   // * -> no slash
  return new RegExp('^' + p + '$');
}

function anyPatternMatches(patterns, items) {
  if (!patterns || !items || items.length === 0) return false;
  for (const pat of patterns) {
    const re = wildcardToRegExp(pat);
    for (const it of items) {
      if (re.test(it)) return true;
    }
  }
  return false;
}

function containsAnyToken(text, tokens) {
  if (!text || !tokens || tokens.length === 0) return false;
  const lower = String(text).toLowerCase();
  return tokens.some(t => lower.includes(String(t).toLowerCase()));
}

function intersectArrays(a, b) {
  if (!Array.isArray(a) || !Array.isArray(b)) return [];
  const setB = new Set(b.map(x => String(x).toLowerCase()));
  return a.filter(x => setB.has(String(x).toLowerCase()));
}

// match recipeMetadata rules
function matchesRecipeMetadata(whenMeta, ctxMeta) {
  if (!whenMeta || Object.keys(whenMeta).length === 0) return true;
  if (!ctxMeta) return false;
  for (const key of Object.keys(whenMeta)) {
    const expected = whenMeta[key];
    const actual = ctxMeta[key];
    if (actual === undefined) return false;
    if (Array.isArray(expected)) {
      const lowerExpected = expected.map(e => String(e).toLowerCase());
      const act = Array.isArray(actual) ? actual.map(a => String(a).toLowerCase()) : [String(actual).toLowerCase()];
      const has = act.some(a => lowerExpected.includes(a));
      if (!has) return false;
    } else {
      if (String(actual).toLowerCase() !== String(expected).toLowerCase()) return false;
    }
  }
  return true;
}

// Evaluate "when" condition
function evaluateWhen(whenObj, context) {
  if (!whenObj || Object.keys(whenObj).length === 0) return true;

  if (whenObj.intentContains) {
    if (!context.intent) return false;
    if (!containsAnyToken(context.intent, whenObj.intentContains)) return false;
  }
  if (whenObj.branch) {
    if (!context.branch) return false;
    const patterns = whenObj.branch;
    const match = patterns.some(pat => wildcardToRegExp(pat).test(context.branch));
    if (!match) return false;
  }
  if (whenObj.changedPaths) {
    if (!context.changedPaths || context.changedPaths.length === 0) return false;
    if (!anyPatternMatches(whenObj.changedPaths, context.changedPaths)) return false;
  }
  if (whenObj.columnsContain) {
    if (!context.columns || context.columns.length === 0) return false;
    const tokens = whenObj.columnsContain.map(t => String(t).toLowerCase());
    const found = context.columns.some(col => {
      const c = String(col).toLowerCase();
      return tokens.some(tok => c.includes(tok));
    });
    if (!found) return false;
  }
  if (whenObj.tags) {
    if (!context.tags || context.tags.length === 0) return false;
    const inter = intersectArrays(context.tags, whenObj.tags);
    if (!inter || inter.length === 0) return false;
  }
  if (whenObj.recipeMetadata) {
    if (!matchesRecipeMetadata(whenObj.recipeMetadata, context.recipeMetadata)) return false;
  }
  return true;
}

function buildContextFromFlags(flags, recipe) {
  const ctx = {
    intent: flags.intent || null,
    branch: flags.branch || flags.gitBranch || flags['git-branch'] || null,
    changedPaths: [],
    columns: [],
    tags: [],
    recipeMetadata: {}
  };

  if (flags.changedPaths) {
    ctx.changedPaths = String(flags.changedPaths).split(',').map(s => s.trim()).filter(Boolean);
  } else if (flags.changedPathsFile) {
    try {
      const p = path.resolve(process.cwd(), flags.changedPathsFile);
      if (fs.existsSync(p)) {
        ctx.changedPaths = fs.readFileSync(p, 'utf-8').split(/\r?\n/).map(s => s.trim()).filter(Boolean);
      }
    } catch (e) { logger.warn("Failed to read changedPathsFile", { error: e.message }); }
  }

  // Helper to parse columns and metadata
  const extractFromObject = (obj) => {
    if (obj && Array.isArray(obj.columns)) ctx.columns = obj.columns.map(c => c.name || c);
    if (obj && obj.metadata && typeof obj.metadata === 'object') ctx.recipeMetadata = obj.metadata;
    if (obj && obj.meta && typeof obj.meta === 'object') ctx.recipeMetadata = obj.meta;
    if (obj && Array.isArray(obj.tags)) ctx.tags = obj.tags.map(t => String(t));
    if (obj && typeof obj.tags === 'string') ctx.tags = String(obj.tags).split(',').map(s => s.trim()).filter(Boolean);
  };

  if (flags.columns) ctx.columns = String(flags.columns).split(',').map(s => s.trim()).filter(Boolean);
  if (flags.tags) ctx.tags = String(flags.tags).split(',').map(s => s.trim()).filter(Boolean);
  if (flags.recipeMetadata) {
    try { ctx.recipeMetadata = JSON.parse(flags.recipeMetadata); } catch { }
  }

  // Load from payload flag or file
  if (flags.payload) {
    try { extractFromObject(JSON.parse(flags.payload)); } catch { }
  }
  if (recipe && recipe.payload) extractFromObject(recipe.payload);
  if (recipe) extractFromObject(recipe); // Allow top-level tags/metadata in recipe

  if ((!ctx.columns || ctx.columns.length === 0) && flags.payloadPath) {
    try {
      const p = path.resolve(process.cwd(), flags.payloadPath);
      if (fs.existsSync(p)) extractFromObject(JSON.parse(fs.readFileSync(p, 'utf-8')));
    } catch (e) { logger.warn("Failed to read payloadPath", { error: e.message }); }
  }

  return ctx;
}

function loadPriorityChecklists(agentDirs, context) {
  const out = {};
  for (const agent of agentDirs) {
    const priorityPath = path.join(agent.path, 'priority.json');
    if (!fs.existsSync(priorityPath)) continue;
    const priority = readJsonSafe(priorityPath);
    if (!priority || !Array.isArray(priority.rules)) continue;

    for (const rule of priority.rules) {
      if (!rule.checklist || rule.checklist.length === 0) continue;

      const whenObj = rule.when || {};
      if (evaluateWhen(whenObj, context)) {
        const sev = rule.severity === 'mandatory' ? 'mandatory' : 'advisory';
        if (!out[agent.name]) out[agent.name] = { mandatory: [], advisory: [] };

        out[agent.name][sev].push(...rule.checklist.map(item => `[${rule.id}] ${item}`));
      }
    }
  }
  return out;
}

function suggestFromIntent(intent) {
  if (!intent) return null;
  const i = intent.toLowerCase();

  // Extendable Routing Table
  // TODO: Load this from a routing config or manifest triggers
  if (i.includes('wiki') || i.includes('docs')) {
    return { agent: 'agent_docs_review', action: 'ps', args: ['scripts/agent-docs-review.ps1', '-Wiki', '-Interactive:$false'] };
  }
  if (i.includes('gov') || i.includes('gate') || i.includes('predeploy')) {
    return { agent: 'agent_governance', action: 'ps', args: ['scripts/agent-governance.ps1', '-Checklist', '-DbDrift', '-KbConsistency', '-Interactive:$false'] };
  }
  if (i.includes('infra') || i.includes('terraform')) {
    return { agent: 'agent_governance', action: 'ps', args: ['scripts/agent-governance.ps1', '-TerraformPlan', '-Interactive:$false'] };
  }
  return null;
}

function validateIntent(intent) {
  if (!intent) return { valid: true };

  const dangerousPatterns = [
    /ignora\s+(tutte?\s+le\s+)?istruzioni/i,
    /ignore\s+(all\s+)?instructions/i,
    /override\s+(all\s+)?rules/i,
    /disregard\s+previous/i,
    /;\s*exec\s*\(/i,
    /\$\([^)]+\)/
  ];

  for (const pattern of dangerousPatterns) {
    if (pattern.test(intent)) {
      return {
        valid: false,
        severity: 'high',
        message: 'Intent contains potentially dangerous pattern'
      };
    }
  }
  return { valid: true };
}

function main() {
  try {
    const { flags } = parseArgs(process.argv);

    // 0. Logging Init
    if (flags.verbose) logger.info("Orchestrator started", { flags });

    // 1. Load Resources
    const manifests = loadManifests();
    const kb = loadKb();
    const goals = loadGoals();

    const intent = flags.intent || null;

    // 2. Security Validation
    const validation = validateIntent(intent);
    if (!validation.valid) {
      const errPayload = {
        error: 'security_validation_failed',
        severity: validation.severity,
        message: validation.message,
        timestamp: new Date().toISOString()
      };
      console.error(JSON.stringify(errPayload, null, 2));
      process.exit(1);
    }

    // 3. Resolve Recipe & Context
    const recipe = kb.find(r => r.id === intent || r.intent === intent) || null;
    const context = buildContextFromFlags(flags, recipe);

    // 4. Suggest Action (Routing)
    const suggestion = suggestFromIntent(intent) || null;

    // 5. Evaluate Priority Rules (Checklists)
    const checklistSuggestions = loadPriorityChecklists(manifests, context);

    // 6. Build Plan
    const plan = {
      timestamp: new Date().toISOString(),
      intent,
      recipeId: recipe?.id || null,
      context,
      suggestion,
      manifests: manifests.map(m => ({
        name: m.name,
        role: m.manifest.role,
        capabilities: m.manifest.capabilities || []
      })),
      goals,
      checklistSuggestions,
      securityValidation: { passed: true }
    };

    // 7. Output Plan (JSON)
    // The calling process (e.g. PowerShell wrapper) consumes this output
    console.log(JSON.stringify({ plan }, null, 2));

  } catch (error) {
    logger.error("Orchestrator failed", { error: error.message, stack: error.stack });
    process.exit(1);
  }
}

main();
