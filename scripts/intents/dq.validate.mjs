#!/usr/bin/env node
import path from 'path';
import { arg, writeJson, nowId, splitCsv } from './_util.mjs';

const runId = arg('--run_id');
const headersStr = arg('--headers', '');
const sample = arg('--sample_preview_path');
const policyHint = arg('--policy_set_hint', 'personal-finance-light');

if (!runId || !sample) {
  console.error('Usage: node scripts/intents/dq.validate.mjs --run_id <id> --headers <h1,h2,...> --sample_preview_path <path> [--policy_set_hint <hint>]');
  process.exit(1);
}

const headers = splitCsv(headersStr);
const decisionTraceId = nowId('trace');
const outcome = headers.length > 0 ? 'DEFER' : 'PASS'; // stub: defer if headers present (simulate warnings)
const dqSummaryPath = path.join('out', 'dq', `${runId}-summary.json`);

writeJson(dqSummaryPath, { run_id: runId, headers, sample_preview_path: sample, policy_set_hint: policyHint, warnings: outcome === 'DEFER' ? ['categorias_non_riconosciute', 'duplicati_potenziali'] : [] });

const out = {
  dq_summary_path: dqSummaryPath,
  gate_outcome: outcome,
  decision_trace_id: decisionTraceId
};

writeJson(path.join('out', 'dq', `${runId}-result.json`), out);
console.log(JSON.stringify(out, null, 2));

