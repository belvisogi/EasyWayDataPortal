#!/usr/bin/env node
import fs from 'fs';
import path from 'path';
import { spawnSync } from 'child_process';

const base = 'docs/agentic/templates/events';
const schemasDir = path.join(base, 'schemas');
const samplesDir = path.join(base, 'samples');
const common = path.join(schemasDir, 'common.schema.json');

function validatePair(schemaFile, sampleFile) {
  const res = spawnSync('npx', ['-y', 'ajv-cli@5', 'validate', '-r', common, '-s', schemaFile, '-d', sampleFile, '--spec=draft2020', '--strict=false'], { encoding: 'utf8' });
  return { code: res.status, out: res.stdout, err: res.stderr };
}

function run() {
  const files = fs.readdirSync(samplesDir).filter(f => f.endsWith('.sample.json'));
  const results = [];
  let fail = false;
  for (const f of files) {
    const sample = path.join(samplesDir, f);
    const schemaName = f.replace('.sample.json', '.schema.json');
    const schema = path.join(schemasDir, schemaName);
    if (!fs.existsSync(schema)) {
      results.push({ sample: f, ok: false, error: `Schema not found: ${schemaName}` });
      fail = true;
      continue;
    }
    const r = validatePair(schema, sample);
    const ok = r.code === 0;
    results.push({ sample: f, schema: schemaName, ok, out: r.out.trim(), err: r.err.trim() });
    if (!ok) fail = true;
  }
  const summary = { ok: !fail, results };
  const logPath = path.join(process.cwd(), 'event-schema-validate.log');
  fs.writeFileSync(logPath, JSON.stringify(summary, null, 2));
  console.log(JSON.stringify(summary, null, 2));
  process.exit(fail ? 1 : 0);
}

run();

