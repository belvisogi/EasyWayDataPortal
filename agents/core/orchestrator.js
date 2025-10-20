#!/usr/bin/env node
/* Minimal orchestrator (JS) – scaffolding for TS version
   - Loads agent manifests and KB
   - Resolves simple intents
   - Prints plan or delegates (future)
   - [2025-10-20] Esteso: legge priority.json per ogni agente e aggrega checklist advisory/mandatory nel plan
*/

const fs = require('fs');
const path = require('path');
const cp = require('child_process');

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

function detectBranch() {
  try {
    const out = cp.execSync('git rev-parse --abbrev-ref HEAD', { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim();
    return out || null;
  } catch { return null; }
}

function gitChangedPaths() {
  try { cp.execSync('git rev-parse --is-inside-work-tree', { stdio: 'ignore' }); } catch { return []; }
  try {
    const base = cp.execSync('git rev-parse HEAD~1', { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim();
    if (!base) throw new Error('no base');
    const diff = cp.execSync(`git diff --name-only ${base} HEAD`, { stdio: ['ignore', 'pipe', 'ignore'] }).toString();
    return diff.split(/\r?\n/).filter(Boolean);
  } catch {
    try {
      const ls = cp.execSync('git ls-files -m -o --exclude-standard', { stdio: ['ignore', 'pipe', 'ignore'] }).toString();
      return ls.split(/\r?\n/).filter(Boolean);
    } catch { return []; }
  }
}

function globToRegex(pattern) {
  let p = String(pattern).replace(/\\/g, '/');
  p = p.replace(/[.+^${}()|[\]\\]/g, '\\$&');
  p = p.replace(/\*\*/g, '.*');
  p = p.replace(/\*/g, '[^/]*');
  return new RegExp('^' + p + '$');
}

function ruleMatches(rule, ctx) {
  const w = rule.when || null;
  if (!w) return true;
  if (Array.isArray(w.intents) && ctx.intent) {
    let ok = false;
    for (const re of w.intents) {
      try { if (new RegExp(re).test(ctx.intent)) { ok = true; break; } }
      catch { if (String(ctx.intent).includes(String(re))) { ok = true; break; } }
    }
    if (!ok) return false;
  }
  if (Array.isArray(w.branch) && ctx.branch) {
    if (!w.branch.includes(ctx.branch)) return false;
  }
  if (Array.isArray(w.env) && ctx.env) {
    if (!w.env.includes(ctx.env)) return false;
  }
  if (Array.isArray(w.changedPaths) && Array.isArray(ctx.changedPaths)) {
    let hit = false;
    for (const pat of w.changedPaths) {
      const rx = globToRegex(pat);
      if (ctx.changedPaths.some(fp => rx.test(fp.replace(/\\/g, '/')))) { hit = true; break; }
    }
    if (!hit) return false;
  }
  if (w.varEquals && typeof w.varEquals === 'object') {
    for (const [k, expected] of Object.entries(w.varEquals)) {
      const actual = process.env[k] || '';
      if (String(actual) !== String(expected)) return false;
    }
  }
  return true;
}

function loadPriorityChecklists(agentDirs, ctx) {
  // Restituisce: [{ agent, severity, items, matchedRules }]
  const suggestions = [];
  for (const agent of agentDirs) {
    const priorityPath = path.join(agent.path, 'priority.json');
    if (!fs.existsSync(priorityPath)) continue;
    const priority = readJsonSafe(priorityPath);
    if (!priority || !Array.isArray(priority.rules)) continue;
    const matched = priority.rules.filter(r => ruleMatches(r, ctx));
    if (matched.length === 0) continue;
    const sevOrder = { mandatory: 2, advisory: 1 };
    let top = 'advisory';
    for (const r of matched) {
      const s = (r.severity === 'mandatory') ? 'mandatory' : 'advisory';
      if (sevOrder[s] > sevOrder[top]) top = s;
    }
    const items = Array.from(new Set(matched.flatMap(r => Array.isArray(r.checklist) ? r.checklist : [])));
    const ids = matched.map(r => r.id).filter(Boolean);
    if (items.length > 0) suggestions.push({ agent: agent.name, severity: top, items, matchedRules: ids });
  }
  return suggestions;
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

  // Nuova logica: aggrega checklist advisory/mandatory per agente con valutazione delle regole
  const ctx = {
    intent,
    branch: detectBranch(),
    env: process.env.ENVIRONMENT || 'local',
    changedPaths: gitChangedPaths()
  };
  const checklistSuggestions = loadPriorityChecklists(manifests, ctx);

  const plan = {
    intent,
    recipeId: recipe?.id || null,
    suggestion,
    manifests: manifests.map(m => ({ name: m.name, role: m.manifest.role })),
    goals,
    context: { branch: ctx.branch, env: ctx.env, changedPathsCount: ctx.changedPaths.length },
    checklistSuggestions
  };

  // For now, just print the plan (the PS wrapper actually executes)
  console.log(JSON.stringify({ plan }, null, 2));
}

main();
