#!/usr/bin/env python3
"""ChromaDB Manager for EasyWay AI Agent"""

import chromadb
from chromadb.config import Settings
from sentence_transformers import SentenceTransformer
import json
import sys
import os
from pathlib import Path

# Add local bin to path just in case
sys.path.append(os.path.expanduser("~/.local/lib/python3.12/site-packages"))

class KnowledgeBaseManager:
    def __init__(self, persist_dir="~/easyway-kb"):
        self.persist_dir = Path(persist_dir).expanduser()
        self.persist_dir.mkdir(parents=True, exist_ok=True)
        
        # ChromaDB client
        self.client = chromadb.PersistentClient(path=str(self.persist_dir))
        
        # Embedding model (all-MiniLM-L6-v2: fast, CPU-friendly)
        self.embedder = SentenceTransformer('all-MiniLM-L6-v2')
        
        # Collection
        self.collection = self.client.get_or_create_collection(
            name="easyway_knowledge",
            metadata={"description": "EasyWay agent knowledge base"}
        )
    
    def index_document(self, doc_path, doc_id=None):
        """Index a document into ChromaDB"""
        with open(doc_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        if doc_id is None:
            doc_id = f"doc_{Path(doc_path).stem}"
        
        # Generate embedding
        embedding = self.embedder.encode(content).tolist()
        
        # Add to collection
        self.collection.add(
            documents=[content],
            embeddings=[embedding],
            ids=[doc_id],
            metadatas=[{"filename": Path(doc_path).name, "path": str(doc_path)}]
        )
        
        # Output JSON for PowerShell to parse easily
        print(json.dumps({"status": "indexed", "id": doc_id, "file": str(doc_path)}))
        return doc_id
    
    def search(self, query, top_k=3):
        """Semantic search"""
        query_embedding = self.embedder.encode(query).tolist()
        
        results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=top_k
        )
        
        output = {
            "query": query,
            "results": []
        }
        
        if results['ids']:
            for i in range(len(results['ids'][0])):
                output["results"].append({
                    "doc_id": results['ids'][0][i],
                    "content": results['documents'][0][i],
                    "distance": results['distances'][0][i] if results['distances'] else 0,
                    "metadata": results['metadatas'][0][i]
                })
                
        return output

if __name__ == "__main__":
    try:
        kb = KnowledgeBaseManager()
        
        if len(sys.argv) < 2:
            print(json.dumps({"error": "Usage: script.py index <file> OR search <query>"}))
            sys.exit(1)
        
        command = sys.argv[1]
        
        if command == "index":
            doc_path = sys.argv[2]
            kb.index_document(doc_path)
        
        elif command == "search":
            query = " ".join(sys.argv[2:])
            results = kb.search(query)
            print(json.dumps(results))
            
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)
