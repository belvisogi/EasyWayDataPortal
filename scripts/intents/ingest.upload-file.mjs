#!/usr/bin/env node
import fs from 'fs';
import path from 'path';
import { arg, writeJson, ensureDir, nowId } from './_util.mjs';

const file = arg('--file');
const user = arg('--user');
const tenant = arg('--tenant');
const domain = arg('--domain');
const flow = arg('--flow');
const instance = arg('--instance');

if (!file || !tenant || !domain || !flow || !instance) {
  console.error('Usage: node scripts/intents/ingest.upload-file.mjs --file <path> --user <id> --tenant <id> --domain <id> --flow <id> --instance <id>');
  process.exit(1);
}

const runId = nowId('run');
const jobId = nowId('job');
const landingPath = path.join('landing', tenant, domain, flow, jobId, path.basename(file));
const samplePath = path.join('out', 'ingest', `${jobId}-sample.txt`);
ensureDir(path.dirname(landingPath));
ensureDir(path.dirname(samplePath));

// Simula: non copiamo file grandi; scriviamo solo una preview minima.
try {
  const content = fs.readFileSync(file, 'utf8');
  const lines = content.split(/\r?\n/).slice(0, 5).join('\n');
  fs.writeFileSync(samplePath, lines, 'utf8');
} catch {
  fs.writeFileSync(samplePath, 'preview not available', 'utf8');
}

const headers = [];
try {
  const content = fs.readFileSync(file, 'utf8');
  headers.push(...(content.split(/\r?\n/)[0] || '').split(',').map(s => s.trim()).filter(Boolean));
} catch {
  // ignore
}

const out = {
  run_id: runId,
  job_id: jobId,
  landing_path: landingPath,
  file_hash: 'sha256:stub',
  headers,
  sample_preview_path: samplePath
};

writeJson(path.join('out', 'ingest', `${jobId}-result.json`), out);
console.log(JSON.stringify(out, null, 2));

