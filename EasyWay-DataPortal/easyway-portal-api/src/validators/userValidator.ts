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

export const userUpdateSchema = z.object({
  email: z.string().email().optional(),
  name: z.string().min(1).max(100).optional(),
  surname: z.string().min(1).max(100).optional(),
  profile_code: z.string().min(1).max(50).optional(),
  // Preferito: is_active (boolean); compat: status("ACTIVE"|"INACTIVE")
  is_active: z.boolean().optional(),
  status: z.string().min(1).max(50).optional(),

  // Compat legacy (deprecato)
  display_name: z.string().min(3).max(100).optional(),
  profile_id: z.string().min(1).optional(),
});

export const userIdParamSchema = z.object({
  user_id: z.string().min(6).max(32),
});

