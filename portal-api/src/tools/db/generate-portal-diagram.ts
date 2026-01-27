import fs from "fs";
import path from "path";

type DiagramNode = { id: string; schema: string; table: string };
type DiagramColumn = { name: string; sql_type: string; nullable: boolean };
type DiagramEdge = {
  from: string;
  fromColumn: string;
  to: string;
  toColumn: string;
  kind: "explicit" | "inferred";
  confidence?: "high" | "medium" | "low";
  reason?: string;
};

type DiagramModel = {
  ok: boolean;
  schema: string;
  sourceOfTruth: { flywaySqlDir: string };
  generatedAtUtc: string;
  nodes: DiagramNode[];
  columns: { table: string; columns: DiagramColumn[] }[];
  edges: DiagramEdge[];
};

function ensureDir(p: string) {
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
}

function normalizeIdent(s: string) {
  return (s || "").trim().replace(/\s+/g, "_");
}

function extractCreateTableBlocks(text: string, schema: string): Array<{ table: string; body: string }> {
  const schemaU = schema.trim().toUpperCase();
  const rx = new RegExp(`\\bCREATE\\s+TABLE\\s+${schemaU}\\.([A-Za-z0-9_]+)\\b`, "gmi");
  const blocks: Array<{ table: string; body: string }> = [];

  let m: RegExpExecArray | null;
  while ((m = rx.exec(text))) {
    const table = m[1];
    const start = rx.lastIndex;
    const open = text.indexOf("(", start);
    if (open < 0) continue;

    let depth = 0;
    let end = -1;
    for (let i = open; i < text.length; i++) {
      const ch = text[i];
      if (ch === "(") depth++;
      else if (ch === ")") {
        depth--;
        if (depth === 0) {
          end = i;
          break;
        }
      }
    }
    if (end < 0) continue;
    const body = text.substring(open + 1, end);
    blocks.push({ table, body });
  }
  return blocks;
}

function parseColumnsFromBody(body: string): DiagramColumn[] {
  const lines = body
    .split("\n")
    .map((l) => l.trim().replace(/\r$/, ""))
    .filter(Boolean);

  const cols: DiagramColumn[] = [];
  for (const line0 of lines) {
    const line = line0.replace(/,+$/, "").trim();
    if (!line) continue;
    if (/^CONSTRAINT\b/i.test(line)) continue;

    const cm = line.match(/^(?:\[([A-Za-z0-9_]+)\]|([A-Za-z0-9_]+))\s+(.+)$/);
    if (!cm) continue;
    const name = cm[1] || cm[2];
    const rest = (cm[3] || "").trim();
    const tm = rest.match(/^([A-Za-z0-9_]+(?:\s*\([^)]+\))?)\s*(.*)$/);
    if (!tm) continue;
    const sqlType = tm[1].replace(/\s+/g, "").toLowerCase();
    const after = tm[2] || "";
    const nullable = !/\bNOT\s+NULL\b/i.test(after);
    cols.push({ name, sql_type: sqlType, nullable });
  }
  return cols;
}

function parseExplicitFksFromBody(schema: string, table: string, body: string): DiagramEdge[] {
  const out: DiagramEdge[] = [];
  const rx = /\bCONSTRAINT\s+\[[^\]]+\]\s+FOREIGN\s+KEY\s+\(\s*\[([A-Za-z0-9_]+)\]\s*\)\s+REFERENCES\s+\[([A-Za-z0-9_]+)\]\.\[([A-Za-z0-9_]+)\]\(\[([A-Za-z0-9_]+)\]\)/gim;
  let m: RegExpExecArray | null;
  while ((m = rx.exec(body))) {
    const fromCol = normalizeIdent(m[1]);
    const refSchema = normalizeIdent(m[2]).toUpperCase();
    const refTable = normalizeIdent(m[3]).toUpperCase();
    const refCol = normalizeIdent(m[4]);
    if (!fromCol || !refSchema || !refTable || !refCol) continue;
    out.push({
      from: `${schema}.${table}`,
      fromColumn: fromCol,
      to: `${refSchema}.${refTable}`,
      toColumn: refCol,
      kind: "explicit",
      confidence: "high",
      reason: "DDL constraint FOREIGN KEY",
    });
  }
  return out;
}

function hasCol(columnsByTable: Map<string, DiagramColumn[]>, tableId: string, colName: string) {
  const cols = columnsByTable.get(tableId) || [];
  const n = colName.toLowerCase();
  return cols.some((c) => (c.name || "").toLowerCase() === n);
}

function main() {
  const schema = (process.env.DB_DIAGRAM_SCHEMA || "PORTAL").trim().toUpperCase();
  const flywaySqlDir =
    process.env.FLYWAY_SQL_DIR || path.resolve(process.cwd(), "../../db/flyway/sql");
  const outJson =
    process.env.DB_DIAGRAM_OUT || path.resolve(process.cwd(), "data/db/portal-diagram.json");

  if (!fs.existsSync(flywaySqlDir)) {
    throw new Error(`Flyway dir not found: ${flywaySqlDir}`);
  }

  const files = fs
    .readdirSync(flywaySqlDir)
    .filter((f) => f.toLowerCase().endsWith(".sql"))
    .sort((a, b) => a.localeCompare(b));

  let sql = "";
  for (const f of files) {
    sql += fs.readFileSync(path.join(flywaySqlDir, f), "utf-8") + "\n";
  }

  const blocks = extractCreateTableBlocks(sql, schema);
  const nodes = new Map<string, DiagramNode>();
  const columnsByTable = new Map<string, DiagramColumn[]>();
  const edges: DiagramEdge[] = [];

  for (const b of blocks) {
    const table = normalizeIdent(b.table).toUpperCase();
    const id = `${schema}.${table}`;
    nodes.set(id, { id, schema, table });
    const cols = parseColumnsFromBody(b.body);
    columnsByTable.set(id, cols);
    edges.push(...parseExplicitFksFromBody(schema, table, b.body));
  }

  // Inferred relationships (project conventions)
  const tenantTable = `${schema}.TENANT`;
  const usersTable = `${schema}.USERS`;
  const profileDomainsTable = `${schema}.PROFILE_DOMAINS`;

  function addInferred(fromTableId: string, fromCol: string, toTableId: string, toCol: string, reason: string) {
    edges.push({
      from: fromTableId,
      fromColumn: fromCol,
      to: toTableId,
      toColumn: toCol,
      kind: "inferred",
      confidence: "high",
      reason,
    });
  }

  for (const id of nodes.keys()) {
    if (id !== tenantTable && hasCol(columnsByTable, id, "tenant_id") && hasCol(columnsByTable, tenantTable, "tenant_id")) {
      addInferred(id, "tenant_id", tenantTable, "tenant_id", "Convention: tenant_id references PORTAL.TENANT.tenant_id");
    }
    if (id !== usersTable && hasCol(columnsByTable, id, "user_id") && hasCol(columnsByTable, usersTable, "user_id")) {
      addInferred(id, "user_id", usersTable, "user_id", "Convention: user_id references PORTAL.USERS.user_id (note: logical composite key may include tenant_id).");
    }
    if (
      id !== profileDomainsTable &&
      hasCol(columnsByTable, id, "profile_code") &&
      hasCol(columnsByTable, profileDomainsTable, "profile_code")
    ) {
      addInferred(id, "profile_code", profileDomainsTable, "profile_code", "Convention: profile_code references PORTAL.PROFILE_DOMAINS.profile_code");
    }
  }

  const model: DiagramModel = {
    ok: true,
    schema,
    sourceOfTruth: { flywaySqlDir: "db/flyway/sql" },
    generatedAtUtc: new Date().toISOString(),
    nodes: Array.from(nodes.values()).sort((a, b) => a.id.localeCompare(b.id)),
    columns: Array.from(columnsByTable.entries())
      .map(([table, columns]) => ({ table, columns }))
      .sort((a, b) => a.table.localeCompare(b.table)),
    edges,
  };

  ensureDir(path.dirname(outJson));
  fs.writeFileSync(outJson, JSON.stringify(model, null, 2), "utf-8");
  // eslint-disable-next-line no-console
  console.log(JSON.stringify({ ok: true, schema, flywaySqlDir, outJson }, null, 2));
}

main();

