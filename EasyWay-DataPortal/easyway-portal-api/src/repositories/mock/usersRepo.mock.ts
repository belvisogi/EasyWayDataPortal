import { UsersRepo, UserRecord, OnboardingRepo, OnboardingInput } from "../types";
import { readJsonFile, writeJsonFile } from "../../utils/fileStore";
import { randomUUID } from "crypto";

type UsersDb = { users: UserRecord[] };

const FILE = "dev-users.json";

function load(): UsersDb { return readJsonFile<UsersDb>(FILE, { users: [] }); }
function save(db: UsersDb) { writeJsonFile<UsersDb>(FILE, db); }

export class MockUsersRepo implements UsersRepo, OnboardingRepo {
  async list(tenantId: string): Promise<UserRecord[]> {
    const db = load();
    return db.users.filter(u => u.tenant_id === tenantId && (u.is_active ?? true));
  }

  async create(tenantId: string, data: { email: string; display_name?: string | null; profile_id?: string | null }): Promise<UserRecord> {
    const db = load();
    const rec: UserRecord = {
      user_id: `USR-${randomUUID()}`,
      tenant_id: tenantId,
      email: data.email,
      display_name: data.display_name ?? null,
      profile_id: data.profile_id ?? null,
      is_active: true,
      updated_at: new Date().toISOString(),
    };
    db.users.push(rec);
    save(db);
    return rec;
  }

  async update(tenantId: string, user_id: string, data: { email?: string | null; display_name?: string | null; profile_id?: string | null; is_active?: boolean | null }): Promise<UserRecord> {
    const db = load();
    const idx = db.users.findIndex(u => u.user_id === user_id && u.tenant_id === tenantId);
    if (idx < 0) throw new Error("User not found");
    const cur = db.users[idx];
    const next: UserRecord = {
      ...cur,
      email: data.email ?? cur.email,
      display_name: (data.display_name === undefined ? cur.display_name : data.display_name) ?? null,
      profile_id: (data.profile_id === undefined ? cur.profile_id : data.profile_id) ?? null,
      is_active: (data.is_active === undefined ? cur.is_active : data.is_active) ?? true,
      updated_at: new Date().toISOString(),
    };
    db.users[idx] = next;
    save(db);
    return next;
  }

  async softDelete(tenantId: string, user_id: string): Promise<void> {
    const db = load();
    const idx = db.users.findIndex(u => u.user_id === user_id && u.tenant_id === tenantId);
    if (idx < 0) return;
    db.users[idx].is_active = false;
    db.users[idx].updated_at = new Date().toISOString();
    save(db);
  }

  async registerTenantAndUser(tenantId: string, input: OnboardingInput): Promise<any> {
    // For local dev we just create a user and echo a fake tenant id
    const rec = await this.create(tenantId || "tenant01", {
      email: input.user_email,
      display_name: input.display_name ?? input.tenant_name,
      profile_id: input.profile_id ?? "TENANT_ADMIN",
    });
    return [{ status: "OK", tenant_id: tenantId || "tenant01", user_id: rec.user_id }];
  }
}

