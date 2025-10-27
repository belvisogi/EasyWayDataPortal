#!/usr/bin/env node
import path from 'path';
import { arg, writeJson } from './_util.mjs';

const runId = arg('--run_id');
const stagingTable = arg('--staging_table');

if (!runId || !stagingTable) {
  console.error('Usage: node scripts/intents/etl.merge-target.mjs --run_id <id> --staging_table <name>');
  process.exit(1);
}

const targetTable = 'dm.fact_transactions';
const mergeStats = { inserted: 0, updated: 0, deduped: 0, ok: true };
const out = { target_table: targetTable, merge_stats: mergeStats };
writeJson(path.join('out','etl', `${runId}-merge.json`), out);
console.log(JSON.stringify(out, null, 2));

