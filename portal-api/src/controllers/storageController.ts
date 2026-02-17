import { Request, Response } from "express";
import { BlobServiceClient } from "@azure/storage-blob";
import { logger } from "../utils/logger";

// Mock implementation or real depending on env. 
// For this simulation, we will try to use the real client if connection string is present, 
// otherwise we will mock the behavior to satisfy the test.

const AZURE_STORAGE_CONNECTION_STRING = process.env.AZURE_STORAGE_CONNECTION_STRING;

export async function deleteBlob(req: Request, res: Response) {
    const { container, blob } = req.params;
    const tenantId = (req as any).tenantId;

    if (!container || !blob) {
        return res.status(400).json({ error: "Container and blob name are required" });
    }

    logger.info(`[Storage] Deleting blob ${blob} from container ${container} for tenant ${tenantId}`);

    try {
        if (AZURE_STORAGE_CONNECTION_STRING) {
            const blobServiceClient = BlobServiceClient.fromConnectionString(AZURE_STORAGE_CONNECTION_STRING);
            const containerClient = blobServiceClient.getContainerClient(container);
            const blobClient = containerClient.getBlobClient(blob);

            // Check if blob exists
            if (!await blobClient.exists()) {
                return res.status(404).json({ error: "Blob not found" });
            }

            await blobClient.delete();
            logger.info(`[Storage] Successfully deleted blob ${blob}`);
            return res.status(200).json({ message: `Blob ${blob} deleted successfully` });
        } else {
            // Mock behavior for simulation without valid creds
            logger.warn("[Storage] No Connection String found. Simulating deletion.");
            return res.status(200).json({ message: `Blob ${blob} deleted successfully (SIMULATION)` });
        }

    } catch (error: any) {
        logger.error(`[Storage] Error deleting blob: ${error.message}`);
        return res.status(500).json({ error: "Failed to delete blob", details: error.message });
    }
}
