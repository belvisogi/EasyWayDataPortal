import { z } from "zod";

export const dbDiagramQuerySchema = z.object({
  schema: z.string().optional().transform((v) => (v ?? "PORTAL").toUpperCase()).refine(
    (v) => v === "PORTAL",
    { message: "Unsupported schema (only PORTAL)" }
  )
});
