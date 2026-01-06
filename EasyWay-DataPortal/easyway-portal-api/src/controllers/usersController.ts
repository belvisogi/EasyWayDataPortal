import { Request, Response } from "express";
import { getUsersRepo } from "../repositories";

// Utility per tenant
function getTenantId(req: Request): string {
  return (req as any).tenantId;
}

// CREATE: POST /api/users
export async function createUser(req: Request, res: Response) {
  try {
    const tenantId = (req as any).tenantId;
    const { email } = req.body;
    const display_name: string | null = req.body.display_name ?? req.body.name ?? null;
    const profile_id: string | null = req.body.profile_id ?? req.body.profile_code ?? null;
    const repo = getUsersRepo();
    const created = await repo.create(tenantId, { email, display_name, profile_id });
    res.status(201).json(created);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
}

// LIST: GET /api/users
export async function getUsers(req: Request, res: Response) {
  try {
    const tenantId = getTenantId(req);
    const repo = getUsersRepo();
    const users = await repo.list(tenantId);
    res.json(users);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
}

// UPDATE: PUT /api/users/:user_id
export async function updateUser(req: Request, res: Response) {
  try {
    const tenantId = getTenantId(req);
    const { user_id } = req.params;
    const repo = getUsersRepo();

    // SOLO parametri DDL-compliant!
    const userData = {
      name: req.body.name,
      surname: req.body.surname,
      profile_code: req.body.profile_code,
      status: req.body.status,
      is_tenant_admin: req.body.is_tenant_admin,
      updated_by: req.body.updated_by
    };

    const updated = await repo.update(tenantId, user_id, userData);
    res.json(updated);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
}

// DELETE (soft): DELETE /api/users/:user_id
export async function deleteUser(req: Request, res: Response) {
  try {
    const tenantId = getTenantId(req);
    const { user_id } = req.params;
    const repo = getUsersRepo();
    await repo.softDelete(tenantId, user_id);
    res.status(204).send();
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
}
