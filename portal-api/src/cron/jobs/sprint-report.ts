import { runAgent, listRuns } from "../../services/agent-runner.service";
import { logger } from "../../utils/logger";

const AGENT_ID = "agent_scrummaster";
const ACTION = "sprint:report";
const POLL_INTERVAL_MS = 500;
const MAX_WAIT_MS = 180_000;

async function waitForCompletion(runId: string): Promise<import("../../repositories/types").AgentRun | null> {
  const deadline = Date.now() + MAX_WAIT_MS;
  while (Date.now() < deadline) {
    await new Promise(r => setTimeout(r, POLL_INTERVAL_MS));
    const runs = listRuns(AGENT_ID, 20);
    const run = runs.find(r => r.runId === runId);
    if (run && (run.status === "SUCCESS" || run.status === "FAILED")) return run;
  }
  return null;
}

export async function runSprintReport(): Promise<void> {
  logger.info("[cron:sprint-report] Generating weekly sprint report");
  const run = runAgent(AGENT_ID, ACTION, "cron");
  const completed = await waitForCompletion(run.runId);

  if (!completed) {
    logger.warn("[cron:sprint-report] Run timed out");
    return;
  }

  if (completed.status === "FAILED") {
    logger.warn(`[cron:sprint-report] Run FAILED (runId=${completed.runId}) — check run history`);
    return;
  }

  logger.info(`[cron:sprint-report] Sprint report generated successfully (runId=${completed.runId})`);
}
