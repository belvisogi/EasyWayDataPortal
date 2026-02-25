import { AppointmentsRepo, AppointmentRecord } from "../types";
import { readJsonFile, writeJsonFile } from "../../utils/fileStore";
import { randomUUID } from "crypto";

type AppointmentsDb = { appointments: AppointmentRecord[] };

const FILE = "dev-appointments.json";

function load(): AppointmentsDb { return readJsonFile<AppointmentsDb>(FILE, { appointments: [] }); }
function save(db: AppointmentsDb) { writeJsonFile<AppointmentsDb>(FILE, db); }

export class MockAppointmentsRepo implements AppointmentsRepo {
  async list(tenantId: string): Promise<AppointmentRecord[]> {
    const db = load();
    return db.appointments.filter(a => a.tenant_id === tenantId && a.status !== 'CANCELLED');
  }

  async create(tenantId: string, data: {
    customer_name: string;
    customer_email: string;
    scheduled_at: string;
    notes?: string | null;
  }): Promise<AppointmentRecord> {
    const db = load();
    const rec: AppointmentRecord = {
      appointment_id: `APT-${randomUUID()}`,
      tenant_id: tenantId,
      customer_name: data.customer_name,
      customer_email: data.customer_email,
      scheduled_at: data.scheduled_at,
      status: 'PENDING',
      notes: data.notes ?? null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    db.appointments.push(rec);
    save(db);
    return rec;
  }

  async update(tenantId: string, appointment_id: string, data: {
    status?: 'CONFIRMED' | 'PENDING' | 'CANCELLED';
    notes?: string | null;
    scheduled_at?: string;
  }): Promise<AppointmentRecord> {
    const db = load();
    const idx = db.appointments.findIndex(a => a.appointment_id === appointment_id && a.tenant_id === tenantId);
    if (idx < 0) throw new Error("Appointment not found");
    const cur = db.appointments[idx];
    const next: AppointmentRecord = {
      ...cur,
      status: data.status ?? cur.status,
      notes: (data.notes === undefined ? cur.notes : data.notes) ?? null,
      scheduled_at: data.scheduled_at ?? cur.scheduled_at,
      updated_at: new Date().toISOString(),
    };
    db.appointments[idx] = next;
    save(db);
    return next;
  }

  async cancel(tenantId: string, appointment_id: string): Promise<void> {
    const db = load();
    const idx = db.appointments.findIndex(a => a.appointment_id === appointment_id && a.tenant_id === tenantId);
    if (idx < 0) return;
    db.appointments[idx].status = 'CANCELLED';
    db.appointments[idx].updated_at = new Date().toISOString();
    save(db);
  }
}
