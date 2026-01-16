import sql from "mssql";

import { withTenantContext } from "../../utils/db";
import { UsersRepo, UserRecord, OnboardingRepo, OnboardingInput } from "../types";

export class SqlUsersRepo implements UsersRepo, OnboardingRepo {
  async list(tenantId: string): Promise<UserRecord[]> {
    const result = await withTenantContext(tenantId, async (tx) => {
      return await new sql.Request(tx)
        .input("tenant_id", sql.NVarChar, tenantId)
        .input("include_inactive", sql.Bit, 0)
        .execute("PORTAL.sp_list_users_by_tenant");
    });
    return result.recordset as UserRecord[];
  }

  async create(tenantId: string, data: { email: string; display_name?: string | null; profile_id?: string | null }): Promise<UserRecord | any> {
    const result = await withTenantContext(tenantId, async (tx) => {
      return await new sql.Request(tx)
        .input("tenant_id", sql.NVarChar, tenantId)
        .input("email", sql.NVarChar, data.email)
        .input("display_name", sql.NVarChar, data.display_name ?? null)
        .input("profile_id", sql.NVarChar, data.profile_id ?? null)
        .input("created_by", sql.NVarChar, "api")
        .execute("PORTAL.sp_insert_user");
    });
    // SP returns { status, user_id, error_message, rows_inserted }
    const row = result.recordset[0];
    if (row && row.status !== 'OK') {
      throw new Error(row.error_message || "Failed to create user");
    }
    // Return format expected: usually the full record, but repo.create just returns whatever for now?
    // Controller expects .json(created). Integration tests expect body.display_name.
    // The SP returns only status/id. This might be a BREAKING CHANGE for the controller which might expect "created object" to echo back.
    // Let's check line 28 of usersController: res.status(201).json(created);
    // If we only return {status, user_id}, the frontend/test might fail expecting 'display_name'.
    // Fix: Merge input data with result or refetch. 
    // Optimization: Just return {...data, ...row, id: row.user_id}
    return { ...data, user_id: row.user_id, status: "ACTIVE", ...row };
  }

  async update(
    tenantId: string,
    user_id: string,
    data: {
      email?: string | null,
      display_name?: string | null,
      profile_id?: string | null,
      is_active?: boolean | null,
      updated_by?: string | null
    }
  ): Promise<UserRecord | any> {
    const result = await withTenantContext(tenantId, async (tx) => {
      return await new sql.Request(tx)
        .input("tenant_id", sql.NVarChar, tenantId)
        .input("user_id", sql.NVarChar, user_id)
        .input("email", sql.NVarChar, data.email ?? null)
        .input("display_name", sql.NVarChar, data.display_name ?? null)
        .input("profile_id", sql.NVarChar, data.profile_id ?? null)
        .input("is_active", sql.Bit, data.is_active ?? null)
        .input("updated_by", sql.NVarChar, data.updated_by ?? "api")
        .execute("PORTAL.sp_update_user");
    });
    const row = result.recordset[0];
    if (row && row.status !== 'OK') {
      throw new Error(row.error_message || "Failed to update user");
    }
    // Similar return issue. Merge data.
    return { user_id, ...data, ...row };
  }

  async softDelete(tenantId: string, user_id: string): Promise<void> {
    await withTenantContext(tenantId, async (tx) => {
      await new sql.Request(tx)
        .input("user_id", sql.NVarChar, user_id)
        .input("tenant_id", sql.NVarChar, tenantId)
        .input("deleted_by", sql.NVarChar, "api")
        .execute("PORTAL.sp_delete_user");
    });
  }

  async registerTenantAndUser(tenantId: string, input: OnboardingInput): Promise<any> {
    const result = await withTenantContext(tenantId ?? "", async (tx) => {
      return await new sql.Request(tx)
        .input("tenant_name", sql.NVarChar, input.tenant_name)
        .input("user_email", sql.NVarChar, input.user_email)
        .input("display_name", sql.NVarChar, input.display_name ?? null)
        .input("profile_id", sql.NVarChar, input.profile_id ?? null)
        .input("ext_attributes", sql.NVarChar, JSON.stringify(input.ext_attributes ?? {}))
        .execute("PORTAL.sp_register_tenant_and_user");
    });
    return result.recordset;
  }
}
