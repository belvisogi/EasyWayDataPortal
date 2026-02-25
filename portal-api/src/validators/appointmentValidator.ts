import { z } from "zod";

export const appointmentCreateSchema = z.object({
  customer_name: z.string().min(2).max(200),
  customer_email: z.string().email(),
  scheduled_at: z.string().datetime({ offset: true }),
  notes: z.string().max(1000).optional(),
});

export const appointmentUpdateSchema = z.object({
  status: z.enum(['CONFIRMED', 'PENDING', 'CANCELLED']).optional(),
  notes: z.string().max(1000).nullable().optional(),
  scheduled_at: z.string().datetime({ offset: true }).optional(),
});

export const appointmentIdParamSchema = z.object({
  appointment_id: z.string().min(6).max(64),
});
