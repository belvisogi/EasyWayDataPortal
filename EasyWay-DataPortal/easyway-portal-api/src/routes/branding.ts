// easyway-portal-api/src/routes/branding.ts
import { Router } from "express";
import { getBrandingConfig } from "../controllers/brandingController";

const router = Router();

// Endpoint GET /api/branding
router.get("/", getBrandingConfig);

export default router;
