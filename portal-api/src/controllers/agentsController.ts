import { Request, Response, NextFunction } from "express";
import { getAgentsRepo } from "../repositories";

// GET /api/agents
export async function getAgents(req: Request, res: Response, next: NextFunction) {
  try {
    const repo = getAgentsRepo();
    const agents = await repo.list();
    res.json(agents);
  } catch (err: any) {
    next(err);
  }
}
