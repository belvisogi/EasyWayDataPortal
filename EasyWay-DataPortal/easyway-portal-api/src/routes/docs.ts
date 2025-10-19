// easyway-portal-api/src/routes/docs.ts
import { Router } from "express";
import fs from "fs";
import path from "path";
import YAML from "yaml";

const router = Router();

const specPath = path.resolve(__dirname, "../../openapi/openapi.yaml");
const kbPath = path.resolve(__dirname, "../../../agents/kb/recipes.jsonl");
const activityPath = path.resolve(__dirname, "../../../agents/logs/events.jsonl");

router.get(["/", ""], (_req, res) => {
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

router.get("/openapi.yaml", (_req, res) => {
  if (!fs.existsSync(specPath)) {
    return res.status(404).json({ message: "Spec not found" });
  }
  res.type("text/yaml").send(fs.readFileSync(specPath, "utf-8"));
});

router.get("/openapi.json", (_req, res) => {
  if (!fs.existsSync(specPath)) {
    return res.status(404).json({ message: "Spec not found" });
  }
  const yamlText = fs.readFileSync(specPath, "utf-8");
  const obj = YAML.parse(yamlText);
  res.json(obj);
});

router.get("/kb.json", (_req, res) => {
  try {
    if (!fs.existsSync(kbPath)) return res.status(404).json({ message: "KB not found" });
    const text = fs.readFileSync(kbPath, "utf-8");
    const lines = text.split(/\r?\n/).filter(Boolean);
    const items = lines.map((l) => JSON.parse(l));
    res.json(items);
  } catch (err: any) {
    res.status(500).json({ error: err?.message || "KB read error" });
  }
});

export default router;
router.get("/activity.json", (_req, res) => {
  try {
    if (!fs.existsSync(activityPath)) return res.status(404).json({ message: "Activity log not found" });
    const text = fs.readFileSync(activityPath, "utf-8");
    const lines = text.split(/\r?\n/).filter(Boolean);
    const items = lines.map((l) => JSON.parse(l));
    res.json(items);
  } catch (err: any) {
    res.status(500).json({ error: err?.message || "Activity read error" });
  }
});
