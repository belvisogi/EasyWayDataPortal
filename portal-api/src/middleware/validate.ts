import { ZodSchema } from "zod";
import { Request, Response, NextFunction } from "express";
import { AppError } from "../utils/errors";

// Body
export function validateBody(schema: ZodSchema<any>) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      return next(new AppError(400, "validation_error", "Validation failed", (result.error as any).errors));
    }
    req.body = result.data;
    next();
  };
}

// Querystring
export function validateQuery(schema: ZodSchema<any>) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.query);
    if (!result.success) {
      return next(new AppError(400, "validation_error", "Invalid query parameters", (result.error as any).errors));
    }
    req.query = result.data;
    next();
  };
}

// Parametri di route (es: /api/users/:user_id)
export function validateParams(schema: ZodSchema<any>) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.params);
    if (!result.success) {
      return next(new AppError(400, "validation_error", "Invalid route parameters", (result.error as any).errors));
    }
    req.params = result.data;
    next();
  };
}
