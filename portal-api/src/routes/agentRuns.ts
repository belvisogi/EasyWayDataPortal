import { Router } from "express";
import { postAgentRun, getAgentRuns } from "../controllers/agentRunsController";

const router = Router();

// POST /api/agents/:id/run  — trigger a run for the given agent
router.post("/:id/run", postAgentRun);

// GET  /api/agents/:id/runs — list last N runs for the given agent
router.get("/:id/runs", getAgentRuns);

export default router;
