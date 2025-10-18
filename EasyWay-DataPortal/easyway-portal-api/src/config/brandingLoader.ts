// easyway-portal-api/src/config/brandingLoader.ts
import fs from "fs";
import path from "path";
import YAML from "yaml";
import { TenantConfig } from "../types/config";

/**
 * Carica configurazione branding YAML per un tenant.
 * @param tenantId Tenant identificativo
 * @returns TenantConfig oggetto configurazione branding/label/path
 */
export function loadBrandingConfig(tenantId: string): TenantConfig {
  // In produzione: monta qui il path del file su Datalake/Blob
  const filePath = path.join(__dirname, "../../datalake-sample", `branding.${tenantId}.yaml`);
  if (!fs.existsSync(filePath)) {
    throw new Error(`Branding YAML for tenant "${tenantId}" not found`);
  }
  const fileContent = fs.readFileSync(filePath, "utf-8");
  const config = YAML.parse(fileContent);
  return config as TenantConfig;
}
