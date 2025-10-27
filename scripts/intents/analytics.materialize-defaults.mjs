#!/usr/bin/env node
import path from 'path';
import { arg, writeJson } from './_util.mjs';

const instanceId = arg('--instance_id');
const targetTable = arg('--target_table');

if (!instanceId || !targetTable) {
  console.error('Usage: node scripts/intents/analytics.materialize-defaults.mjs --instance_id <id> --target_table <name>');
  process.exit(1);
}

const views = ['vw_tx_time_series', 'vw_tx_by_category', 'vw_tx_kpi'];
const kpi = { total_income: 0, total_expense: 0, balance: 0 };
const out = { views, kpi };
writeJson(path.join('out','analytics', `${instanceId}-materialize.json`), out);
console.log(JSON.stringify(out, null, 2));

