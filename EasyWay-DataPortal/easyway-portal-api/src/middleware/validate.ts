import { ZodSchema } from "zod";
import { Request, Response, NextFunction } from "express";

// Body
export function validateBody(schema: ZodSchema<any>) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      return res.status(400).json({ error: "Validation failed", details: result.error.errors });
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
      return res.status(400).json({ error: "Invalid query parameters", details: result.error.errors });
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
      return res.status(400).json({ error: "Invalid route parameters", details: result.error.errors });
    }
    req.params = result.data;
    next();
  };
}
