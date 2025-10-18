// easyway-portal-api/src/controllers/brandingController.ts
import { Request, Response } from "express";
import { loadBrandingConfig } from "../config/brandingLoader";

export async function getBrandingConfig(req: Request, res: Response) {
  try {
    const tenantId = (req as any).tenantId;
    const config = await loadBrandingConfig(tenantId);
    res.json(config);
  } catch (err: any) {
    res.status(404).json({ error: err.message || "Branding config not found" });
  }
}
