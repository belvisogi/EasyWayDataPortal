import { loadQueryWithFallback } from "../queries/queryLoader";
import sql from "mssql";
import { Request, Response } from "express";

// Utility per tenant
function getTenantId(req: Request): string {
  return (req as any).tenantId;
}



export async function createUser(req: Request, res: Response) {
  try {
    const tenantId = (req as any).tenantId;
    const { email } = req.body;

    // Mapping compatibilità legacy: display_name/profile_id → name/surname/profile_code
    const name = req.body.name ?? req.body.display_name ?? null;
    const surname = req.body.surname ?? null;
    const profile_code = req.body.profile_code ?? req.body.profile_id ?? null;

    const pool = await sql.connect(process.env.DB_CONN_STRING!);
    const sqlQuery = await loadQueryWithFallback("users_insert.sql");

    const result = await pool.request()
      .input("tenant_id", sql.NVarChar, tenantId)
      .input("email", sql.NVarChar, email)
      .input("name", sql.NVarChar, name)
      .input("surname", sql.NVarChar, surname)
      .input("profile_code", sql.NVarChar, profile_code)
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
    const pool = await sql.connect(process.env.DB_CONN_STRING!);
    const sqlQuery = await loadQueryWithFallback("users_select_by_tenant.sql");

    const result = await pool.request()
      .input("tenant_id", sql.NVarChar, tenantId)
      .query(sqlQuery);

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
    const { email, status } = req.body;
    // Mapping compat
    const name = req.body.name ?? req.body.display_name ?? null;
    const surname = req.body.surname ?? null;
    const profile_code = req.body.profile_code ?? req.body.profile_id ?? null;

    const pool = await sql.connect(process.env.DB_CONN_STRING!);
    const sqlQuery = await loadQueryWithFallback("users_update.sql");

    const result = await pool.request()
      .input("user_id", sql.NVarChar, user_id)
      .input("tenant_id", sql.NVarChar, tenantId)
      .input("email", sql.NVarChar, email)
      .input("name", sql.NVarChar, name)
      .input("surname", sql.NVarChar, surname)
      .input("profile_code", sql.NVarChar, profile_code)
      .input("status", sql.NVarChar, status ?? null)
      .query(sqlQuery);

    res.json(result.recordset[0]);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
}

// #### Soft delete: endpoint "DELETE /api/users/:user_id"
export async function deleteUser(req: Request, res: Response) {
  try {
    const tenantId = getTenantId(req);
    const { user_id } = req.params;

    const pool = await sql.connect(process.env.DB_CONN_STRING!);
    const sqlQuery = await loadQueryWithFallback("users_deactive.sql");

    await pool.request()
      .input("user_id", sql.NVarChar, user_id)
      .input("tenant_id", sql.NVarChar, tenantId)
      .query(sqlQuery);

    res.status(204).send();
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
}
