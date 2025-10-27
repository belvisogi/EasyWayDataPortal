#!/usr/bin/env node
import fs from 'fs';
import path from 'path';
import { arg, writeJson } from './_util.mjs';

const runId = arg('--run_id');
const mappingJsonPath = arg('--mapping_json');
const saveTemplate = arg('--save_template','false') === 'true';
const templateName = arg('--template_name','');

if (!runId || !mappingJsonPath) {
  console.error('Usage: node scripts/intents/schema.map-apply.mjs --run_id <id> --mapping_json <path> [--save_template true|false] [--template_name <name>]');
  process.exit(1);
}

let mapping = {};
try { mapping = JSON.parse(fs.readFileSync(mappingJsonPath,'utf8')); } catch { mapping = {}; }

let templateId = '';
if (saveTemplate) {
  templateId = `map-${templateName || runId}`;
  const outPath = path.join('out','mapping', `${templateId}.json`);
  writeJson(outPath, mapping);
}

const out = { mapping_template_id: templateId, mapping_applied: true };
writeJson(path.join('out','mapping', `${runId}-apply-result.json`), out);
console.log(JSON.stringify(out, null, 2));

