import { runAgent, getFirstAction, listRuns } from "../../services/agent-runner.service";
import { createAdoIssue } from "../ado-issue";
import { logger } from "../../utils/logger";

const AGENT_ID = "agent_infra";
const ACTION = "infra:drift-check";
const POLL_INTERVAL_MS = 500;
const MAX_WAIT_MS = 120_000;

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

export async function runInfraDriftCheck(): Promise<void> {
  logger.info("[cron:infra-drift] Starting infra drift check");
  const action = ACTION || getFirstAction(AGENT_ID) || "infra:drift-check";
  const run = runAgent(AGENT_ID, action, "cron");
  const completed = await waitForCompletion(run.runId);

  if (!completed) {
    logger.warn("[cron:infra-drift] Run timed out — skipping ADO issue");
    return;
  }

  if (completed.status === "FAILED") {
    logger.warn("[cron:infra-drift] Run FAILED — opening ADO issue");
    await createAdoIssue(
      `[AUTO] Infra drift detected — ${new Date().toISOString().slice(0, 10)}`,
      `Agent: ${AGENT_ID}\nAction: ${action}\nRunId: ${completed.runId}\n\n${completed.output ?? "no output"}`
    );
    return;
  }

  // Parse output JSON to check for severity
  try {
    const parsed = JSON.parse((completed.output ?? "{}").split("\n").filter(l => l.startsWith("{")).join(""));
    const severity: string = parsed.severity || parsed.level || "";
    if (severity.toUpperCase() === "HIGH" || parsed.ok === false) {
      logger.warn(`[cron:infra-drift] Severity HIGH — opening ADO issue`);
      await createAdoIssue(
        `[AUTO] Infra drift HIGH severity — ${new Date().toISOString().slice(0, 10)}`,
        `Agent: ${AGENT_ID}\nSeverity: ${severity}\nRunId: ${completed.runId}\n\n${completed.output ?? ""}`
      );
    } else {
      logger.info("[cron:infra-drift] No drift detected — all OK");
    }
  } catch {
    // Output is not JSON: log but don't open issue
    logger.info(`[cron:infra-drift] Run SUCCESS (non-JSON output) — no issue`);
  }
}
