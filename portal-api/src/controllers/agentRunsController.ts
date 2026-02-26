import { Request, Response, NextFunction } from "express";
import { runAgent, listRuns, getFirstAction } from "../services/agent-runner.service";
import { AppError } from "../utils/errors";

export async function postAgentRun(req: Request, res: Response, next: NextFunction) {
  try {
    const agentId = req.params.id;
    if (!agentId || !/^agent_[a-z0-9_]+$/.test(agentId)) {
      return next(new AppError(400, "invalid_agent_id", "Invalid agent ID format"));
    }

    // Use action from body or fall back to first action in manifest
    const requestedAction: string | undefined = req.body?.action;
    const action = requestedAction || getFirstAction(agentId);
    if (!action) {
      return next(new AppError(422, "no_action", `No action found for agent '${agentId}'`));
    }

    const run = runAgent(agentId, action, "manual");
    res.status(202).json({ runId: run.runId, agentId, action, status: run.status });
  } catch (err: any) {
    next(err);
  }
}

export async function getAgentRuns(req: Request, res: Response, next: NextFunction) {
  try {
    const agentId = req.params.id;
    const limit = Math.min(parseInt((req.query.limit as string) || "10", 10), 50);
    const runs = listRuns(agentId, limit);
    res.json({ agentId, runs, count: runs.length });
  } catch (err: any) {
    next(err);
  }
}

/** GET /api/runs — recent runs across all agents (flat array for data-list UI) */
export async function getAllRuns(req: Request, res: Response, next: NextFunction) {
  try {
    const limit = Math.min(parseInt((req.query.limit as string) || "20", 10), 100);
    const runs = listRuns(undefined, limit);
    res.json(runs);
  } catch (err: any) {
    next(err);
  }
}
