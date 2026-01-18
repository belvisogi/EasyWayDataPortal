// easyway-portal-api/src/controllers/brandingController.ts
import { Request, Response, NextFunction } from "express";
import { loadBrandingConfig } from "../config/brandingLoader";
import { AppError } from "../utils/errors";

export async function getBrandingConfig(req: Request, res: Response, next: NextFunction) {
  try {
    const tenantId = (req as any).tenantId;
    const config = await loadBrandingConfig(tenantId);
    res.json(config);
  } catch (err: any) {
    next(new AppError(404, "not_found", err?.message || "Branding config not found"));
  }
}
