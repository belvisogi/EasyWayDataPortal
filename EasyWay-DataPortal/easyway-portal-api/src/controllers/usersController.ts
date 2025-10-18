import { loadQueryWithFallback } from "../queries/queryLoader";
import sql from "mssql";
import { getPool } from "../utils/db";
import { Request, Response } from "express";

// Utility per tenant
function getTenantId(req: Request): string {
  return (req as any).tenantId;
}

// CREATE: POST /api/users
export async function createUser(req: Request, res: Response) {
  try {
    const tenantId = (req as any).tenantId;
    const { email } = req.body;

    // Normalizza ai parametri DB: display_name, profile_id
    const display_name: string | null = req.body.display_name ?? req.body.name ?? null;
    const profile_id: string | null = req.body.profile_id ?? req.body.profile_code ?? null;

    const pool = await getPool();
    const sqlQuery = await loadQueryWithFallback("users_insert.sql");

    const result = await pool
      .request()
      .input("tenant_id", sql.NVarChar, tenantId)
      .input("email", sql.NVarChar, email)
      .input("display_name", sql.NVarChar, display_name)
      .input("profile_id", sql.NVarChar, profile_id)
      .query(sqlQuery);

    res.status(201).json(result.recordset?.[0] ?? { status: "ok" });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
}

// LIST: GET /api/users
export async function getUsers(req: Request, res: Response) {
  try {
    const tenantId = getTenantId(req);
    const pool = await getPool();
    const sqlQuery = await loadQueryWithFallback("users_select_by_tenant.sql");

    const result = await pool.request().input("tenant_id", sql.NVarChar, tenantId).query(sqlQuery);

    res.json(result.recordset);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
}

// UPDATE: PUT /api/users/:user_id
export async function updateUser(req: Request, res: Response) {
  try {
    const tenantId = getTenantId(req);
    const { user_id } = req.params;
    const { email } = req.body;

    // Normalizza ai parametri DB
    const display_name: string | null = req.body.display_name ?? req.body.name ?? null;
    const profile_id: string | null = req.body.profile_id ?? req.body.profile_code ?? null;

    // Supporta sia is_active (boolean) sia status (ACTIVE/INACTIVE)
    let is_active: boolean | null | undefined = req.body.is_active;
    if (is_active === undefined && typeof req.body.status === "string") {
      const s = (req.body.status as string).toLowerCase();
      if (s === "active") is_active = true;
      else if (s === "inactive") is_active = false;
    }
    if (is_active === undefined) is_active = null;

    const pool = await getPool();
    const sqlQuery = await loadQueryWithFallback("users_update.sql");

    const result = await pool
      .request()
      .input("user_id", sql.NVarChar, user_id)
      .input("tenant_id", sql.NVarChar, tenantId)
      .input("email", sql.NVarChar, email ?? null)
      .input("display_name", sql.NVarChar, display_name)
      .input("profile_id", sql.NVarChar, profile_id)
      .input("is_active", sql.Bit, is_active as any)
      .query(sqlQuery);

    res.json(result.recordset[0]);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
}

// DELETE (soft): DELETE /api/users/:user_id
export async function deleteUser(req: Request, res: Response) {
  try {
    const tenantId = getTenantId(req);
    const { user_id } = req.params;

    const pool = await sql.connect(process.env.DB_CONN_STRING!);
    const sqlQuery = await loadQueryWithFallback("users_deactive.sql");

    await pool
      .request()
      .input("user_id", sql.NVarChar, user_id)
      .input("tenant_id", sql.NVarChar, tenantId)
      .query(sqlQuery);

    res.status(204).send();
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
}
