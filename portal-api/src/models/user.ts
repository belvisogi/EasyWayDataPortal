// easyway-portal-api/src/models/user.ts

export interface User {
  user_id: string;        // NDG, es: CDI0000010001
  tenant_id: string;
  email: string;
  display_name: string;
  is_active: boolean;
  profile_id: string;
  created_at: Date;
  updated_at: Date;
}