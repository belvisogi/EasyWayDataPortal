import { Request, Response, NextFunction } from "express";
import { AppError, toAppError } from "../utils/errors";
import { logger } from "../utils/logger";

function buildErrorPayload(req: Request, err: AppError) {
  return {
    error: {
      code: err.code,
      message: err.message,
      details: err.details ?? undefined
    },
    requestId: (req as any).requestId || null,
    correlationId: (req as any).correlationId || null
  };
}

export function notFoundHandler(req: Request, res: Response) {
  const err = new AppError(404, "not_found", "Route not found");
  res.status(err.status).json(buildErrorPayload(req, err));
}

export function errorHandler(err: unknown, req: Request, res: Response, _next: NextFunction) {
  let appErr = toAppError(err);
  if (appErr.message === "CORS not allowed") {
    appErr = new AppError(403, "cors_denied", "CORS not allowed");
  }

  const status = appErr.status || 500;
  const isServerError = status >= 500;
  if (isServerError) {
    logger.error("api.error", {
      message: appErr.message,
      code: appErr.code,
      status,
      path: req.originalUrl,
      requestId: (req as any).requestId || null,
      correlationId: (req as any).correlationId || null
    });
  }

  const payload = buildErrorPayload(req, isServerError
    ? new AppError(status, appErr.code || "internal_error", "Internal server error")
    : appErr
  );
  res.status(status).json(payload);
}
