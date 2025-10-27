#!/usr/bin/env node
import path from 'path';
import { arg, writeJson } from './_util.mjs';

const runId = arg('--run_id');
const landingPath = arg('--landing_path');
const mappingTemplateId = arg('--mapping_template_id');

if (!runId || !landingPath) {
  console.error('Usage: node scripts/intents/etl.load-staging.mjs --run_id <id> --landing_path <path> [--mapping_template_id <id>]');
  process.exit(1);
}

const stagingTable = 'stg.fact_transactions_raw';
const rowCounts = { total: 0 };
const out = { staging_table: stagingTable, row_counts: rowCounts };
writeJson(path.join('out','etl', `${runId}-staging.json`), out);
console.log(JSON.stringify(out, null, 2));

