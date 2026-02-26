import { runAgent, listRuns } from "../../services/agent-runner.service";
import { createAdoIssue } from "../ado-issue";
import { logger } from "../../utils/logger";

const AGENT_ID = "agent_backend";
const ACTION = "api:openapi-validate";
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

export async function runOpenApiValidate(): Promise<void> {
  logger.info("[cron:openapi-validate] Starting OpenAPI validation");
  const run = runAgent(AGENT_ID, ACTION, "cron");
  const completed = await waitForCompletion(run.runId);

  if (!completed) {
    logger.warn("[cron:openapi-validate] Run timed out");
    return;
  }

  if (completed.status === "FAILED") {
    logger.warn("[cron:openapi-validate] Run FAILED — opening ADO issue");
    await createAdoIssue(
      `[AUTO] OpenAPI validation FAILED — ${new Date().toISOString().slice(0, 10)}`,
      `Agent: ${AGENT_ID}\nAction: ${ACTION}\nRunId: ${completed.runId}\n\n${completed.output ?? "no output"}`
    );
    return;
  }

  // Parse violations count from output
  try {
    const parsed = JSON.parse((completed.output ?? "{}").split("\n").filter(l => l.startsWith("{")).join(""));
    const violations: number = parsed.violations ?? parsed.violationsCount ?? 0;
    if (violations > 0) {
      logger.warn(`[cron:openapi-validate] ${violations} violations — opening ADO issue`);
      await createAdoIssue(
        `[AUTO] OpenAPI ${violations} violations — ${new Date().toISOString().slice(0, 10)}`,
        `Agent: ${AGENT_ID}\nViolations: ${violations}\nRunId: ${completed.runId}\n\n${completed.output ?? ""}`
      );
    } else {
      logger.info("[cron:openapi-validate] No violations — OK");
    }
  } catch {
    logger.info("[cron:openapi-validate] Run SUCCESS (non-JSON output) — no issue");
  }
}
