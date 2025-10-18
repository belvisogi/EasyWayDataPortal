// easyway-portal-api/src/routes/config.ts
import { Router } from "express";
import { getDbConfig } from "../controllers/configController";

const router = Router();

// Endpoint GET /api/config
router.get("/", getDbConfig);

export default router;
