#!/usr/bin/env node
/* Minimal orchestrator (JS) – scaffolding for TS version
   - Loads agent manifests and KB
   - Resolves simple intents
   - Prints plan or delegates (future) */

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

  const plan = {
    intent,
    recipeId: recipe?.id || null,
    suggestion,
    manifests: manifests.map(m => ({ name: m.name, role: m.manifest.role })),
    goals
  };

  // For now, just print the plan (the PS wrapper actually executes)
  console.log(JSON.stringify({ plan }, null, 2));
}

main();
