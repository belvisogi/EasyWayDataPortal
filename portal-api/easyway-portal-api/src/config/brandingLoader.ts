// easyway-portal-api/src/config/brandingLoader.ts
import fs from "fs";
import path from "path";
import YAML from "yaml";
import { BlobServiceClient, StorageSharedKeyCredential } from "@azure/storage-blob";
import { DefaultAzureCredential } from "@azure/identity";
import { TenantConfig } from "../types/config";

/**
 * Carica configurazione branding YAML per un tenant.
 * @param tenantId Tenant identificativo
 * @returns TenantConfig oggetto configurazione branding/label/path
 */
export async function loadBrandingConfig(tenantId: string): Promise<TenantConfig> {
  // 1) Prova da Azure Blob se configurato (DefaultAzureCredential fallback)
  const connectionString = process.env.AZURE_STORAGE_CONNECTION_STRING;
  const containerName = process.env.BRANDING_CONTAINER;
  const prefix = process.env.BRANDING_PREFIX || "config";
  const accountName = process.env.AZURE_STORAGE_ACCOUNT; // per MI

  try {
    if (containerName && (connectionString || accountName)) {
      let blobServiceClient: BlobServiceClient;
      if (connectionString) {
        blobServiceClient = BlobServiceClient.fromConnectionString(connectionString, {
          retryOptions: { maxTries: 4, tryTimeoutInMs: 15000 }
        });
      } else {
        const accountUrl = `https://${accountName}.blob.core.windows.net`;
        const credential = new DefaultAzureCredential();
        blobServiceClient = new BlobServiceClient(accountUrl, credential, {
          retryOptions: { maxTries: 4, tryTimeoutInMs: 15000 }
        });
      }
      const containerClient = blobServiceClient.getContainerClient(containerName);
      const blobName = `${prefix}/branding.${tenantId}.yaml`;
      const blockBlobClient = containerClient.getBlockBlobClient(blobName);
      if (await blockBlobClient.exists()) {
        const download = await blockBlobClient.download();
        const text = await streamToString(download.readableStreamBody as NodeJS.ReadableStream);
        return YAML.parse(text) as TenantConfig;
      }
    }
  } catch {
    // se errore o non esiste, fallback su locale
  }

  // 2) Fallback: file sample locale (dev)
  const filePath = path.join(__dirname, "../../datalake-sample", `branding.${tenantId}.yaml`);
  if (!fs.existsSync(filePath)) {
    throw new Error(`Branding YAML for tenant "${tenantId}" not found`);
  }
  const fileContent = fs.readFileSync(filePath, "utf-8");
  const config = YAML.parse(fileContent);
  return config as TenantConfig;
}

async function streamToString(stream: NodeJS.ReadableStream): Promise<string> {
  const chunks: Buffer[] = [];
  return await new Promise((resolve, reject) => {
    stream.on("data", (d: Buffer) => chunks.push(d));
    stream.on("end", () => resolve(Buffer.concat(chunks).toString("utf-8")));
    stream.on("error", reject);
  });
}
