#!/usr/bin/env python3
"""
ChromaDB Quick Test - Embedding and Retrieval Demo
Demonstrates basic vector database operations
"""

import chromadb
from chromadb.config import Settings
import sys

def main():
    print("🔍 ChromaDB Quick Test")
    print("=" * 50)
    
    # Connect to ChromaDB
    try:
        client = chromadb.HttpClient(
            host='localhost',
            port=8000,
            settings=Settings(anonymized_telemetry=False)
        )
        
        print("✅ Connected to ChromaDB")
        print(f"   Heartbeat: {client.heartbeat()}")
        
    except Exception as e:
        print(f"❌ Failed to connect: {e}")
        sys.exit(1)
    
    # Create or get collection
    collection_name = "easyway_test"
    
    try:
        # Delete if exists (fresh start)
        try:
            client.delete_collection(name=collection_name)
            print(f"🗑️  Deleted existing collection '{collection_name}'")
        except:
            pass
        
        # Create collection
        collection = client.create_collection(
            name=collection_name,
            metadata={"description": "EasyWay test collection"}
        )
        print(f"✅ Created collection '{collection_name}'")
        
    except Exception as e:
        print(f"❌ Collection error: {e}")
        sys.exit(1)
    
    # Add documents with embeddings (ChromaDB auto-generates embeddings)
    documents = [
        "EasyWay Data Portal uses enterprise RBAC with 4 security groups",
        "ChromaDB is the vector database for agent knowledge retrieval",
        "The security framework includes ACLs for directory protection",
        "Agent DBA requires easyway-admin group membership",
        "AI security guardrails protect against prompt injection"
    ]
    
    ids = [f"doc{i}" for i in range(len(documents))]
    
    metadatas = [
        {"category": "security", "source": "SECURITY_FRAMEWORK.md"},
        {"category": "infrastructure", "source": "docker-compose.yml"},
        {"category": "security", "source": "apply-acls.sh"},
        {"category": "agents", "source": "agent_dba/manifest.json"},
        {"category": "security", "source": "ai-security-guardrails.md"}
    ]
    
    try:
        collection.add(
            documents=documents,
            ids=ids,
            metadatas=metadatas
        )
        print(f"✅ Added {len(documents)} documents to collection")
        
    except Exception as e:
        print(f"❌ Failed to add documents: {e}")
        sys.exit(1)
    
    # Query - semantic search
    print("\n" + "=" * 50)
    print("🔎 Semantic Search Test")
    print("=" * 50)
    
    queries = [
        "How do I secure the database?",
        "What permissions does an agent need?",
        "Tell me about vector databases"
    ]
    
    for query in queries:
        print(f"\n📝 Query: '{query}'")
        
        results = collection.query(
            query_texts=[query],
            n_results=2
        )
        
        print("   Top matches:")
        for i, (doc, metadata, distance) in enumerate(zip(
            results['documents'][0],
            results['metadatas'][0],
            results['distances'][0]
        ), 1):
            print(f"   {i}. [{metadata['category']}] {doc[:80]}...")
            print(f"      Source: {metadata['source']}, Distance: {distance:.4f}")
    
    # Statistics
    print("\n" + "=" * 50)
    print("📊 Collection Statistics")
    print("=" * 50)
    print(f"   Total documents: {collection.count()}")
    print(f"   Collection name: {collection.name}")
    print(f"   Metadata: {collection.metadata}")
    
    print("\n✅ ChromaDB test completed successfully!")

if __name__ == "__main__":
    main()
