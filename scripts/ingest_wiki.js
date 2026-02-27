import { QdrantClient } from '@qdrant/js-client-rest';
import { pipeline } from '@xenova/transformers';
import { glob } from 'glob';
import fs from 'fs/promises';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';

// Configuration
const QDRANT_URL = process.env.QDRANT_URL || 'http://localhost:6333';
const QDRANT_API_KEY = process.env.QDRANT_API_KEY;
const COLLECTION_NAME = 'easyway_wiki';
const WIKI_PATH = process.env.WIKI_PATH || '../Wiki';

async function main() {
    console.log(`🚀 Starting Ingestion (The Feeder)...`);
    console.log(`Target: ${QDRANT_URL} (Collection: ${COLLECTION_NAME})`);

    // 1. Initialize Qdrant Client
    const client = new QdrantClient({
        url: QDRANT_URL,
        apiKey: QDRANT_API_KEY,
    });

    // 2. Initialize Embedding Model
    console.log(`Loading embedding model (all-MiniLM-L6-v2)...`);
    const extractor = await pipeline('feature-extraction', 'Xenova/all-MiniLM-L6-v2');

    // 3. Ensure Collection Exists
    try {
        const collections = await client.getCollections();
        const exists = collections.collections.some(c => c.name === COLLECTION_NAME);

        if (!exists) {
            console.log(`Creating collection '${COLLECTION_NAME}'...`);
            await client.createCollection(COLLECTION_NAME, {
                vectors: {
                    size: 384,
                    distance: 'Cosine',
                },
            });
        }
    } catch (e) {
        console.error(`Error checking/creating collection: ${e.message}`);
        process.exit(1);
    }

    // 4. Read Wiki Files
    console.log(`Reading Wiki files from ${WIKI_PATH}...`);
    const files = await glob(`${WIKI_PATH}/**/*.md`);
    console.log(`Found ${files.length} Markdown files.`);

    let totalPoints = 0;

    for (const file of files) {
        const content = await fs.readFile(file, 'utf-8');
        const filename = path.basename(file);

        // Simple Chunking (by paragraphs/headers for now)
        // Ideally: Use a smarter chunker. Here we split by double newline.
        const chunks = content.split(/\n\s*\n/).filter(c => c.trim().length > 50);

        if (chunks.length === 0) continue;

        const points = [];

        for (let i = 0; i < chunks.length; i++) {
            const chunkText = chunks[i].trim();

            // Generate Embedding
            const output = await extractor(chunkText, { pooling: 'mean', normalize: true });
            const vector = Array.from(output.data);

            points.push({
                id: uuidv4(),
                payload: {
                    filename: filename,
                    path: file,
                    content: chunkText,
                    chunk_index: i
                },
                vector: vector
            });
        }

        if (points.length > 0) {
            const BATCH_SIZE = 20;
            for (let b = 0; b < points.length; b += BATCH_SIZE) {
                await client.upsert(COLLECTION_NAME, {
                    points: points.slice(b, b + BATCH_SIZE)
                });
            }
            console.log(`Indexed ${filename}: ${points.length} chunks.`);
            totalPoints += points.length;
        }
    }

    console.log(`✅ Ingestion Complete! Total chunks indexed: ${totalPoints}`);
}

main().catch(console.error);
