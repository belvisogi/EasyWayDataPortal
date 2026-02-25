import { z } from "zod";

export const quoteCreateSchema = z.object({
  customer_name: z.string().min(2).max(200),
  customer_email: z.string().email(),
  total_amount: z.number().positive(),
  valid_until: z.string().date().nullable().optional(),
});

export const quoteUpdateSchema = z.object({
  status: z.enum(['DRAFT', 'SENT', 'ACCEPTED', 'REJECTED']).optional(),
  total_amount: z.number().positive().optional(),
  valid_until: z.string().date().nullable().optional(),
});

export const quoteIdParamSchema = z.object({
  quote_id: z.string().min(6).max(64),
});
