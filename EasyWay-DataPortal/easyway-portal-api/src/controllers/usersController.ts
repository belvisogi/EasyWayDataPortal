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
    const { email } = req.body;
    const display_name: string | null = req.body.display_name ?? req.body.name ?? null;
    const profile_id: string | null = req.body.profile_id ?? req.body.profile_code ?? null;
    let is_active: boolean | null | undefined = req.body.is_active;
    if (is_active === undefined && typeof req.body.status === "string") {
      const s = (req.body.status as string).toLowerCase();
      if (s === "active") is_active = true;
      else if (s === "inactive") is_active = false;
    }
    if (is_active === undefined) is_active = null;

    const repo = getUsersRepo();
    const updated = await repo.update(tenantId, user_id, { email, display_name, profile_id, is_active });
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
