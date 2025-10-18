
// easyway-portal-api/src/routes/health.ts
import { Router } from "express";
import { healthCheck } from "../controllers/healthController";

const router = Router();

// Rotta di healthcheck base
router.get("/", healthCheck);

export default router;