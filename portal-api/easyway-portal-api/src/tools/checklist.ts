import fs from 'fs';
import path from 'path';
import YAML from 'yaml';
import { BlobServiceClient } from '@azure/storage-blob';
import { DefaultAzureCredential } from '@azure/identity';
import { getPool } from '../utils/db';

type CheckResult = { name: string; ok: boolean; details?: any; warning?: boolean };

function envPresent(keys: string[]): CheckResult {
  const missing = keys.filter(k => !process.env[k] || process.env[k] === '');
  return { name: 'env.required', ok: missing.length === 0, details: { missing } };
}

async function checkOpenApi(): Promise<CheckResult> {
  const specPath = path.resolve(__dirname, '../../openapi/openapi.yaml');
  try {
    const text = fs.readFileSync(specPath, 'utf-8');
    YAML.parse(text);
    return { name: 'openapi.exists_valid', ok: true, details: { path: specPath } };
  } catch (err: any) {
    return { name: 'openapi.exists_valid', ok: false, details: { error: err?.message, path: specPath } };
  }
}

async function checkSql(): Promise<CheckResult> {
  try {
    const pool = await getPool();
    const r = await pool.request().query('SELECT 1 as ok');
    const ok = r.recordset?.[0]?.ok === 1;
    return { name: 'sql.connect', ok, details: { rows: r.rowsAffected } };
  } catch (err: any) {
    return { name: 'sql.connect', ok: false, details: { error: err?.message } };
  }
}

async function buildBlobService(): Promise<BlobServiceClient | null> {
  const conn = process.env.AZURE_STORAGE_CONNECTION_STRING;
  const account = process.env.AZURE_STORAGE_ACCOUNT;
  if (conn) {
    return BlobServiceClient.fromConnectionString(conn, { retryOptions: { maxTries: 3, tryTimeoutInMs: 10000 } });
  }
  if (account) {
    const url = `https://${account}.blob.core.windows.net`;
    const cred = new DefaultAzureCredential();
    return new BlobServiceClient(url, cred, { retryOptions: { maxTries: 3, tryTimeoutInMs: 10000 } });
  }
  return null;
}

async function checkBranding(): Promise<CheckResult> {
  const container = process.env.BRANDING_CONTAINER;
  const prefix = (process.env.BRANDING_PREFIX || 'config').replace(/\/$/, '');
  const tenantId = process.env.CHECK_TENANT_ID || 'tenant01';
  try {
    const svc = await buildBlobService();
    if (!svc || !container) return { name: 'branding.storage', ok: false, details: { error: 'Storage not configured', container } };
    const cont = svc.getContainerClient(container);
    const blob = cont.getBlockBlobClient(`${prefix}/branding.${tenantId}.yaml`);
    const exists = await blob.exists();
    if (!exists) {
      return { name: 'branding.file', ok: false, details: { container, prefix, tenantId }, warning: true };
    }
    return { name: 'branding.file', ok: true, details: { container, prefix, tenantId } };
  } catch (err: any) {
    return { name: 'branding.storage', ok: false, details: { error: err?.message } };
  }
}

async function checkQueries(): Promise<CheckResult> {
  const container = process.env.QUERIES_CONTAINER || process.env.AZURE_STORAGE_CONTAINER;
  const prefix = (process.env.QUERIES_PREFIX || '').replace(/\/$/, '');
  try {
    if (!container) return { name: 'queries.container', ok: true, details: { note: 'not configured (optional)' }, warning: true };
    const svc = await buildBlobService();
    if (!svc) return { name: 'queries.storage', ok: false, details: { error: 'Storage not configured' } };
    const cont = svc.getContainerClient(container);
    // probe listing by prefix (non-fatal if empty)
    const it = cont.listBlobsFlat({ prefix: prefix ? `${prefix}/` : undefined });
    let found = false;
    for await (const _ of it) { found = true; break; }
    return { name: 'queries.prefix', ok: true, details: { container, prefix, hasItems: found } };
  } catch (err: any) {
    return { name: 'queries.storage', ok: false, details: { error: err?.message } };
  }
}

async function main() {
  const requiredEnv = [
    'AUTH_ISSUER', 'AUTH_JWKS_URI', 'TENANT_CLAIM',
    'BRANDING_CONTAINER',
  ];
  const checks: CheckResult[] = [];
  checks.push(envPresent(requiredEnv));
  checks.push(await checkOpenApi());
  checks.push(await checkSql());
  checks.push(await checkBranding());
  checks.push(await checkQueries());

  const summary = {
    ok: checks.every(c => c.ok),
    warnings: checks.filter(c => c.warning && c.ok).map(c => c.name),
    failed: checks.filter(c => !c.ok).map(c => ({ name: c.name, details: c.details })),
  };

  const mode = (process.env.CHECKLIST_OUTPUT || 'both').toLowerCase();
  const json = JSON.stringify({ checks, summary }, null, 2);
  if (mode === 'json' || mode === 'both') {
    console.log(json);
  }
  if (mode === 'human' || mode === 'both') {
    const human = [`Checklist – EasyWay API`, `Status: ${summary.ok ? 'OK' : 'FAIL'}`];
    for (const c of checks) human.push(`- ${c.name}: ${c.ok ? 'ok' : 'fail'}${c.warning ? ' (warn)' : ''}`);
    console.log(human.join('\n'));
  }

  process.exit(summary.ok ? 0 : 1);
}

main().catch(err => {
  console.error(JSON.stringify({ error: err?.message || String(err) }));
  process.exit(1);
});

