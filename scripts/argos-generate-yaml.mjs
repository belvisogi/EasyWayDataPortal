#!/usr/bin/env node
import fs from 'fs';
import path from 'path';

function arg(k, def) {
  const idx = process.argv.indexOf(k);
  if (idx >= 0 && process.argv[idx + 1]) return process.argv[idx + 1];
  return def;
}

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function readJson(p) {
  const txt = fs.readFileSync(p, 'utf8');
  return JSON.parse(txt);
}

function toYaml(obj, indent = 0) {
  const sp = '  '.repeat(indent);
  if (obj === null) return 'null';
  if (typeof obj === 'number') return String(obj);
  if (typeof obj === 'boolean') return obj ? 'true' : 'false';
  if (typeof obj === 'string') {
    if (/[:#\-\n\r\t]/.test(obj)) return JSON.stringify(obj);
    return obj;
  }
  if (Array.isArray(obj)) {
    if (obj.length === 0) return '[]';
    return obj.map(v => sp + '- ' + toYaml(v, indent + 1).replace(/^\s+/, '')).join('\n');
  }
  const keys = Object.keys(obj || {});
  if (keys.length === 0) return '{}';
  return keys.map(k => {
    const v = obj[k];
    const valStr = toYaml(v, indent + 1);
    if (typeof v === 'object' && v !== null && !Array.isArray(v)) {
      return sp + k + ':\n' + '  '.repeat(indent + 1) + valStr.replace(/^/gm, '');
    } else if (Array.isArray(v)) {
      const arrStr = toYaml(v, indent + 1);
      return sp + k + ':\n' + arrStr;
    } else {
      return sp + k + ': ' + valStr;
    }
  }).join('\n');
}

function help() {
  console.log(`Usage:
  node scripts/argos-generate-yaml.mjs --type policy-set --registry <registry.json> --domain <id> --flow <id> --instance <id> --out <dir>
  node scripts/argos-generate-yaml.mjs --type playbook --playbook <playbook.json> --out <dir>

Notes:
  - The registry/playbook JSON is typically exported from DB by a job.
  - YAML is generated on-the-fly and can be published as CI artifact.
`);
}

const type = arg('--type');
if (!type) {
  help();
  process.exit(1);
}

const outDir = arg('--out', 'out/argos');
ensureDir(outDir);

if (type === 'policy-set') {
  const regPath = arg('--registry');
  const domainId = arg('--domain');
  const flowId = arg('--flow');
  const instanceId = arg('--instance');
  if (!regPath || !domainId || !flowId || !instanceId) {
    help();
    process.exit(1);
  }
  const reg = readJson(regPath);
  const key = `${domainId}::${flowId}::${instanceId}`;
  const set = (reg.policy_sets || []).find(p => (
    p?.scope?.domain_id === domainId &&
    p?.scope?.flow_id === flowId &&
    p?.scope?.instance_id === instanceId
  ));
  if (!set) {
    console.error(`Policy set not found for scope ${key}`);
    process.exit(2);
  }
  const minimal = {
    policy_set: {
      id: set.id,
      version: set.version,
      scope: { domain_id: domainId, flow_id: flowId, instance_id: instanceId },
      rules: (set.rules || []).map(r => ({
        rule_id: r.rule_id,
        rule_version: r.rule_version,
        severity_base: r.severity_base,
        impact_score: r.impact_score
      })),
      metadata: { owner: set?.metadata?.owner || 'n/a', tags: set?.metadata?.tags || [] }
    }
  };
  const yaml = toYaml(minimal);
  const fname = `policy-set.${domainId}.${flowId}.${instanceId}.yaml`;
  const outPath = path.join(outDir, fname);
  fs.writeFileSync(outPath, yaml + '\n', 'utf8');
  console.log(outPath);
  process.exit(0);
}

if (type === 'playbook') {
  const pbJson = arg('--playbook');
  if (!pbJson) {
    help();
    process.exit(1);
  }
  const p = readJson(pbJson);
  const minimal = {
    playbook: {
      pb_id: p.playbook?.pb_id || p.pb_id,
      title: p.playbook?.title || p.title,
      version: p.playbook?.version || p.version || '1.0.0',
      owner: p.playbook?.owner || p.owner || 'n/a',
      mode: p.playbook?.mode || p.mode,
      scope: p.playbook?.scope || p.scope,
      tags: p.playbook?.tags || p.tags || [],
      triggers: p.playbook?.triggers || p.triggers || [],
      guardrail: p.playbook?.guardrail || p.guardrail || {},
      procedure: p.playbook?.procedure || p.procedure || {},
      telemetry: p.playbook?.telemetry || p.telemetry || {}
    }
  };
  const id = minimal.playbook.pb_id || 'pb';
  const yaml = toYaml(minimal);
  const fname = `${id}.yaml`;
  const outPath = path.join(outDir, fname);
  fs.writeFileSync(outPath, yaml + '\n', 'utf8');
  console.log(outPath);
  process.exit(0);
}

help();
process.exit(1);

