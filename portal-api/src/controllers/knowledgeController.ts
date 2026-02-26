import { Request, Response, NextFunction } from "express";
import { execFile } from "child_process";
import { promisify } from "util";
import path from "path";
import { AppError } from "../utils/errors";
import { logger } from "../utils/logger";

const execFileAsync = promisify(execFile);

export async function searchKnowledge(req: Request, res: Response, next: NextFunction) {
  try {
    const q = (req.query.q as string | undefined) || "";
    const k = Math.min(parseInt((req.query.k as string) || "5", 10), 20);

    if (!q || q.trim().length === 0) {
      return next(new AppError(400, "knowledge_query_required", "Query parameter 'q' is required"));
    }
    if (q.length > 500) {
      return next(new AppError(400, "knowledge_query_too_long", "Query parameter 'q' must be ≤ 500 characters"));
    }

    const agentsPath = process.env.AGENTS_PATH || path.join(process.cwd(), "agents");
    const scriptPath = path.join(agentsPath, "skills", "retrieval", "rag_search.py");

    logger.info(`[knowledge] RAG query: "${q.substring(0, 80)}" k=${k}`);

    const { stdout, stderr } = await execFileAsync(
      "python3",
      [scriptPath, q.trim(), String(k)],
      {
        env: {
          ...process.env,
          QDRANT_HOST: process.env.QDRANT_HOST || "localhost",
          QDRANT_PORT: process.env.QDRANT_PORT || "6333",
          QDRANT_API_KEY: process.env.QDRANT_API_KEY || "",
        },
        timeout: 30_000,
        cwd: path.dirname(agentsPath),
      }
    );

    if (stderr && stderr.trim()) {
      logger.warn(`[knowledge] rag_search stderr: ${stderr.trim().substring(0, 200)}`);
    }

    let parsed: any;
    try {
      parsed = JSON.parse(stdout);
    } catch {
      logger.error(`[knowledge] Failed to parse rag_search output: ${stdout.substring(0, 200)}`);
      return next(new AppError(502, "knowledge_parse_error", "RAG search returned invalid JSON"));
    }

    const results = Array.isArray(parsed) ? parsed : (parsed.results || []);
    res.json({ query: q.trim(), results, count: results.length });
  } catch (err: any) {
    if (err.code === "ETIMEDOUT" || err.killed) {
      return next(new AppError(504, "knowledge_timeout", "RAG search timed out"));
    }
    logger.error(`[knowledge] Error: ${err.message}`);
    return next(new AppError(502, "knowledge_error", "RAG search failed", err.message));
  }
}
