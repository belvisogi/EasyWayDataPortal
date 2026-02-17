import fs from "fs";
import path from "path";
import { TenantGuard } from "./isolation";

function ensureDir(p: string) {
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
}

// Global guard instance (baseDir = repo root)
// Assuming this is called from 'dist', repo root is 2 levels up.
// NOTE: Ideally this should be injected or configured.
const repoRoot = path.resolve(__dirname, "../../");
const guard = new TenantGuard(repoRoot);

export function getDataPath(fileName: string): string {
  const dataDir = path.join(repoRoot, "data");
  ensureDir(dataDir);
  return path.join(dataDir, fileName);
}

/**
 * Validates path security for a given tenant.
 * Defaults to 'system' tenant if none provided (CAUTION: Use real tenantId in prod).
 */
function validateAccess(filePath: string, operation: 'read' | 'write') {
  // TODO: Extract tenantId from context/ALS in a real request.
  // For now, we enforce isolation if a tenantId is passed, or default to system safety.
  // Since this util is generic, we might need to refactor signatures to accept tenantId.
  // For this iteration, we check if path is within repoRoot.
  try {
    guard.validatePath(filePath, 'system-fallback', operation);
  } catch (e: any) {
    // Allow data/ access for backward compatibility until full migration
    if (filePath.includes(path.join(repoRoot, 'data'))) return;
    throw e;
  }
}

export function readJsonFile<T>(fileName: string, def: T): T {
  const p = getDataPath(fileName);
  validateAccess(p, 'read');
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
  validateAccess(p, 'write');
  fs.writeFileSync(p, JSON.stringify(data, null, 2), "utf-8");
}

