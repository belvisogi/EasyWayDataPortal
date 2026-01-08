import { Router, Request, Response, NextFunction } from "express";
import fs from "fs";
import path from "path";
import { requireAccessFromEnv } from "../middleware/authorize";
import { auditAccess } from "../middleware/audit";
import { validateQuery } from "../middleware/validate";
import { dbDiagramQuerySchema } from "../validators/dbValidator";
import { AppError } from "../utils/errors";

const router = Router();

function getDiagramPath() {
  const envPath = (process.env.DB_DIAGRAM_PATH || "").trim();
  if (envPath) return envPath;
  return path.resolve(process.cwd(), "data/db/portal-diagram.json");
}

router.use(auditAccess("api.db"));
router.use(requireAccessFromEnv({
  rolesEnv: "DB_ROLES",
  scopesEnv: "DB_SCOPES",
  defaultRoles: ["portal_admin", "portal_governance", "portal_ops"]
}));

router.get("/diagram", validateQuery(dbDiagramQuerySchema), (req: Request, res: Response, next: NextFunction) => {
  const p = getDiagramPath();
  if (!fs.existsSync(p)) {
    return next(new AppError(404, "not_found", "Diagram not found", {
      hint: "Generate it with: npm run db:diagram:refresh",
      path: p
    }));
  }

  try {
    const raw = fs.readFileSync(p, "utf-8");
    const json = JSON.parse(raw);
    res.setHeader("Cache-Control", "private, max-age=60");
    return res.json(json);
  } catch (e: any) {
    return next(new AppError(500, "internal_error", "Failed to read diagram JSON", e?.message || String(e)));
  }
});

export default router;
