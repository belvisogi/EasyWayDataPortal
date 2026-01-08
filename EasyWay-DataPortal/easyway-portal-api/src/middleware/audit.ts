import { Request, Response, NextFunction } from "express";
import { logger } from "../utils/logger";

function getActorId(payload: any): string | null {
  return payload?.oid || payload?.sub || payload?.upn || payload?.preferred_username || null;
}

export function auditAccess(action: string) {
  return (req: Request, res: Response, next: NextFunction) => {
    const start = Date.now();
    res.on("finish", () => {
      const durationMs = Date.now() - start;
      const status = res.statusCode;
      logger.info("api.access", {
        action,
        method: req.method,
        path: req.originalUrl,
        status,
        outcome: status < 400 ? "ok" : "error",
        durationMs,
        tenant_id: (req as any).tenantId || null,
        actor: getActorId((req as any).user),
        request_id: (req as any).requestId || null,
        correlation_id: (req as any).correlationId || null
      });
    });
    next();
  };
}
