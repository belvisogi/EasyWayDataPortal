require('dotenv').config();
const { BlobServiceClient, StorageSharedKeyCredential } = require('@azure/storage-blob');

const account = process.env.AZURE_STORAGE_ACCOUNT_NAME;
const accountKey = process.env.AZURE_STORAGE_ACCOUNT_KEY;
const containerName = process.env.AZURE_CONTAINER_NAME;
const prefixPath = 'h_reference/prj_ifrs9/otb_out_moody/2023/01/';

const sharedKeyCredential = new StorageSharedKeyCredential(account, accountKey);
const blobServiceClient = new BlobServiceClient(
  `https://${account}.blob.core.windows.net`,
  sharedKeyCredential
);

async function listArchivedBlobs() {
  const containerClient = blobServiceClient.getContainerClient(containerName);

  console.log(`🔍 Scanning for archived files in: ${prefixPath}\n`);

  for await (const blob of containerClient.listBlobsFlat({ prefix: prefixPath })) {
    const blobClient = containerClient.getBlobClient(blob.name);
    const props = await blobClient.getProperties();

    if (props.accessTier && props.accessTier.toLowerCase() === 'archive') {
      console.log(`📦 ARCHIVE FILE: ${blob.name}`);
    }
  }
}

listArchivedBlobs().catch((err) => {
  console.error("❌ Error:", err.message);
});
