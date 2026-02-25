import { Router } from "express";
import { getQuotes, createQuote, updateQuote } from "../controllers/quotesController";
import { validateBody, validateParams } from "../middleware/validate";
import { quoteCreateSchema, quoteUpdateSchema, quoteIdParamSchema } from "../validators/quoteValidator";

const router = Router();

// GET /api/quotes
router.get("/", getQuotes);

// POST /api/quotes
router.post("/", validateBody(quoteCreateSchema), createQuote);

// PATCH /api/quotes/:quote_id
router.patch("/:quote_id", validateParams(quoteIdParamSchema), validateBody(quoteUpdateSchema), updateQuote);

export default router;
