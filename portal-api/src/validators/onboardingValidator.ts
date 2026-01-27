import { z } from "zod";

export const onboardingSchema = z.object({
  tenant_name: z.string().min(3).max(128),
  user_email: z.string().email(),
  display_name: z.string().min(3).max(100),
  profile_id: z.string().min(1).max(64),
  ext_attributes: z.record(z.string(), z.any()).optional()
});
