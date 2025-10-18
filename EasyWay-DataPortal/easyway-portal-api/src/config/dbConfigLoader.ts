// easyway-portal-api/src/config/dbConfigLoader.ts
import sql from "mssql";

/**
 * Carica parametri di configurazione dal DB per un tenant.
 * @param tenantId Tenant identificativo
 * @param section  Sezione di configurazione (opzionale)
 * @returns Oggetto chiave/valore della config
 */
export async function loadDbConfig(
  tenantId: string,
  section?: string
): Promise<Record<string, string>> {
  // Connessione DB (parametri da .env)
  const pool = await sql.connect({
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    server: process.env.DB_HOST,
    database: process.env.DB_NAME,
    options: { encrypt: true }
  });

  let query = `SELECT config_key, config_value FROM PORTAL.CONFIGURATION WHERE tenant_id = @tenant_id AND enabled = 1`;
  if (section) query += ` AND section = @section`;

  const request = pool.request().input("tenant_id", sql.NVarChar, tenantId);
  if (section) request.input("section", sql.NVarChar, section);

  const result = await request.query(query);
  const config: Record<string, string> = {};
  result.recordset.forEach((row: any) => {
    config[row.config_key] = row.config_value;
  });
  return config;
}
