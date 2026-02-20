import { z } from "zod";

// Allineato al DDL standard PORTAL.USERS
// Compat legacy: name/surname/profile_code vengono mappati a display_name/profile_id

export const userCreateSchema = z.object({
  email: z.string().email(),
  display_name: z.string().min(3).max(100).optional(),
  profile_id: z.string().min(1).optional(),

  // Compat legacy (deprecato): se usati, verranno mappati
  name: z.string().min(1).max(100).optional()
    .describe('[DEPRECATED v2.0.0] Use display_name instead'),
  surname: z.string().min(1).max(100).optional()
    .describe('[DEPRECATED v2.0.0] Will be concatenated to display_name'),
  profile_code: z.string().min(1).max(50).optional()
    .describe('[DEPRECATED v2.0.0] Use profile_id instead'),
});

// Solo parametri DDL-compliant, nessun legacy, nessun alias
export const userUpdateSchema = z.object({
  email: z.string().email().optional(),
  display_name: z.string().min(3).max(100).optional(),
  profile_id: z.string().min(1).optional(),
  // Compat legacy (deprecato): mantenuto per backward-compat su update
  name: z.string().min(1).max(100).optional()
    .describe('[DEPRECATED v2.0.0] Use display_name instead'),
  surname: z.string().min(1).max(100).optional()
    .describe('[DEPRECATED v2.0.0] Will be concatenated to display_name'),
  profile_code: z.string().min(1).max(50).optional()
    .describe('[DEPRECATED v2.0.0] Use profile_id instead'),
  is_active: z.boolean().optional(),
  updated_by: z.string().min(1).max(100).optional()
});

export const userIdParamSchema = z.object({
  user_id: z.string().min(6).max(64),
});
