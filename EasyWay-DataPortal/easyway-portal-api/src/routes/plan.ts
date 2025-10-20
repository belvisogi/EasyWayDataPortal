import express from 'express';
import { spawnSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import os from 'os';

const router = express.Router();

/**
 * Helper: run orchestrator with provided flags and return parsed JSON (or throw)
 */
function runOrchestrator(flags: Record<string, string | boolean>): any {
  // build args
  const args: string[] = [];
  for (const k of Object.keys(flags)) {
    const v = flags[k];
    if (v === true) {
      args.push(`--${k}`);
    } else {
      args.push(`--${k}`, String(v));
    }
  }

  const orchestratorPath = path.resolve(process.cwd(), 'agents/core/orchestrator.js');
  if (!fs.existsSync(orchestratorPath)) {
    throw new Error(`Orchestrator not found at ${orchestratorPath}`);
  }

  const proc = spawnSync('node', [orchestratorPath, ...args], { encoding: 'utf-8', maxBuffer: 10 * 1024 * 1024 });
  if (proc.error) throw proc.error;
  if (proc.status !== 0) {
    const errOut = proc.stderr || proc.stdout;
    throw new Error(`Orchestrator exited with code ${proc.status}: ${errOut}`);
  }

  // parse JSON output
  try {
    return JSON.parse(proc.stdout);
  } catch (e) {
    throw new Error('Orchestrator did not return valid JSON: ' + String(e));
  }
}

/**
 * GET /api/plan?intent=<intent>&columns=a,b,c&tags=x,y&branch=...
 * Calls orchestrator with flags derived from querystring and returns the plan JSON.
 */
router.get('/api/plan', async (req, res) => {
  const intent = String(req.query.intent || '');
  if (!intent) return res.status(400).json({ error: 'intent query parameter is required' });

  const flags: Record<string, string | boolean> = { intent };

  if (req.query.columns) flags.columns = String(req.query.columns);
  if (req.query.changedPaths) flags.changedPaths = String(req.query.changedPaths);
  if (req.query.branch) flags.branch = String(req.query.branch);
  if (req.query.tags) flags.tags = String(req.query.tags);
  if (req.query.recipeMetadata) flags.recipeMetadata = String(req.query.recipeMetadata);

  try {
    const out = runOrchestrator(flags);
    return res.json(out);
  } catch (err: any) {
    return res.status(500).json({ error: err?.message || String(err) });
  }
});

/**
 * POST /api/intent
 * Body: { intent: string, payload?: object, tags?: [], metadata?: {} , author?: string }
 * Writes payload to a temp file and invokes orchestrator with --intent and --payloadPath
 */
router.post('/api/intent', express.json(), async (req, res) => {
  const body = req.body || {};
  const intent = body.intent || body.intentName;
  if (!intent) return res.status(400).json({ error: 'intent is required in body' });

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'ew-intent-'));
  try {
    const payload = body.payload || {};
    const payloadPath = path.join(tempDir, 'payload.json');
    fs.writeFileSync(payloadPath, JSON.stringify(payload, null, 2), 'utf-8');

    const flags: Record<string, string | boolean> = { intent, payloadPath };

    if (body.tags) flags.tags = Array.isArray(body.tags) ? body.tags.join(',') : String(body.tags);
    if (body.metadata) flags.recipeMetadata = JSON.stringify(body.metadata);
    if (body.columns) flags.columns = Array.isArray(body.columns) ? body.columns.join(',') : String(body.columns);

    // optional author forwarded as flag
    if (body.author) flags.author = String(body.author);

    const out = runOrchestrator(flags);

    // return 201 with plan + preview if orchestrator provides it
    return res.status(201).json(out);
  } catch (err: any) {
    return res.status(500).json({ error: err?.message || String(err) });
  } finally {
    // best-effort cleanup
    try { fs.rmSync(tempDir, { recursive: true, force: true }); } catch {}
  }
});

export default router;
