import { Request, Response, NextFunction } from "express";
import { getUsersRepo } from "../repositories";
import { logger } from "../utils/logger";

// Utility per tenant
function getTenantId(req: Request): string {
  return (req as any).tenantId;
}

// CREATE: POST /api/users
export async function createUser(req: Request, res: Response, next: NextFunction) {
  try {
    const tenantId = (req as any).tenantId;
    const { email } = req.body;


    // Mapping da legacy per compatibilità, ma senza warning (ormai standardizzato)


    const display_name: string | null = req.body.display_name ?? req.body.name ?? null;
    const profile_id: string | null = req.body.profile_id ?? req.body.profile_code ?? null;
    const repo = getUsersRepo();
    const created = await repo.create(tenantId, { email, display_name, profile_id });
    res.status(201).json(created);
  } catch (err: any) {
    next(err);
  }
}

// LIST: GET /api/users
export async function getUsers(req: Request, res: Response, next: NextFunction) {
  try {
    const tenantId = getTenantId(req);
    const repo = getUsersRepo();
    const users = await repo.list(tenantId);
    res.json(users);
  } catch (err: any) {
    next(err);
  }
}

// UPDATE: PUT /api/users/:user_id
export async function updateUser(req: Request, res: Response, next: NextFunction) {
  try {
    const tenantId = getTenantId(req);
    const { user_id } = req.params;
    const repo = getUsersRepo();


    // Mapping legacy silenzioso


    // SOLO parametri DDL-compliant (display_name/profile_id/is_active/email)
    const legacyName = [req.body.name, req.body.surname].filter(Boolean).join(" ");
    const displayName = req.body.display_name ?? (legacyName || null);
    const profileId = req.body.profile_id ?? req.body.profile_code ?? null;
    const userData = {
      email: req.body.email ?? null,
      display_name: displayName,
      profile_id: profileId,
      is_active: req.body.is_active ?? null,
      updated_by: req.body.updated_by ?? null
    };

    const updated = await repo.update(tenantId, user_id, userData);
    res.json(updated);
  } catch (err: any) {
    next(err);
  }
}

// DELETE (soft): DELETE /api/users/:user_id
export async function deleteUser(req: Request, res: Response, next: NextFunction) {
  try {
    const tenantId = getTenantId(req);
    const { user_id } = req.params;
    const repo = getUsersRepo();
    await repo.softDelete(tenantId, user_id);
    res.status(204).send();
  } catch (err: any) {
    next(err);
  }
}
