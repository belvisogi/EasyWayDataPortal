#!/usr/bin/env node
import { spawnSync } from 'child_process';
import fs from 'fs';
import path from 'path';

function arg(name, def) {
  const i = process.argv.indexOf(name);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : def;
}

function run(cmd, args, stage) {
  const res = spawnSync(cmd, args, { encoding: 'utf8' });
  if (res.error) throw res.error;
  if (res.status !== 0) {
    return { ok: false, err: res.stderr || res.stdout, stage };
  }
  try {
    const json = JSON.parse(res.stdout.trim());
    return { ok: true, json, raw: res.stdout };
  } catch (e) {
    return { ok: false, err: `Invalid JSON from ${stage}: ${e}`, out: res.stdout, stage };
  }
}

function nowIso() { return new Date().toISOString(); }
function ensureDir(d) { fs.mkdirSync(d, { recursive: true }); }

const file = arg('--file');
const user = arg('--user', 'u01');
const tenant = arg('--tenant', 't01');
const domain = arg('--domain', 'customer');
const flow = arg('--flow', 'personal_finance');
const instance = arg('--instance', 'pf_tx_monthly');
if (!file) {
  console.error('Usage: node scripts/wf.run-excel-csv-upload.mjs --file <path> [--user u01] [--tenant t01] [--domain customer] [--flow personal_finance] [--instance pf_tx_monthly]');
  process.exit(1);
}

const diary = { started_at: nowIso(), scope: { user, tenant, domain, flow, instance }, timeline: [] };

// 1) Ingest
let step = run('node', ['scripts/intents/ingest.upload-file.mjs', '--file', file, '--user', user, '--tenant', tenant, '--domain', domain, '--flow', flow, '--instance', instance], 'ingest.upload-file');
if (!step.ok) { diary.timeline.push({ timestamp: nowIso(), stage: 'uploaded', outcome: 'ERROR', reason: step.err }); finalize(false); }
const ingest = step.json; diary.run_id = ingest.run_id;
diary.timeline.push({ timestamp: nowIso(), stage: 'uploaded', outcome: 'OK', next: 'parsed', artifacts: [ingest.sample_preview_path] });

// 2) DQ
const headersCsv = (ingest.headers || []).join(',');
step = run('node', ['scripts/intents/dq.validate.mjs', '--run_id', ingest.run_id, '--headers', headersCsv, '--sample_preview_path', ingest.sample_preview_path], 'dq.validate');
if (!step.ok) { diary.timeline.push({ timestamp: nowIso(), stage: 'dq_evaluated', outcome: 'ERROR', reason: step.err }); finalize(false); }
const dq = step.json; diary.decision_trace_id = dq.decision_trace_id;
diary.timeline.push({ timestamp: nowIso(), stage: 'dq_evaluated', outcome: dq.gate_outcome, reason: dq.gate_outcome === 'DEFER' ? 'warnings' : undefined, next: dq.gate_outcome === 'FAIL' ? 'failed' : 'mapped', decision_trace_id: dq.decision_trace_id, artifacts: [dq.dq_summary_path] });
if (dq.gate_outcome === 'FAIL') finalize(false);

// 3) Mapping suggest
step = run('node', ['scripts/intents/schema.map-suggest.mjs', '--headers', headersCsv], 'schema.map-suggest');
if (!step.ok) { diary.timeline.push({ timestamp: nowIso(), stage: 'mapped', outcome: 'ERROR', reason: step.err }); finalize(false); }
const suggest = step.json;
const suggestPath = path.join('out', 'mapping', `${ingest.run_id}-suggest.json`);
ensureDir(path.dirname(suggestPath));
fs.writeFileSync(suggestPath, JSON.stringify(suggest, null, 2));
diary.timeline.push({ timestamp: nowIso(), stage: 'mapped', outcome: suggest.missing_fields?.length ? 'WARN' : 'OK', reason: suggest.missing_fields?.length ? `missing: ${suggest.missing_fields.join(',')}` : undefined, next: 'staged', artifacts: [suggestPath] });

// 4) Mapping apply
step = run('node', ['scripts/intents/schema.map-apply.mjs', '--run_id', ingest.run_id, '--mapping_json', suggestPath, '--save_template', 'true', '--template_name', 'pf_default'], 'schema.map-apply');
if (!step.ok) { diary.timeline.push({ timestamp: nowIso(), stage: 'mapped', outcome: 'ERROR', reason: step.err }); finalize(false); }
const mapApply = step.json;

// 5) Staging
step = run('node', ['scripts/intents/etl.load-staging.mjs', '--run_id', ingest.run_id, '--landing_path', ingest.landing_path, '--mapping_template_id', mapApply.mapping_template_id || ''], 'etl.load-staging');
if (!step.ok) { diary.timeline.push({ timestamp: nowIso(), stage: 'staged', outcome: 'ERROR', reason: step.err }); finalize(false); }
const staging = step.json;
diary.timeline.push({ timestamp: nowIso(), stage: 'staged', outcome: 'OK', next: 'merged', artifacts: [path.join('out','etl', `${ingest.run_id}-staging.json`)] });

// 6) Merge
step = run('node', ['scripts/intents/etl.merge-target.mjs', '--run_id', ingest.run_id, '--staging_table', staging.staging_table], 'etl.merge-target');
if (!step.ok) { diary.timeline.push({ timestamp: nowIso(), stage: 'merged', outcome: 'ERROR', reason: step.err }); finalize(false); }
const merge = step.json;
diary.timeline.push({ timestamp: nowIso(), stage: 'merged', outcome: merge.merge_stats?.ok ? 'OK' : 'ERROR', next: 'materialized', artifacts: [path.join('out','etl', `${ingest.run_id}-merge.json`)] });

// 7) Views
step = run('node', ['scripts/intents/analytics.materialize-defaults.mjs', '--instance_id', instance, '--target_table', merge.target_table], 'analytics.materialize-defaults');
if (!step.ok) { diary.timeline.push({ timestamp: nowIso(), stage: 'materialized', outcome: 'ERROR', reason: step.err }); finalize(false); }
const views = step.json;
diary.timeline.push({ timestamp: nowIso(), stage: 'materialized', outcome: 'OK', next: 'completed' });

// 8) Done
diary.timeline.push({ timestamp: nowIso(), stage: 'completed', outcome: 'OK', artifacts: [] });
finalize(true, { views: views.views, kpi: views.kpi });

function finalize(success, extra = {}) {
  diary.completed_at = nowIso();
  diary.success = !!success;
  Object.assign(diary, extra);
  ensureDir(path.join('out','diary'));
  fs.writeFileSync(path.join('out','diary','diary.json'), JSON.stringify(diary, null, 2));
  console.log(JSON.stringify({ ok: !!success, diary: 'out/diary/diary.json' }, null, 2));
  process.exit(success ? 0 : 1);
}

