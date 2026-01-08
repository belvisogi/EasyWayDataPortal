// easyway-portal-api/src/routes/branding.ts
import { Router } from "express";
import { getBrandingConfig } from "../controllers/brandingController";
import { validateQuery } from "../middleware/validate";
import { emptyQuerySchema } from "../validators/commonValidator";

const router = Router();

// Endpoint GET /api/branding
router.get("/", validateQuery(emptyQuerySchema), getBrandingConfig);

export default router;
