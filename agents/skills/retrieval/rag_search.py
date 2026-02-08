
import os
import sys
import json
from qdrant_client import QdrantClient
from sentence_transformers import SentenceTransformer

# Configuration
QDRANT_HOST = os.getenv("QDRANT_HOST", "localhost")
QDRANT_PORT = int(os.getenv("QDRANT_PORT", 6333))
QDRANT_API_KEY = os.getenv("QDRANT_API_KEY", None)
COLLECTION_NAME = "easyway_wiki"

def search(query, limit=5):
    try:
        # 1. Connect to Qdrant
        # Force HTTP to avoid SSL errors internal to the cluster
        url = f"http://{QDRANT_HOST}:{QDRANT_PORT}"
        client = QdrantClient(url=url, api_key=QDRANT_API_KEY)

        # 2. Load Model & Embed Query
        # matching the Node.js ingestion model
        model = SentenceTransformer('all-MiniLM-L6-v2')
        query_vector = model.encode(query).tolist()

        # 3. Search
        # 3. Search
        # client.search was removed/missing, using query_points
        search_result = client.query_points(
            collection_name=COLLECTION_NAME,
            query=query_vector,
            limit=limit
        )
        hits = search_result.points

        # 4. Format Results
        results = []
        for hit in hits:
            results.append({
                "filename": hit.payload.get("filename"),
                "content": hit.payload.get("content"),
                "score": hit.score,
                "path": hit.payload.get("path")
            })

        return {"results": results}

    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No query provided"}))
        sys.exit(1)

    query_text = sys.argv[1]
    response = search(query_text)
    print(json.dumps(response))
