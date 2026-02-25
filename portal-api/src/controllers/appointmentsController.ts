import { Request, Response, NextFunction } from "express";
import { getAppointmentsRepo } from "../repositories";
import { logger } from "../utils/logger";

function getTenantId(req: Request): string {
  return (req as any).tenantId;
}

// GET /api/appointments
export async function getAppointments(req: Request, res: Response, next: NextFunction) {
  try {
    const tenantId = getTenantId(req);
    const repo = getAppointmentsRepo();
    const appointments = await repo.list(tenantId);
    res.json(appointments);
  } catch (err: any) {
    next(err);
  }
}

// POST /api/appointments
export async function createAppointment(req: Request, res: Response, next: NextFunction) {
  try {
    const tenantId = getTenantId(req);
    const { customer_name, customer_email, scheduled_at, notes } = req.body;
    const repo = getAppointmentsRepo();
    const created = await repo.create(tenantId, { customer_name, customer_email, scheduled_at, notes: notes ?? null });
    res.status(201).json(created);
  } catch (err: any) {
    next(err);
  }
}

// PATCH /api/appointments/:appointment_id
export async function updateAppointment(req: Request, res: Response, next: NextFunction) {
  try {
    const tenantId = getTenantId(req);
    const { appointment_id } = req.params;
    const repo = getAppointmentsRepo();
    const updated = await repo.update(tenantId, appointment_id, {
      status: req.body.status,
      notes: req.body.notes,
      scheduled_at: req.body.scheduled_at,
    });
    res.json(updated);
  } catch (err: any) {
    next(err);
  }
}

// DELETE /api/appointments/:appointment_id
export async function cancelAppointment(req: Request, res: Response, next: NextFunction) {
  try {
    const tenantId = getTenantId(req);
    const { appointment_id } = req.params;
    const repo = getAppointmentsRepo();
    await repo.cancel(tenantId, appointment_id);
    res.status(204).send();
  } catch (err: any) {
    next(err);
  }
}
