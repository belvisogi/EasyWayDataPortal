import sql from "mssql";
import { withTenantContext } from "../../utils/db";
import { QuotesRepo, QuoteRecord } from "../types";

export class SqlQuotesRepo implements QuotesRepo {
  async list(tenantId: string): Promise<QuoteRecord[]> {
    const result = await withTenantContext(tenantId, async (tx) => {
      return await new sql.Request(tx)
        .input("tenant_id", sql.NVarChar, tenantId)
        .execute("PORTAL.sp_list_quotes_by_tenant");
    });
    return result.recordset as QuoteRecord[];
  }

  async create(tenantId: string, data: {
    customer_name: string;
    customer_email: string;
    total_amount: number;
    valid_until?: string | null;
  }): Promise<QuoteRecord> {
    const result = await withTenantContext(tenantId, async (tx) => {
      return await new sql.Request(tx)
        .input("tenant_id", sql.NVarChar, tenantId)
        .input("customer_name", sql.NVarChar, data.customer_name)
        .input("customer_email", sql.NVarChar, data.customer_email)
        .input("total_amount", sql.Decimal(18, 2), data.total_amount)
        .input("valid_until", sql.NVarChar, data.valid_until ?? null)
        .input("created_by", sql.NVarChar, "api")
        .execute("PORTAL.sp_insert_quote");
    });
    const row = result.recordset[0];
    if (row && row.status !== "OK") {
      throw new Error(row.error_message || "Failed to create quote");
    }
    return { ...data, quote_id: row.quote_id, tenant_id: tenantId, status: "DRAFT", ...row };
  }

  async update(tenantId: string, quote_id: string, data: {
    status?: 'DRAFT' | 'SENT' | 'ACCEPTED' | 'REJECTED';
    total_amount?: number;
    valid_until?: string | null;
  }): Promise<QuoteRecord> {
    const result = await withTenantContext(tenantId, async (tx) => {
      return await new sql.Request(tx)
        .input("tenant_id", sql.NVarChar, tenantId)
        .input("quote_id", sql.NVarChar, quote_id)
        .input("status", sql.NVarChar, data.status ?? null)
        .input("total_amount", sql.Decimal(18, 2), data.total_amount ?? null)
        .input("valid_until", sql.NVarChar, data.valid_until ?? null)
        .input("updated_by", sql.NVarChar, "api")
        .execute("PORTAL.sp_update_quote");
    });
    const row = result.recordset[0];
    if (row && row.status !== "OK") {
      throw new Error(row.error_message || "Failed to update quote");
    }
    return { quote_id, tenant_id: tenantId, ...data, ...row } as QuoteRecord;
  }
}
