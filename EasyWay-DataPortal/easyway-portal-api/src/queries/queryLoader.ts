import fs from "fs";
import path from "path";
import { loadSqlQueryFromBlob } from "../config/queryLoader";

/**
 * Carica una query SQL:
 * - Prima cerca su Blob Storage (custom override)
 * - Se non trovata, usa la versione locale sotto /src/queries
 */
export async function loadQueryWithFallback(fileName: string): Promise<string> {
  try {
    // Tenta override su Blob (custom)
    return await loadSqlQueryFromBlob(fileName);
  } catch (err) {
    // Se errore (es: blob non esiste), fallback su query locale
    const localPath = path.join(__dirname, fileName);
    if (!fs.existsSync(localPath)) {
      throw new Error(`Query "${fileName}" non trovata né su Blob né localmente`);
    }
    return fs.readFileSync(localPath, "utf-8");
  }
}
