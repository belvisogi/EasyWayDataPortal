import { z } from "zod";

export const sendNotificationSchema = z.object({
  recipients: z.array(z.string().min(6).max(64)), // array di user_id
  category: z.string().min(3).max(32),   // es: "ALERT"
  channel: z.string().min(3).max(16),    // es: "EMAIL", "SMS"
  message: z.string().min(1).max(1024),
  ext_attributes: z.record(z.any()).optional()
});
