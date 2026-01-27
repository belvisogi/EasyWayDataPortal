// easyway-portal-api/src/controllers/configController.ts
import { Request, Response, NextFunction } from "express";
import { loadDbConfig } from "../config/dbConfigLoader";
import { withTenantContext } from "../utils/db";
import { AppError } from "../utils/errors";

export async function getDbConfig(req: Request, res: Response, next: NextFunction) {
  try {
    const tenantId = (req as any).tenantId;
    const section = req.query.section as string | undefined;

    const config = await withTenantContext(tenantId, async (tx) => {
      return await loadDbConfig(tenantId, section, tx);
    });

    if (Object.keys(config).length === 0) {
      return next(new AppError(404, "not_found", "No configuration found for this tenant/section"));
    }

    res.json(config);
  } catch (err: any) {
    next(err);
  }
}
