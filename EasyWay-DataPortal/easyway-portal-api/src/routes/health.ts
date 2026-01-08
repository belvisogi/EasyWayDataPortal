
// easyway-portal-api/src/routes/health.ts
import { Router } from "express";
import { healthCheck } from "../controllers/healthController";
import { validateQuery } from "../middleware/validate";
import { emptyQuerySchema } from "../validators/commonValidator";

const router = Router();

// Rotta di healthcheck base
router.get("/", validateQuery(emptyQuerySchema), healthCheck);

export default router;
