import { Router } from "express";
import fs from "fs";
import path from "path";

const router = Router();

function getDiagramPath() {
  const envPath = (process.env.DB_DIAGRAM_PATH || "").trim();
  if (envPath) return envPath;
  return path.resolve(process.cwd(), "data/db/portal-diagram.json");
}

router.get("/diagram", (req, res) => {
  const schema = String(req.query.schema || "PORTAL").trim().toUpperCase();
  if (schema !== "PORTAL") {
    return res.status(400).json({ error: "Unsupported schema (only PORTAL)", schema });
  }

  const p = getDiagramPath();
  if (!fs.existsSync(p)) {
    return res.status(404).json({
      error: "Diagram not found",
      hint: "Generate it with: npm run db:diagram:refresh",
      path: p,
    });
  }

  try {
    const raw = fs.readFileSync(p, "utf-8");
    const json = JSON.parse(raw);
    res.setHeader("Cache-Control", "private, max-age=60");
    return res.json(json);
  } catch (e: any) {
    return res.status(500).json({ error: "Failed to read diagram JSON", message: e?.message || String(e) });
  }
});

export default router;

