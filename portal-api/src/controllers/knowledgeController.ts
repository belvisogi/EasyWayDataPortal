import { Request, Response, NextFunction } from "express";
import { AppError } from "../utils/errors";
import { logger } from "../utils/logger";

const QDRANT_HOST = () => process.env.QDRANT_HOST || "localhost";
const QDRANT_PORT = () => process.env.QDRANT_PORT || "6333";
const QDRANT_API_KEY = () => process.env.QDRANT_API_KEY || "";
const QDRANT_COLLECTION = process.env.QDRANT_COLLECTION || "easyway_wiki";

interface QdrantPoint {
  id: string | number;
  payload: {
    filename?: string;
    path?: string;
    content?: string;
    chunk_index?: number;
  };
  score?: number;
}

/**
 * Search Qdrant collection using full-text match on `content` field.
 * Requires a text index on the `content` field (PUT /collections/{name}/index).
 * No python3 or ML dependency — pure Node.js fetch to Qdrant REST API.
 */
async function qdrantTextSearch(query: string, limit: number): Promise<QdrantPoint[]> {
  const url = `http://${QDRANT_HOST()}:${QDRANT_PORT()}/collections/${QDRANT_COLLECTION}/points/scroll`;
  const apiKey = QDRANT_API_KEY();

  const body = {
    filter: {
      must: [{ key: "content", match: { text: query } }],
    },
    limit,
    with_payload: true,
    with_vector: false,
  };

  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (apiKey) headers["api-key"] = apiKey;

  const resp = await fetch(url, {
    method: "POST",
    headers,
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(20_000),
  });

  if (!resp.ok) {
    const text = await resp.text();
    throw new Error(`Qdrant error ${resp.status}: ${text.substring(0, 200)}`);
  }

  const data: any = await resp.json();
  return (data?.result?.points ?? []) as QdrantPoint[];
}

export async function searchKnowledge(req: Request, res: Response, next: NextFunction) {
  try {
    const q = ((req.query.q as string) || "").trim();
    const k = Math.min(parseInt((req.query.k as string) || "5", 10), 20);

    if (!q) {
      return next(new AppError(400, "knowledge_query_required", "Query parameter 'q' is required"));
    }
    if (q.length > 500) {
      return next(new AppError(400, "knowledge_query_too_long", "Query parameter 'q' must be ≤ 500 characters"));
    }

    logger.info(`[knowledge] full-text query: "${q.substring(0, 80)}" k=${k}`);

    const points = await qdrantTextSearch(q, k);

    const results = points.map(p => ({
      filename: p.payload.filename ?? "",
      path: p.payload.path ?? "",
      content: (p.payload.content ?? "").substring(0, 800),
      chunk_index: p.payload.chunk_index ?? 0,
      score: p.score ?? null,
    }));

    res.json({ query: q, results, count: results.length });
  } catch (err: any) {
    if (err.name === "TimeoutError" || err.name === "AbortError") {
      return next(new AppError(504, "knowledge_timeout", "Knowledge search timed out"));
    }
    logger.error(`[knowledge] Error: ${err.message}`);
    return next(new AppError(502, "knowledge_error", "Knowledge search failed", err.message));
  }
}
