#!/usr/bin/env node
/*
  Generate DB artifacts (DDL + SP) from a mini-DSL JSON
  Usage:
    node agents/core/generate-db-artifacts.js --in path/to/dsl.json [--out db/flyway/sql]

  DSL example (see docs/agentic/AGENTIC_READINESS.md):
  {
    "entity": "USERS",
    "schema": "PORTAL",
    "columns": [{"name":"user_id","type":"NVARCHAR(50)","constraints":["NOT NULL","UNIQUE"]}],
    "sp": { "insert": {"name":"sp_insert_user"}, "update": {"name":"sp_update_user"}, "delete": {"name":"sp_delete_user"} }
  }
*/

const fs = require('fs');
const path = require('path');

function parseArgs(argv){
  const out = { flags: {} };
  for (let i=2; i<argv.length; i++){
    const a = argv[i];
    if (a.startsWith('--')){
      const k = a.replace(/^--/, '');
      const n = argv[i+1];
      if (!n || n.startsWith('--')) { out.flags[k] = true; }
      else { out.flags[k] = n; i++; }
    }
  }
  return out;
}

function readJson(p){ return JSON.parse(fs.readFileSync(p, 'utf-8')); }
function readText(p){ return fs.readFileSync(p, 'utf-8'); }
function ensureDir(d){ fs.mkdirSync(d, { recursive: true }); }

function nowVersion(){
  const d = new Date();
  const pad = (n)=> String(n).padStart(2,'0');
  return `V${d.getFullYear()}${pad(d.getMonth()+1)}${pad(d.getDate())}${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}`;
}

function sanitizeObj(x){ return String(x||'').trim().replace(/\s+/g, '_').toLowerCase(); }

function buildColumns(cols){
  if (!Array.isArray(cols)) return '-- none';
  return cols.map(c => {
    const cons = Array.isArray(c.constraints) && c.constraints.length ? ' ' + c.constraints.join(' ') : '';
    return `    ${c.name} ${c.type}${cons},`;
  }).join('\n');
}

function fill(tpl, map){
  let out = tpl;
  for (const [k,v] of Object.entries(map)){
    const rx = new RegExp(`{{${k}}}`,'g');
    out = out.replace(rx, v);
  }
  return out;
}

function main(){
  const { flags } = parseArgs(process.argv);
  const inPath = flags.in;
  const outDir = flags.out || path.resolve('db/flyway/sql');
  if (!inPath) { console.error('Missing --in <dsl.json>'); process.exit(1); }

  const dsl = readJson(inPath);
  const schema = dsl.schema || 'PORTAL';
  const table = dsl.entity || dsl.table || 'ENTITY';
  const object = sanitizeObj(table);

  const ddlTpl = readText(path.resolve('docs/agentic/templates/ddl/template_table.sql'));
  const spInsTpl = readText(path.resolve('docs/agentic/templates/sp/template_sp_insert.sql'));
  const spUpdTpl = readText(path.resolve('docs/agentic/templates/sp/template_sp_update.sql'));
  const spDelTpl = readText(path.resolve('docs/agentic/templates/sp/template_sp_delete.sql'));

  const columnsBlock = buildColumns(dsl.columns);
  const mapBase = { SCHEMA: schema, TABLE: table, OBJECT: object, COLUMNS: columnsBlock };

  const ddl = fill(ddlTpl, mapBase);
  const spInsert = fill(spInsTpl, {
    ...mapBase,
    PARAMS: '-- TODO: add parameters',
    INSERT_BLOCK: '-- TODO: insert logic'
  });
  const spUpdate = fill(spUpdTpl, {
    ...mapBase,
    PARAMS: '-- TODO: add key + updatable fields',
    UPDATE_BLOCK: '-- TODO: update logic'
  });
  const spDelete = fill(spDelTpl, {
    ...mapBase,
    PARAMS: '-- TODO: add key parameters',
    DELETE_BLOCK: '-- TODO: delete/soft-delete logic'
  });

  const composite = [ddl, '', spInsert, '', spUpdate, '', spDelete].join('\n');
  ensureDir(outDir);
  const ver = nowVersion();
  const fname = `${ver}__${schema}_${object}_generated.sql`;
  const outPath = path.join(outDir, fname);
  fs.writeFileSync(outPath, composite, 'utf-8');

  const summary = {
    ok: true,
    outFile: path.relative(process.cwd(), outPath),
    schema, table, object,
  };
  console.log(JSON.stringify(summary, null, 2));
}

try { main(); } catch (e) { console.error(e?.message || String(e)); process.exit(1); }

