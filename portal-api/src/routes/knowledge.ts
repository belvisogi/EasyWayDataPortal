import { Router } from "express";
import { searchKnowledge } from "../controllers/knowledgeController";

const router = Router();

// GET /api/knowledge?q=<query>&k=<top-k>
router.get("/", searchKnowledge);

export default router;
