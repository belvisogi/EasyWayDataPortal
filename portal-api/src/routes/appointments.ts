import { Router } from "express";
import { getAppointments, createAppointment, updateAppointment, cancelAppointment } from "../controllers/appointmentsController";
import { validateBody, validateParams } from "../middleware/validate";
import { appointmentCreateSchema, appointmentUpdateSchema, appointmentIdParamSchema } from "../validators/appointmentValidator";

const router = Router();

// GET /api/appointments
router.get("/", getAppointments);

// POST /api/appointments
router.post("/", validateBody(appointmentCreateSchema), createAppointment);

// PATCH /api/appointments/:appointment_id
router.patch("/:appointment_id", validateParams(appointmentIdParamSchema), validateBody(appointmentUpdateSchema), updateAppointment);

// DELETE /api/appointments/:appointment_id
router.delete("/:appointment_id", validateParams(appointmentIdParamSchema), cancelAppointment);

export default router;
