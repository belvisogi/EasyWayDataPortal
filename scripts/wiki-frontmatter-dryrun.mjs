#!/usr/bin/env node
import fs from 'fs';
import path from 'path';

function arg(k, def) {
  const i = process.argv.indexOf(k);
  return i >= 0 ? process.argv[i + 1] : def;
}

const root = arg('--path', 'Wiki/EasyWayData.wiki');
const out = arg('--out', 'wiki-frontmatter-dryrun.json');

function walk(dir, acc = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.isFile() && e.name.toLowerCase().endsWith('.md')) acc.push(p);
  }
  return acc;
}

function parseFrontMatter(text) {
  if (!text.startsWith('---\n') && !text.startsWith('---\r\n')) {
    return { exists: false };
  }
  const idx = text.indexOf('\n---', 4);
  if (idx < 0) return { exists: true, terminated: false };
  const block = text.slice(4, idx);
  return { exists: true, terminated: true, block, endIndex: idx + 4 + 3 };
}

function checkRequired(block) {
  const lines = block.split(/\r?\n/).map(s => s.trim());
  const req = {
    id: false, title: false, summary: false, status: false, owner: false, tags: false, llm_include: false, llm_chunk: false
  };
  let inLLM = false;
  for (const l of lines) {
    if (/^id\s*:\s*.+/i.test(l)) req.id = true;
    else if (/^title\s*:\s*.+/i.test(l)) req.title = true;
    else if (/^summary\s*:\s*.+/i.test(l)) req.summary = true;
    else if (/^status\s*:\s*.+/i.test(l)) req.status = true;
    else if (/^owner\s*:\s*.+/i.test(l)) req.owner = true;
    else if (/^tags\s*:\s*\[/.test(l)) req.tags = true;
    else if (/^llm\s*:\s*$/i.test(l)) inLLM = true;
    else if (inLLM && /^include\s*:\s*(true|false)$/i.test(l)) req.llm_include = true;
    else if (/^chunk_hint\s*:\s*\d+/.test(l)) req.llm_chunk = true;
  }
  const missing = Object.keys(req).filter(k => !req[k]);
  return { ok: missing.length === 0, missing };
}

const files = walk(root);
const results = [];
for (const f of files) {
  const text = fs.readFileSync(f, 'utf8');
  const fm = parseFrontMatter(text);
  if (!fm.exists) results.push({ file: f, ok: false, error: 'missing_yaml_front_matter' });
  else if (!fm.terminated) results.push({ file: f, ok: false, error: 'unterminated_front_matter' });
  else {
    const req = checkRequired(fm.block);
    results.push({ file: f, ok: req.ok, missing: req.missing });
  }
}

const summary = { ok: results.every(r => r.ok), total: results.length, failed: results.filter(r => !r.ok).length, results };
fs.writeFileSync(out, JSON.stringify(summary, null, 2));
console.log(JSON.stringify(summary, null, 2));

