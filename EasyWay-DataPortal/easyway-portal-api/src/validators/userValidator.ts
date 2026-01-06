import { z } from "zod";

// Allineato al DDL standard PORTAL.USERS
// Manteniamo compatibilità: display_name/profile_id deprecati, mappati se presenti

export const userCreateSchema = z.object({
  email: z.string().email(),
  // Nuovo modello
  name: z.string().min(1).max(100).optional(),
  surname: z.string().min(1).max(100).optional(),
  profile_code: z.string().min(1).max(50).optional(),

  // Compat legacy (deprecato): se usati, verranno mappati
  display_name: z.string().min(3).max(100).optional(),
  profile_id: z.string().min(1).optional(),
});

// Solo parametri DDL-compliant, nessun legacy, nessun alias
export const userUpdateSchema = z.object({
  name: z.string().min(1).max(100),
  surname: z.string().min(1).max(100),
  profile_code: z.string().min(1).max(50),
  status: z.string().min(1).max(50),
  is_tenant_admin: z.boolean(),
  updated_by: z.string().min(1).max(100)
});

export const userIdParamSchema = z.object({
  user_id: z.string().min(6).max(32),
});
