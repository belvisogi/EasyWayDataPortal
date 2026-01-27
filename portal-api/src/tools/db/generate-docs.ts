import fs from 'fs';
import path from 'path';
import sql from 'mssql';
import { getPool } from '../../utils/db';

function ensureDir(p: string) {
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
}

async function fetchTables(pool: sql.ConnectionPool) {
  const q = `
    SELECT TABLE_SCHEMA, TABLE_NAME
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE='BASE TABLE'
    ORDER BY TABLE_SCHEMA, TABLE_NAME`;
  const r = await pool.request().query(q);
  return r.recordset as { TABLE_SCHEMA: string; TABLE_NAME: string }[];
}

async function fetchColumns(pool: sql.ConnectionPool) {
  const q = `
    SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE
    FROM INFORMATION_SCHEMA.COLUMNS`;
  const r = await pool.request().query(q);
  return r.recordset as { TABLE_SCHEMA: string; TABLE_NAME: string; COLUMN_NAME: string; DATA_TYPE: string; IS_NULLABLE: string }[];
}

async function fetchFks(pool: sql.ConnectionPool) {
  const q = `
    SELECT 
      FK.name AS FK_NAME,
      SCHEMA_NAME(tp.schema_id) AS PK_SCHEMA,
      tp.name AS PK_TABLE,
      SCHEMA_NAME(tf.schema_id) AS FK_SCHEMA,
      tf.name AS FK_TABLE
    FROM sys.foreign_keys FK
    JOIN sys.tables tp ON FK.referenced_object_id = tp.object_id
    JOIN sys.tables tf ON FK.parent_object_id = tf.object_id`;
  const r = await pool.request().query(q);
  return r.recordset as { FK_NAME: string; PK_SCHEMA: string; PK_TABLE: string; FK_SCHEMA: string; FK_TABLE: string }[];
}

async function fetchProcedures(pool: sql.ConnectionPool) {
  const q = `
    SELECT SCHEMA_NAME(p.schema_id) AS [schema], p.name AS [name], p.object_id
    FROM sys.procedures p
    ORDER BY [schema], [name]`;
  const r = await pool.request().query(q);
  return r.recordset as { schema: string; name: string; object_id: number }[];
}

async function fetchParameters(pool: sql.ConnectionPool, objIds: number[]) {
  if (objIds.length === 0) return [] as any[];
  const chunks: number[][] = [];
  for (let i = 0; i < objIds.length; i += 1000) chunks.push(objIds.slice(i, i + 1000));
  const all: any[] = [];
  for (const ch of chunks) {
    const q = `SELECT object_id, name, parameter_id, system_type_id
               FROM sys.parameters WHERE object_id IN (${ch.join(',')}) ORDER BY object_id, parameter_id`;
    const r = await pool.request().query(q);
    all.push(...r.recordset);
  }
  return all;
}

function buildMermaidER(tables: any[], fks: any[]) {
  const lines: string[] = ['```mermaid', 'erDiagram'];
  for (const t of tables) {
    lines.push(`  ${t.TABLE_SCHEMA}_${t.TABLE_NAME} {}`);
  }
  for (const fk of fks) {
    lines.push(`  ${fk.PK_SCHEMA}_${fk.PK_TABLE} ||--o{ ${fk.FK_SCHEMA}_${fk.FK_TABLE} : FK_${fk.FK_NAME}`);
  }
  lines.push('```');
  return lines.join('\n');
}

function buildSpCatalog(procs: any[], parms: any[]) {
  const map = new Map<number, any[]>();
  for (const p of parms) {
    const arr = map.get(p.object_id) || [];
    arr.push(p);
    map.set(p.object_id, arr);
  }
  const lines: string[] = [];
  lines.push('# Catalogo Stored Procedure');
  for (const sp of procs) {
    lines.push(`\n## ${sp.schema}.${sp.name}`);
    const ps = map.get(sp.object_id) || [];
    if (ps.length === 0) {
      lines.push('- (nessun parametro)');
    } else {
      for (const prm of ps) lines.push(`- ${prm.name}`);
    }
  }
  return lines.join('\n');
}

async function main() {
  const pool = await getPool();
  const [tables, cols, fks, procs] = await Promise.all([
    fetchTables(pool), fetchColumns(pool), fetchFks(pool), fetchProcedures(pool)
  ]);
  const parms = await fetchParameters(pool, procs.map(p => p.object_id));

  const erd = buildMermaidER(tables, fks);
  const spcat = buildSpCatalog(procs, parms);

  const outDir = process.env.DB_DOCS_OUT || path.resolve(process.cwd(), '../../Wiki/EasyWayData.wiki/EasyWay_WebApp/01_database_architecture');
  ensureDir(outDir);
  fs.writeFileSync(path.join(outDir, 'ERD.md'), erd, 'utf-8');
  fs.writeFileSync(path.join(outDir, 'SP_CATALOG.md'), spcat, 'utf-8');

  const summary = { ok: true, tables: tables.length, procedures: procs.length, outDir };
  console.log(JSON.stringify({ summary }, null, 2));
}

main().catch(err => {
  console.error(JSON.stringify({ ok: false, error: err?.message || String(err) }));
  process.exit(1);
});

