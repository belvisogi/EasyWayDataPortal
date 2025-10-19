import sql from 'mssql';
import fs from 'fs';
import path from 'path';
import { getPool } from '../../utils/db';

type RequiredObjects = { tables?: string[]; procedures?: string[] };

function loadRequired(): RequiredObjects {
  const configPath = process.env.DB_REQUIRED_OBJECTS || path.resolve(process.cwd(), '../../scripts/variables/db-required-objects.sample.json');
  if (!fs.existsSync(configPath)) return { tables: [], procedures: [] };
  return JSON.parse(fs.readFileSync(configPath, 'utf-8')) as RequiredObjects;
}

async function existsTable(pool: sql.ConnectionPool, fullName: string): Promise<boolean> {
  const [schema, name] = fullName.split('.');
  const q = `SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA=@s AND TABLE_NAME=@n`;
  const r = await pool.request().input('s', sql.NVarChar, schema).input('n', sql.NVarChar, name).query(q);
  return r.recordset.length > 0;
}

async function existsProc(pool: sql.ConnectionPool, fullName: string): Promise<boolean> {
  const [schema, name] = fullName.split('.');
  const q = `SELECT 1 FROM sys.procedures WHERE schema_id = SCHEMA_ID(@s) AND name=@n`;
  const r = await pool.request().input('s', sql.NVarChar, schema).input('n', sql.NVarChar, name).query(q);
  return r.recordset.length > 0;
}

async function main() {
  const req = loadRequired();
  const pool = await getPool();
  const missingTables: string[] = [];
  const missingProcs: string[] = [];

  for (const t of req.tables || []) { if (!(await existsTable(pool, t))) missingTables.push(t); }
  for (const p of req.procedures || []) { if (!(await existsProc(pool, p))) missingProcs.push(p); }

  const ok = missingTables.length === 0 && missingProcs.length === 0;
  const report = { ok, missing: { tables: missingTables, procedures: missingProcs } };
  console.log(JSON.stringify(report, null, 2));
  process.exit(ok ? 0 : 1);
}

main().catch(err => { console.error(JSON.stringify({ ok:false, error: err?.message || String(err) })); process.exit(1); });

