import { BlobServiceClient } from "@azure/storage-blob";
import { DefaultAzureCredential } from "@azure/identity";

/**
 * Tenta di leggere una query SQL da Azure Blob Storage.
 * Se le variabili d'ambiente non sono configurate, lascia fallire (il chiamante gestisce il fallback locale).
 *
 * Richiede:
 * - AZURE_STORAGE_CONNECTION_STRING
 * - QUERIES_CONTAINER (nome container dove risiedono le query)
 */
export async function loadSqlQueryFromBlob(fileName: string): Promise<string> {
  const connectionString = process.env.AZURE_STORAGE_CONNECTION_STRING;
  const containerName = process.env.QUERIES_CONTAINER || process.env.AZURE_STORAGE_CONTAINER;
  const accountName = process.env.AZURE_STORAGE_ACCOUNT;

  if (!containerName) throw new Error("Blob storage not configured for queries");

  let blobServiceClient: BlobServiceClient;
  if (connectionString) {
    blobServiceClient = BlobServiceClient.fromConnectionString(connectionString, {
      retryOptions: { maxTries: 4, tryTimeoutInMs: 15000 }
    });
  } else if (accountName) {
    const accountUrl = `https://${accountName}.blob.core.windows.net`;
    const credential = new DefaultAzureCredential();
    blobServiceClient = new BlobServiceClient(accountUrl, credential, {
      retryOptions: { maxTries: 4, tryTimeoutInMs: 15000 }
    });
  } else {
    throw new Error("Blob storage not configured for queries (missing connection/account)");
  }

  const containerClient = blobServiceClient.getContainerClient(containerName);
  const prefix = process.env.QUERIES_PREFIX ? `${process.env.QUERIES_PREFIX.replace(/\/$/, "")}/` : "";
  const blockBlobClient = containerClient.getBlockBlobClient(`${prefix}${fileName}`);

  const exists = await blockBlobClient.exists();
  if (!exists) throw new Error(`Query ${fileName} not found in blob container ${containerName}`);

  const download = await blockBlobClient.download();
  const downloaded = await streamToString(download.readableStreamBody as NodeJS.ReadableStream);
  return downloaded;
}

async function streamToString(stream: NodeJS.ReadableStream): Promise<string> {
  const chunks: Buffer[] = [];
  return await new Promise((resolve, reject) => {
    stream.on("data", (d: Buffer) => chunks.push(d));
    stream.on("end", () => resolve(Buffer.concat(chunks).toString("utf-8")));
    stream.on("error", reject);
  });
}
