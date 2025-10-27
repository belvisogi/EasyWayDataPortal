#!/usr/bin/env node
import fs from 'fs';
import path from 'path';
import { arg, splitCsv, writeJson } from './_util.mjs';

const headersStr = arg('--headers','');
const templateRef = arg('--template_ref','docs/agentic/templates/mapping.entrate-uscite.candidates.json');
const headers = splitCsv(headersStr).map(h => h.toLowerCase());

if (headers.length === 0) {
  console.error('Usage: node scripts/intents/schema.map-suggest.mjs --headers <h1,h2,...> [--template_ref <path>]');
  process.exit(1);
}

let candidates = {};
try { candidates = JSON.parse(fs.readFileSync(templateRef,'utf8')); } catch { candidates = {}; }

const mappingPreview = {};
const missing = [];
for (const [target, cands] of Object.entries(candidates)) {
  const found = (cands||[]).find(c => headers.includes(String(c).toLowerCase()));
  if (found) mappingPreview[target] = found;
  else missing.push(target);
}

const out = { mapping_preview: mappingPreview, missing_fields: missing };
writeJson(path.join('out','mapping','suggest-result.json'), out);
console.log(JSON.stringify(out, null, 2));

