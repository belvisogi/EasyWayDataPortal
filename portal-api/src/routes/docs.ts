// easyway-portal-api/src/routes/docs.ts
import { Router, Request, Response, NextFunction } from "express";
import fs from "fs";
import path from "path";
import YAML from "yaml";
import { requireAccessFromEnv } from "../middleware/authorize";
import { auditAccess } from "../middleware/audit";
import { AppError } from "../utils/errors";

const router = Router();

const specPath = path.resolve(__dirname, "../../openapi/openapi.yaml");
const kbPath = path.resolve(__dirname, "../../../agents/kb/recipes.jsonl");
const activityPath = path.resolve(__dirname, "../../../agents/logs/events.jsonl");

router.use(auditAccess("api.docs"));
router.use(requireAccessFromEnv({
  rolesEnv: "DOCS_ROLES",
  scopesEnv: "DOCS_SCOPES",
  defaultRoles: ["portal_admin", "portal_governance", "portal_ops"]
}));

router.get(["/", ""], (_req: Request, res: Response) => {
  res.type("html").send(`<!doctype html>
  <html><head><meta charset="utf-8"><title>EasyWay API Docs</title></head>
  <body>
    <h1>EasyWay API Docs</h1>
    <ul>
      <li><a href="./openapi.yaml">openapi.yaml</a></li>
      <li><a href="./openapi.json">openapi.json</a></li>
    </ul>
  </body></html>`);
});

router.get("/openapi.yaml", (_req: Request, res: Response, next: NextFunction) => {
  if (!fs.existsSync(specPath)) {
    return next(new AppError(404, "not_found", "Spec not found"));
  }
  res.type("text/yaml").send(fs.readFileSync(specPath, "utf-8"));
});

router.get("/openapi.json", (_req: Request, res: Response, next: NextFunction) => {
  if (!fs.existsSync(specPath)) {
    return next(new AppError(404, "not_found", "Spec not found"));
  }
  const yamlText = fs.readFileSync(specPath, "utf-8");
  const obj = YAML.parse(yamlText);
  res.json(obj);
});

router.get("/kb.json", (_req: Request, res: Response, next: NextFunction) => {
  try {
    if (!fs.existsSync(kbPath)) return next(new AppError(404, "not_found", "KB not found"));
    const text = fs.readFileSync(kbPath, "utf-8");
    const lines = text.split(/\r?\n/).filter(Boolean);
    const items = lines.map((l) => JSON.parse(l));
    res.json(items);
  } catch (err: any) {
    next(err);
  }
});

export default router;
router.get("/activity.json", (_req: Request, res: Response, next: NextFunction) => {
  try {
    if (!fs.existsSync(activityPath)) return next(new AppError(404, "not_found", "Activity log not found"));
    const text = fs.readFileSync(activityPath, "utf-8");
    const lines = text.split(/\r?\n/).filter(Boolean);
    const items = lines.map((l) => JSON.parse(l));
    res.json(items);
  } catch (err: any) {
    next(err);
  }
});

router.get("/activity/approved", (_req: Request, res: Response, next: NextFunction) => {
  try {
    if (!fs.existsSync(activityPath)) return next(new AppError(404, "not_found", "Activity log not found"));
    const text = fs.readFileSync(activityPath, "utf-8");
    const lines = text.split(/\r?\n/).filter(Boolean);
    const items = lines.map((l) => JSON.parse(l));
    const approved = items.filter((e: any) => {
      const v = ("" + (e.govApproved ?? "")).toLowerCase();
      return v === "true";
    });
    res.json(approved);
  } catch (err: any) {
    next(err);
  }
});
