export interface UserRecord {
  user_id: string;
  tenant_id: string;
  email: string;
  display_name?: string | null;
  profile_id?: string | null;
  is_active?: boolean;
  updated_at?: string;
}

export interface UsersRepo {
  list(tenantId: string): Promise<UserRecord[]>;
  create(tenantId: string, data: { email: string; display_name?: string | null; profile_id?: string | null }): Promise<UserRecord | any>;
  update(
    tenantId: string, 
    user_id: string, 
    data: { 
      name: string, 
      surname: string, 
      profile_code: string, 
      status: string, 
      is_tenant_admin: boolean, 
      updated_by: string
    }
  ): Promise<UserRecord | any>;
  softDelete(tenantId: string, user_id: string): Promise<void>;
}

export interface OnboardingInput {
  tenant_name: string;
  user_email: string;
  display_name?: string | null;
  profile_id?: string | null;
  ext_attributes?: any;
}

export interface OnboardingRepo {
  registerTenantAndUser(tenantId: string, input: OnboardingInput): Promise<any>;
}
