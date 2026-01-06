import sql from "mssql";
import { loadQueryWithFallback } from "../../queries/queryLoader";
import { withTenantContext } from "../../utils/db";
import { UsersRepo, UserRecord, OnboardingRepo, OnboardingInput } from "../types";

export class SqlUsersRepo implements UsersRepo, OnboardingRepo {
  async list(tenantId: string): Promise<UserRecord[]> {
    const sqlQuery = await loadQueryWithFallback("users_select_by_tenant.sql");
    const result = await withTenantContext(tenantId, async (tx) => {
      return await new sql.Request(tx).input("tenant_id", sql.NVarChar, tenantId).query(sqlQuery);
    });
    return result.recordset as UserRecord[];
  }

  async create(tenantId: string, data: { email: string; display_name?: string | null; profile_id?: string | null }): Promise<UserRecord | any> {
    const sqlQuery = await loadQueryWithFallback("users_insert.sql");
    const result = await withTenantContext(tenantId, async (tx) => {
      return await new sql.Request(tx)
        .input("tenant_id", sql.NVarChar, tenantId)
        .input("email", sql.NVarChar, data.email)
        .input("display_name", sql.NVarChar, data.display_name ?? null)
        .input("profile_id", sql.NVarChar, data.profile_id ?? null)
        .query(sqlQuery);
    });
    return (result.recordset?.[0] ?? { status: "ok" }) as any;
  }

  async update(
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
  ): Promise<UserRecord | any> {
    const sqlQuery = await loadQueryWithFallback("users_update.sql");
    const result = await withTenantContext(tenantId, async (tx) => {
      return await new sql.Request(tx)
        .input("user_id", sql.NVarChar, user_id)
        .input("tenant_id", sql.NVarChar, tenantId)
        .input("name", sql.NVarChar, data.name)
        .input("surname", sql.NVarChar, data.surname)
        .input("profile_code", sql.NVarChar, data.profile_code)
        .input("status", sql.NVarChar, data.status)
        .input("is_tenant_admin", sql.Bit, data.is_tenant_admin)
        .input("updated_by", sql.NVarChar, data.updated_by)
        .query(sqlQuery);
    });
    return result.recordset?.[0] as any;
  }

  async softDelete(tenantId: string, user_id: string): Promise<void> {
    const sqlQuery = await loadQueryWithFallback("users_deactive.sql");
    await withTenantContext(tenantId, async (tx) => {
      await new sql.Request(tx)
        .input("user_id", sql.NVarChar, user_id)
        .input("tenant_id", sql.NVarChar, tenantId)
        .query(sqlQuery);
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
        .query("EXEC PORTAL.sp_debug_register_tenant_and_user @tenant_name, @user_email, @display_name, @profile_id, @ext_attributes");
    });
    return result.recordset;
  }
}
