// easyway-portal-api/src/controllers/healthController.ts
import { Request, Response } from "express";

export function healthCheck(req: Request, res: Response) {
  res.json({
    status: "ok",
    tenant: (req as any).tenantId || "undefined",
    service: "EasyWay Data Portal API"
  });
}