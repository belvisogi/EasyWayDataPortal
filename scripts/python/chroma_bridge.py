import sys
import os
import json
import chromadb
from chromadb.utils import embedding_functions

# Configuration
CHROMA_HOST = os.environ.get("CHROMA_HOST", "localhost")
CHROMA_PORT = os.environ.get("CHROMA_PORT", "8000")
COLLECTION_NAME = "easyway_knowledge"

def get_client():
    # Attempt to connect to remote Chroma (Container), fall back to ephemeral for test
    try:
        return chromadb.HttpClient(host=CHROMA_HOST, port=int(CHROMA_PORT))
    except:
        return chromadb.Client() # In-memory fallback

def upsert_documents(documents, metadatas, ids):
    client = get_client()
    # Default embedding function (all-MiniLM-L6-v2) is automatic if not specified
    # For container usage, we ensure chromadb is installed with default deps
    collection = client.get_or_create_collection(name=COLLECTION_NAME)
    
    collection.upsert(
        documents=documents,
        metadatas=metadatas,
        ids=ids
    )
    print(json.dumps({"status": "success", "count": len(ids)}))

def query_knowledge(query_text, n_results=3):
    client = get_client()
    collection = client.get_or_create_collection(name=COLLECTION_NAME)
    
    results = collection.query(
        query_texts=[query_text],
        n_results=n_results
    )
    
    # Flatten results for JSON output
    output = []
    if results["documents"]:
        for i in range(len(results["documents"][0])):
            output.append({
                "content": results["documents"][0][i],
                "metadata": results["metadatas"][0][i],
                "id": results["ids"][0][i],
                "distance": results["distances"][0][i] if results["distances"] else 0
            })
            
    print(json.dumps(output))

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: chroma_bridge.py [upsert|query] [payload_json]")
        sys.exit(1)
        
    command = sys.argv[1]
    
    # Read payload from stdin if not provided as arg (for large JSONs)
    if len(sys.argv) > 2:
        payload = json.loads(sys.argv[2])
    else:
        payload = json.load(sys.stdin)

    if command == "upsert":
        upsert_documents(payload["documents"], payload["metadatas"], payload["ids"])
    elif command == "query":
        query_knowledge(payload["query"], payload.get("n", 3))
    else:
        print(f"Unknown command: {command}")
