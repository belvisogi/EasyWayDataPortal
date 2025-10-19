import sql from "mssql";
import { DefaultAzureCredential } from "@azure/identity";

let poolPromise: Promise<sql.ConnectionPool> | null = null;

function delay(ms: number) { return new Promise(res => setTimeout(res, ms)); }

async function connectWithRetry(config: sql.config, retries = 3, baseDelay = 300): Promise<sql.ConnectionPool> {
  let lastErr: any;
  for (let i = 0; i < retries; i++) {
    try {
      const pool = await new sql.ConnectionPool(config).connect();
      return pool;
    } catch (err) {
      lastErr = err;
      await delay(baseDelay * Math.pow(2, i));
    }
  }
  throw lastErr;
}

export async function getPool(): Promise<sql.ConnectionPool> {
  if (!poolPromise) {
    const connString = process.env.DB_CONN_STRING;
    const useAad = (process.env.DB_AAD || "").toLowerCase() === "true";

    let config: sql.config;
    if (useAad) {
      const credential = new DefaultAzureCredential();
      const token = await credential.getToken("https://database.windows.net/.default");
      config = {
        server: process.env.DB_HOST as string,
        database: process.env.DB_NAME,
        options: { encrypt: true },
        authentication: {
          type: "azure-active-directory-access-token",
          options: { token: token?.token as string }
        }
      } as any;
    } else if (connString) {
      config = { connectionString: connString, options: { encrypt: true }, pool: { max: 5 } } as any;
    } else {
      config = {
        user: process.env.DB_USER,
        password: process.env.DB_PASS,
        server: process.env.DB_HOST as string,
        database: process.env.DB_NAME,
        options: { encrypt: true },
        pool: { max: 5 }
      } as any;
    }

    poolPromise = connectWithRetry(config, 3, 300);
  }
  return poolPromise;
}

export async function withTenantContext<T>(tenantId: string, run: (tx: sql.Transaction) => Promise<T>): Promise<T> {
  const pool = await getPool();
  const tx = new sql.Transaction(pool);
  await tx.begin();
  try {
    const rlsEnabled = (process.env.RLS_CONTEXT_ENABLED ?? 'true').toLowerCase() !== 'false';
    if (rlsEnabled && tenantId) {
      const setReq = new sql.Request(tx);
      await setReq.input('tenant_id', sql.NVarChar, tenantId)
        .query("EXEC sp_set_session_context @key=N'tenant_id', @value=@tenant_id;");
    }
    const result = await run(tx);
    await tx.commit();
    return result;
  } catch (err) {
    try { if (tx._aborted !== true) await tx.rollback(); } catch {}
    throw err;
  }
}

// Convenience helper for future GOLD/REPORTING routes: runs a single-request function
export async function runTenantQuery<T>(tenantId: string, fn: (req: sql.Request) => Promise<T>): Promise<T> {
  return await withTenantContext(tenantId, async (tx) => {
    const req = new sql.Request(tx);
    return await fn(req);
  });
}
