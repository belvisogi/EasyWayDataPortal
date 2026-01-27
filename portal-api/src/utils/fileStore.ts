import fs from "fs";
import path from "path";

function ensureDir(p: string) {
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
}

export function getDataPath(fileName: string): string {
  // Resolve repo root from compiled dist path
  const repoRoot = path.resolve(__dirname, "../../");
  const dataDir = path.join(repoRoot, "data");
  ensureDir(dataDir);
  return path.join(dataDir, fileName);
}

export function readJsonFile<T>(fileName: string, def: T): T {
  const p = getDataPath(fileName);
  try {
    if (!fs.existsSync(p)) return def;
    const txt = fs.readFileSync(p, "utf-8");
    return JSON.parse(txt) as T;
  } catch {
    return def;
  }
}

export function writeJsonFile<T>(fileName: string, data: T): void {
  const p = getDataPath(fileName);
  fs.writeFileSync(p, JSON.stringify(data, null, 2), "utf-8");
}

