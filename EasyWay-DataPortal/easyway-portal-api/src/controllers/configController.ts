// easyway-portal-api/src/controllers/configController.ts
import { Request, Response } from "express";
import { loadDbConfig } from "../config/dbConfigLoader";
import { withTenantContext } from "../utils/db";

export async function getDbConfig(req: Request, res: Response) {
  try {
    const tenantId = (req as any).tenantId;
    const section = req.query.section as string | undefined;

    const config = await withTenantContext(tenantId, async (tx) => {
      return await loadDbConfig(tenantId, section, tx);
    });

    if (Object.keys(config).length === 0) {
      return res.status(404).json({ error: "No configuration found for this tenant/section" });
    }

    res.json(config);
  } catch (err: any) {
    res.status(500).json({ error: err.message || "Internal server error" });
  }
}
