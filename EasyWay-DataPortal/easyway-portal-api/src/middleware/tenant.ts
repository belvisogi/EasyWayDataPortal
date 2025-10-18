// easyway-portal-api/src/middleware/tenant.ts
import { Request, Response, NextFunction } from "express";

// Estrae tenant dal claim del token (impostato da authenticateJwt)
export function extractTenantId(req: Request, res: Response, next: NextFunction) {
  const tenantId = (req as any).tenantId;
  if (!tenantId || typeof tenantId !== "string" || tenantId.length < 3 || tenantId.length > 64) {
    return res.status(400).json({ error: "Missing or invalid tenant claim" });
  }
  next();
}
