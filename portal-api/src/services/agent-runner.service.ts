import fs from "fs";
import path from "path";
import { spawn } from "child_process";
import { v4 as uuidv4 } from "uuid";
import { AgentRun } from "../repositories/types";
import { logger } from "../utils/logger";

const MAX_OUTPUT_BYTES = 10_000;
const MAX_RUNS_STORED = 200;

function getRunsFilePath(): string {
  const dataPath = process.env.DATA_PATH || path.join(process.cwd(), "data");
  return path.join(dataPath, "agent-runs.json");
}

function loadRuns(): AgentRun[] {
  const fp = getRunsFilePath();
  try {
    if (!fs.existsSync(fp)) return [];
    return JSON.parse(fs.readFileSync(fp, "utf-8")) as AgentRun[];
  } catch {
    return [];
  }
}

function saveRuns(runs: AgentRun[]): void {
  const fp = getRunsFilePath();
  const trimmed = runs.slice(-MAX_RUNS_STORED);
  try {
    fs.mkdirSync(path.dirname(fp), { recursive: true });
    fs.writeFileSync(fp, JSON.stringify(trimmed, null, 2), "utf-8");
  } catch (err: any) {
    logger.error(`[agent-runner] Failed to save runs: ${err.message}`);
  }
}

function upsertRun(run: AgentRun): void {
  const runs = loadRuns();
  const idx = runs.findIndex(r => r.runId === run.runId);
  if (idx >= 0) {
    runs[idx] = run;
  } else {
    runs.push(run);
  }
  saveRuns(runs);
}

/** Derive runner script path from agent ID */
export function getRunnerPath(agentId: string): string {
  const suffix = agentId
    .replace(/^agent_/, "")
    .split("_")
    .map(p => p.charAt(0).toUpperCase() + p.slice(1))
    .join("");
  const agentsPath = process.env.AGENTS_PATH || path.join(process.cwd(), "agents");
  return path.join(agentsPath, agentId, `Invoke-Agent${suffix}.ps1`);
}

/** Read first action from manifest */
export function getFirstAction(agentId: string): string | null {
  const agentsPath = process.env.AGENTS_PATH || path.join(process.cwd(), "agents");
  const manifestPath = path.join(agentsPath, agentId, "manifest.json");
  try {
    const raw = JSON.parse(fs.readFileSync(manifestPath, "utf-8"));
    const actions: any[] = raw.actions || raw.allowedActions || [];
    if (actions.length === 0) return null;
    // actions can be strings or objects with an 'id' field
    const first = actions[0];
    return typeof first === "string" ? first : (first.id ?? first.name ?? null);
  } catch {
    return null;
  }
}

/** List last N runs for a given agent (or all agents if agentId is undefined) */
export function listRuns(agentId?: string, limit = 10): AgentRun[] {
  const runs = loadRuns();
  const filtered = agentId ? runs.filter(r => r.agentId === agentId) : runs;
  return filtered.slice(-limit).reverse();
}

const isMock = (): boolean => {
  // AGENT_EXECUTION=real bypasses mock mode (used on server when DB_MODE=mock but pwsh is available)
  if (process.env.AGENT_EXECUTION === "real") return false;
  return (
    process.env.DB_MODE === "mock" ||
    process.env.NODE_ENV === "development" ||
    process.platform === "win32"
  );
};

/** Start an agent run (async — does not wait for completion) */
export function runAgent(
  agentId: string,
  action: string,
  triggeredBy: "manual" | "cron" = "manual"
): AgentRun {
  const run: AgentRun = {
    runId: uuidv4(),
    agentId,
    action,
    status: "PENDING",
    startedAt: new Date().toISOString(),
    triggeredBy,
  };
  upsertRun(run);

  if (isMock()) {
    // Mock mode: simulate a short run
    setTimeout(() => {
      const completed: AgentRun = {
        ...run,
        status: "SUCCESS",
        completedAt: new Date().toISOString(),
        durationMs: 420,
        output: `[MOCK] Agent ${agentId} executed action '${action}' successfully.\n{"ok":true,"action":"${action}","agentId":"${agentId}"}`,
        exitCode: 0,
      };
      upsertRun(completed);
      logger.info(`[agent-runner] [MOCK] Run ${run.runId} completed for ${agentId}:${action}`);
    }, 500);
    return run;
  }

  // Production: spawn pwsh
  const runnerPath = getRunnerPath(agentId);
  if (!fs.existsSync(runnerPath)) {
    const failed: AgentRun = {
      ...run,
      status: "FAILED",
      completedAt: new Date().toISOString(),
      durationMs: 0,
      output: `Runner script not found: ${runnerPath}`,
      exitCode: -1,
    };
    upsertRun(failed);
    logger.error(`[agent-runner] Runner not found: ${runnerPath}`);
    return failed;
  }

  // Update to RUNNING
  upsertRun({ ...run, status: "RUNNING" });

  const child = spawn("pwsh", ["-NoProfile", "-File", runnerPath, "-Action", action], {
    env: { ...process.env },
    stdio: ["ignore", "pipe", "pipe"],
  });

  let outputBuf = "";
  child.stdout?.on("data", (chunk: Buffer) => {
    const s = chunk.toString();
    outputBuf += s;
    if (outputBuf.length > MAX_OUTPUT_BYTES) outputBuf = outputBuf.slice(-MAX_OUTPUT_BYTES);
  });
  child.stderr?.on("data", (chunk: Buffer) => {
    const s = chunk.toString();
    outputBuf += s;
    if (outputBuf.length > MAX_OUTPUT_BYTES) outputBuf = outputBuf.slice(-MAX_OUTPUT_BYTES);
  });

  const startMs = Date.now();
  child.on("close", (code) => {
    const completed: AgentRun = {
      ...run,
      status: code === 0 ? "SUCCESS" : "FAILED",
      completedAt: new Date().toISOString(),
      durationMs: Date.now() - startMs,
      output: outputBuf.trim(),
      exitCode: code ?? -1,
    };
    upsertRun(completed);
    logger.info(`[agent-runner] Run ${run.runId} ${completed.status} (exit=${code}) for ${agentId}:${action}`);
  });

  child.on("error", (err) => {
    const failed: AgentRun = {
      ...run,
      status: "FAILED",
      completedAt: new Date().toISOString(),
      durationMs: Date.now() - startMs,
      output: `Spawn error: ${err.message}`,
      exitCode: -1,
    };
    upsertRun(failed);
    logger.error(`[agent-runner] Spawn error for ${agentId}: ${err.message}`);
  });

  return run;
}
