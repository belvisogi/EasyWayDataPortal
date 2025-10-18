// easyway-portal-api/src/middleware/tenant.ts
import { Request, Response, NextFunction } from "express";

// Esempio: tenant_id estratto da header X-Tenant-Id
export function extractTenantId(req: Request, res: Response, next: NextFunction) {
  const tenantId = req.header("X-Tenant-Id");
  if (!tenantId || tenantId.length < 3 || tenantId.length > 32) {
    return res.status(400).json({ error: "Invalid or missing X-Tenant-Id header" });
  }
  // Attach tenant_id to req for downstream use
  (req as any).tenantId = tenantId;
  next();
}
