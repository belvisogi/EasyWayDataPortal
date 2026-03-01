/**
 * embed-query.js — Query embedding for RAG vector search
 *
 * Usage:
 *   node scripts/embed-query.js "query text here"
 *
 * Output (stdout): JSON { "vector": [384 floats] }
 * Logs:           stderr only (silent in pipeline)
 *
 * Model: Xenova/all-MiniLM-L6-v2 (same as ingest_wiki.js)
 *   pooling: mean, normalize: true → 384-dim cosine vectors
 *
 * Requires local cache (no network): model cached by ingest at
 *   node_modules/@xenova/transformers/.cache/Xenova/all-MiniLM-L6-v2/
 */

import { pipeline, env } from '@xenova/transformers';

// Local cache only — never download (network may be blocked)
env.allowRemoteModels = false;
env.useBrowserCache   = false;

const query = process.argv[2];
if (!query || !query.trim()) {
    process.stderr.write('Usage: node embed-query.js "query text"\n');
    process.exit(1);
}

// Silence model-loading logs → stderr so stdout stays clean JSON
const _log = console.log;
console.log = (...a) => process.stderr.write(a.join(' ') + '\n');

let extractor;
try {
    extractor = await pipeline('feature-extraction', 'Xenova/all-MiniLM-L6-v2');
} catch (e) {
    process.stderr.write(`Model load error: ${e.message}\n`);
    process.exit(2);
} finally {
    console.log = _log;
}

const output = await extractor(query.trim(), { pooling: 'mean', normalize: true });
const vector = Array.from(output.data);

process.stdout.write(JSON.stringify({ vector }) + '\n');
