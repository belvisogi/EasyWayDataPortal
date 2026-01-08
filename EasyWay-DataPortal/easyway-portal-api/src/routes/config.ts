// easyway-portal-api/src/routes/config.ts
import { Router } from "express";
import { getDbConfig } from "../controllers/configController";
import { validateQuery } from "../middleware/validate";
import { configQuerySchema } from "../validators/configValidator";

const router = Router();

// Endpoint GET /api/config
router.get("/", validateQuery(configQuerySchema), getDbConfig);

export default router;
