import { Router } from "express";
import { onboarding } from "../controllers/onboardingController";
import { validateBody } from "../middleware/validate";
import { onboardingSchema } from "../validators/onboardingValidator";

const router = Router();

// POST /api/onboarding
router.post(
  "/",
  validateBody(onboardingSchema), // Validazione input (Zod/TypeScript)
  onboarding // Controller conversazionale/agent-aware
);

export default router;
