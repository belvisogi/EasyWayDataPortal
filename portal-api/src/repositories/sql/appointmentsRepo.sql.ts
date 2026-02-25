import sql from "mssql";
import { withTenantContext } from "../../utils/db";
import { AppointmentsRepo, AppointmentRecord } from "../types";

export class SqlAppointmentsRepo implements AppointmentsRepo {
  async list(tenantId: string): Promise<AppointmentRecord[]> {
    const result = await withTenantContext(tenantId, async (tx) => {
      return await new sql.Request(tx)
        .input("tenant_id", sql.NVarChar, tenantId)
        .execute("PORTAL.sp_list_appointments_by_tenant");
    });
    return result.recordset as AppointmentRecord[];
  }

  async create(tenantId: string, data: {
    customer_name: string;
    customer_email: string;
    scheduled_at: string;
    notes?: string | null;
  }): Promise<AppointmentRecord> {
    const result = await withTenantContext(tenantId, async (tx) => {
      return await new sql.Request(tx)
        .input("tenant_id", sql.NVarChar, tenantId)
        .input("customer_name", sql.NVarChar, data.customer_name)
        .input("customer_email", sql.NVarChar, data.customer_email)
        .input("scheduled_at", sql.NVarChar, data.scheduled_at)
        .input("notes", sql.NVarChar, data.notes ?? null)
        .input("created_by", sql.NVarChar, "api")
        .execute("PORTAL.sp_insert_appointment");
    });
    const row = result.recordset[0];
    if (row && row.status !== "OK") {
      throw new Error(row.error_message || "Failed to create appointment");
    }
    return { ...data, appointment_id: row.appointment_id, tenant_id: tenantId, status: "PENDING", ...row };
  }

  async update(tenantId: string, appointment_id: string, data: {
    status?: 'CONFIRMED' | 'PENDING' | 'CANCELLED';
    notes?: string | null;
    scheduled_at?: string;
  }): Promise<AppointmentRecord> {
    const result = await withTenantContext(tenantId, async (tx) => {
      return await new sql.Request(tx)
        .input("tenant_id", sql.NVarChar, tenantId)
        .input("appointment_id", sql.NVarChar, appointment_id)
        .input("status", sql.NVarChar, data.status ?? null)
        .input("notes", sql.NVarChar, data.notes ?? null)
        .input("scheduled_at", sql.NVarChar, data.scheduled_at ?? null)
        .input("updated_by", sql.NVarChar, "api")
        .execute("PORTAL.sp_update_appointment");
    });
    const row = result.recordset[0];
    if (row && row.status !== "OK") {
      throw new Error(row.error_message || "Failed to update appointment");
    }
    return { appointment_id, tenant_id: tenantId, ...data, ...row } as AppointmentRecord;
  }

  async cancel(tenantId: string, appointment_id: string): Promise<void> {
    await withTenantContext(tenantId, async (tx) => {
      await new sql.Request(tx)
        .input("tenant_id", sql.NVarChar, tenantId)
        .input("appointment_id", sql.NVarChar, appointment_id)
        .input("cancelled_by", sql.NVarChar, "api")
        .execute("PORTAL.sp_cancel_appointment");
    });
  }
}
