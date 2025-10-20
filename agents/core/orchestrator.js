#!/usr/bin/env node
/* Minimal orchestrator (JS) – scaffolding for TS version
   - Loads agent manifests and KB
   - Resolves simple intents
   - Prints plan or delegates (future)
   - [2025-10-20] Esteso: legge priority.json per ogni agente e aggrega checklist advisory/mandatory nel plan
   - [2025-10-20] Esteso: evaluation delle condizioni "when" (intentContains, columnsContain, branch, changedPaths, tags, recipeMetadata)
*/

const fs = require('fs');
const path = require('path');

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

function readJsonSafe(p) { try { return JSON.parse(fs.readFileSync(p, 'utf-8')); } catch { return null; } }

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
  const lines = fs.readFileSync(kbPath, 'utf-8').split(/\r?\n/).filter(Boolean);
  return lines.map(l => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
}

function loadGoals() {
  const goalsPath = path.resolve(process.cwd(), 'agents/goals.json');
  if (!fs.existsSync(goalsPath)) return null;
  try { return JSON.parse(fs.readFileSync(goalsPath, 'utf-8')); } catch { return null; }
}

// Utility: convert wildcard pattern (simple * and **) to RegExp
function wildcardToRegExp(pattern) {
  // escape regex special chars, then replace \*\* and \* accordingly
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

function arrayContainsAny(haystack, needles) {
  if (!Array.isArray(haystack) || !needles || needles.length === 0) return false;
  const lowerHay = haystack.map(x => String(x).toLowerCase());
  return needles.some(n => lowerHay.includes(String(n).toLowerCase()));
}

function intersectArrays(a, b) {
  if (!Array.isArray(a) || !Array.isArray(b)) return [];
  const setB = new Set(b.map(x => String(x).toLowerCase()));
  return a.filter(x => setB.has(String(x).toLowerCase()));
}

// match recipeMetadata rules: whenObj.recipeMetadata can be { key: valueOrArray }
function matchesRecipeMetadata(whenMeta, ctxMeta) {
  if (!whenMeta || Object.keys(whenMeta).length === 0) return true;
  if (!ctxMeta) return false;
  for (const key of Object.keys(whenMeta)) {
    const expected = whenMeta[key];
    const actual = ctxMeta[key];
    if (actual === undefined) return false;
    if (Array.isArray(expected)) {
      // any match
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

// Evaluate the "when" object against a provided context
function evaluateWhen(whenObj, context) {
  if (!whenObj || Object.keys(whenObj).length === 0) {
    // No conditions -> match by default
    return true;
  }
  // intentContains: array of substrings to search in intent
  if (whenObj.intentContains) {
    if (!context.intent) return false;
    if (!containsAnyToken(context.intent, whenObj.intentContains)) return false;
  }
  // branch: array of branch names or globs
  if (whenObj.branch) {
    if (!context.branch) return false;
    // support patterns: e.g. "main", "release/*"
    const patterns = whenObj.branch;
    const match = patterns.some(pat => wildcardToRegExp(pat).test(context.branch));
    if (!match) return false;
  }
  // changedPaths: array of path patterns; match if any changedPath matches any pattern
  if (whenObj.changedPaths) {
    if (!context.changedPaths || context.changedPaths.length === 0) return false;
    if (!anyPatternMatches(whenObj.changedPaths, context.changedPaths)) return false;
  }
  // columnsContain: array of column names or tokens present in context.columns
  if (whenObj.columnsContain) {
    if (!context.columns || context.columns.length === 0) return false;
    // match if any of the tokens is included in any column name
    const tokens = whenObj.columnsContain.map(t => String(t).toLowerCase());
    const found = context.columns.some(col => {
      const c = String(col).toLowerCase();
      return tokens.some(tok => c.includes(tok));
    });
    if (!found) return false;
  }
  // tags: array of tags expected in context.tags (any match)
  if (whenObj.tags) {
    if (!context.tags || context.tags.length === 0) return false;
    const inter = intersectArrays(context.tags, whenObj.tags);
    if (!inter || inter.length === 0) return false;
  }
  // recipeMetadata: object with key->value(s) constraints
  if (whenObj.recipeMetadata) {
    if (!matchesRecipeMetadata(whenObj.recipeMetadata, context.recipeMetadata)) return false;
  }
  // If all specified checks passed, return true
  return true;
}

// Build a lightweight context object from flags and recipe/payload
function buildContextFromFlags(flags, recipe) {
  const ctx = {
    intent: flags.intent || null,
    branch: flags.branch || flags.gitBranch || flags['git-branch'] || null,
    changedPaths: [],
    columns: [],
    tags: [],
    recipeMetadata: {}
  };

  // support flags.changedPaths as comma-separated
  if (flags.changedPaths) {
    ctx.changedPaths = String(flags.changedPaths).split(',').map(s => s.trim()).filter(Boolean);
  } else if (flags.changedPathsFile) {
    // optional: load a file with changed paths (one per line)
    try {
      const p = path.resolve(process.cwd(), flags.changedPathsFile);
      if (fs.existsSync(p)) {
        ctx.changedPaths = fs.readFileSync(p, 'utf-8').split(/\r?\n/).map(s => s.trim()).filter(Boolean);
      }
    } catch {}
  }

  // columns: try flags.columns (comma-separated) or payload in flags.payload (JSON string) or recipe payload
  if (flags.columns) {
    ctx.columns = String(flags.columns).split(',').map(s => s.trim()).filter(Boolean);
  } else if (flags.payload) {
    try {
      const pl = JSON.parse(flags.payload);
      if (pl && Array.isArray(pl.columns)) ctx.columns = pl.columns.map(c => c.name || c);
    } catch {}
  } else if (recipe && recipe.payload && Array.isArray(recipe.payload.columns)) {
    ctx.columns = recipe.payload.columns.map(c => c.name || c);
  }

  // tags: flags.tags comma-separated or recipe.tags array
  if (flags.tags) {
    ctx.tags = String(flags.tags).split(',').map(s => s.trim()).filter(Boolean);
  } else if (recipe && Array.isArray(recipe.tags)) {
    ctx.tags = recipe.tags.map(t => String(t));
  } else if (recipe && recipe.tags && typeof recipe.tags === 'string') {
    ctx.tags = String(recipe.tags).split(',').map(s => s.trim()).filter(Boolean);
  }

  // recipeMetadata: try recipe.metadata or recipe.meta or flags.recipeMetadata (JSON string)
  if (flags.recipeMetadata) {
    try {
      const rm = JSON.parse(flags.recipeMetadata);
      if (rm && typeof rm === 'object') ctx.recipeMetadata = rm;
    } catch {}
  } else if (recipe && recipe.metadata && typeof recipe.metadata === 'object') {
    ctx.recipeMetadata = recipe.metadata;
  } else if (recipe && recipe.meta && typeof recipe.meta === 'object') {
    ctx.recipeMetadata = recipe.meta;
  }

  // allow flags.payloadPath pointing to a JSON file for columns or metadata
  if ((!ctx.columns || ctx.columns.length === 0) && flags.payloadPath) {
    try {
      const p = path.resolve(process.cwd(), flags.payloadPath);
      if (fs.existsSync(p)) {
        const pl = JSON.parse(fs.readFileSync(p, 'utf-8'));
        if (pl && Array.isArray(pl.columns)) ctx.columns = pl.columns.map(c => c.name || c);
        if (pl && pl.metadata && typeof pl.metadata === 'object') ctx.recipeMetadata = pl.metadata;
      }
    } catch {}
  }

  return ctx;
}

// Restituisce: { <agent>: { mandatory: [...], advisory: [...] } }
function loadPriorityChecklists(agentDirs, context) {
  const out = {};
  for (const agent of agentDirs) {
    const priorityPath = path.join(agent.path, 'priority.json');
    if (!fs.existsSync(priorityPath)) continue;
    const priority = readJsonSafe(priorityPath);
    if (!priority || !Array.isArray(priority.rules)) continue;
    for (const rule of priority.rules) {
      const whenObj = rule.when || {};
      const applies = evaluateWhen(whenObj, context);
      if (!applies) continue;
      const sev = rule.severity === 'mandatory' ? 'mandatory' : 'advisory';
      if (!out[agent.name]) out[agent.name] = { mandatory: [], advisory: [] };
      if (Array.isArray(rule.checklist)) {
        out[agent.name][sev].push(...rule.checklist.map(item =>
          `[${rule.id}] ${item}`));
      }
    }
  }
  return out;
}

function suggestFromIntent(intent) {
  if (!intent) return null;
  const i = intent.toLowerCase();
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

function main() {
  const { flags } = parseArgs(process.argv);
  const manifests = loadManifests();
  const kb = loadKb();
  const goals = loadGoals();

  const intent = flags.intent || null;
  const recipe = kb.find(r => r.id === intent || r.intent === intent) || null;
  const suggestion = suggestFromIntent(intent) || null;

  const context = buildContextFromFlags(flags, recipe);

  // Nuova logica: aggrega checklist advisory/mandatory per agente usando evaluation delle condizioni "when"
  const checklistSuggestions = loadPriorityChecklists(manifests, context);

  const plan = {
    intent,
    recipeId: recipe?.id || null,
    suggestion,
    manifests: manifests.map(m => ({ name: m.name, role: m.manifest.role })),
    goals,
    checklistSuggestions,
    context
  };

  // For now, just print the plan (the PS wrapper actually executes)
  console.log(JSON.stringify({ plan }, null, 2));
}

main();
