// easyway-portal-api/src/routes/docs.ts
import { Router } from "express";
import fs from "fs";
import path from "path";
import YAML from "yaml";

const router = Router();

const specPath = path.resolve(__dirname, "../../openapi/openapi.yaml");

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

export default router;

