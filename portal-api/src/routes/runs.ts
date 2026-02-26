import { Router } from "express";
import { getAllRuns } from "../controllers/agentRunsController";

const router = Router();

// GET /api/runs — list recent runs across all agents (flat array for UI)
router.get("/", getAllRuns);

export default router;
