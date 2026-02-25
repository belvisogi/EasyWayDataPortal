import { QuotesRepo, QuoteRecord } from "../types";
import { readJsonFile, writeJsonFile } from "../../utils/fileStore";
import { randomUUID } from "crypto";

type QuotesDb = { quotes: QuoteRecord[] };

const FILE = "dev-quotes.json";

function load(): QuotesDb { return readJsonFile<QuotesDb>(FILE, { quotes: [] }); }
function save(db: QuotesDb) { writeJsonFile<QuotesDb>(FILE, db); }

export class MockQuotesRepo implements QuotesRepo {
  async list(tenantId: string): Promise<QuoteRecord[]> {
    const db = load();
    return db.quotes.filter(q => q.tenant_id === tenantId);
  }

  async create(tenantId: string, data: {
    customer_name: string;
    customer_email: string;
    total_amount: number;
    valid_until?: string | null;
  }): Promise<QuoteRecord> {
    const db = load();
    const rec: QuoteRecord = {
      quote_id: `QUO-${randomUUID()}`,
      tenant_id: tenantId,
      customer_name: data.customer_name,
      customer_email: data.customer_email,
      total_amount: data.total_amount,
      status: 'DRAFT',
      valid_until: data.valid_until ?? null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    db.quotes.push(rec);
    save(db);
    return rec;
  }

  async update(tenantId: string, quote_id: string, data: {
    status?: 'DRAFT' | 'SENT' | 'ACCEPTED' | 'REJECTED';
    total_amount?: number;
    valid_until?: string | null;
  }): Promise<QuoteRecord> {
    const db = load();
    const idx = db.quotes.findIndex(q => q.quote_id === quote_id && q.tenant_id === tenantId);
    if (idx < 0) throw new Error("Quote not found");
    const cur = db.quotes[idx];
    const next: QuoteRecord = {
      ...cur,
      status: data.status ?? cur.status,
      total_amount: data.total_amount ?? cur.total_amount,
      valid_until: (data.valid_until === undefined ? cur.valid_until : data.valid_until) ?? null,
      updated_at: new Date().toISOString(),
    };
    db.quotes[idx] = next;
    save(db);
    return next;
  }
}
