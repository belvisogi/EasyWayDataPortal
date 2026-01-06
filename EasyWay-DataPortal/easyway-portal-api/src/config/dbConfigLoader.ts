// easyway-portal-api/src/config/dbConfigLoader.ts
import sql from "mssql";
import { getPool } from "../utils/db";

/**
 * Carica parametri di configurazione dal DB per un tenant in modalità "golden path": solo SP e campi DDL-compliant.
 * @param tenantId Tenant identificativo
 * @returns Oggetto chiave/valore della config
 */
export async function loadDbConfig(
  tenantId: string,
  tx?: sql.Transaction
): Promise<Record<string, string>> {
  const pool = await getPool();

  const request = (tx ? new sql.Request(tx) : pool.request())
    .input("tenant_id", sql.NVarChar, tenantId);

  const result = await request.execute("PORTAL.sp_get_config_by_tenant");
  const config: Record<string, string> = {};
  result.recordset.forEach((row: any) => {
    config[row.config_key] = row.config_value;
  });
  return config;
}
