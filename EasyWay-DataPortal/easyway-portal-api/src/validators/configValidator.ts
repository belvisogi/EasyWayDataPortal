import { z } from "zod";

export const configQuerySchema = z.object({
  section: z.string().min(1).max(64).optional()
});
