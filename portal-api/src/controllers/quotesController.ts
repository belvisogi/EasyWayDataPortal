import { Request, Response, NextFunction } from "express";
import { getQuotesRepo } from "../repositories";
import { logger } from "../utils/logger";

function getTenantId(req: Request): string {
  return (req as any).tenantId;
}

// GET /api/quotes
export async function getQuotes(req: Request, res: Response, next: NextFunction) {
  try {
    const tenantId = getTenantId(req);
    const repo = getQuotesRepo();
    const quotes = await repo.list(tenantId);
    res.json(quotes);
  } catch (err: any) {
    next(err);
  }
}

// POST /api/quotes
export async function createQuote(req: Request, res: Response, next: NextFunction) {
  try {
    const tenantId = getTenantId(req);
    const { customer_name, customer_email, total_amount, valid_until } = req.body;
    const repo = getQuotesRepo();
    const created = await repo.create(tenantId, { customer_name, customer_email, total_amount, valid_until: valid_until ?? null });
    res.status(201).json(created);
  } catch (err: any) {
    next(err);
  }
}

// PATCH /api/quotes/:quote_id
export async function updateQuote(req: Request, res: Response, next: NextFunction) {
  try {
    const tenantId = getTenantId(req);
    const { quote_id } = req.params;
    const repo = getQuotesRepo();
    const updated = await repo.update(tenantId, quote_id, {
      status: req.body.status,
      total_amount: req.body.total_amount,
      valid_until: req.body.valid_until,
    });
    res.json(updated);
  } catch (err: any) {
    next(err);
  }
}
