---
id: ew-archive-imported-docs-2026-01-30-playground-setup
title: EasyWay Playground Setup - Complete Guide
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
tags: [domain/docs, layer/reference, privacy/internal, language/it, audience/dev]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
type: guide
---
# EasyWay Playground Setup - Complete Guide

## 🎯 Overview

This guide sets up a complete development playground for EasyWay on Ubuntu VM with:
- **n8n** - Visual workflow automation
- **Qdrant** - Vector database for RAG
- **DeepSeek** - Cost-effective LLM ($0.14/1M tokens)
- **Ollama** - Local LLM (free tier)
- **PowerShell Core** - Agent scripting
- **Node.js** - API runtime
- **Azure SQL** - Existing database

**Total Setup Time:** ~30 minutes  
**Monthly Cost:** ~$22 (vs $1,560 with GPT-4 only)

---

## 📋 Prerequisites

- Ubuntu 22.04 LTS VM (8GB RAM, 50GB disk)
- Azure SQL Server connection string
- DeepSeek API key (get from https://platform.deepseek.com/)
- OpenAI API key (optional, for fallback)

---

## 🚀 Quick Start (Automated)

```bash
# Download setup script
curl -o setup-playground.sh https://raw.githubusercontent.com/your-repo/scripts/setup-playground.sh
chmod +x setup-playground.sh

# Run setup
sudo ./setup-playground.sh

# Start services
cd ~/easyway-playground
docker-compose up -d

# Access services
# n8n:    http://localhost:5678
# Qdrant: http://localhost:6333/dashboard
# Ollama: http://localhost:11434
```

---

## 📖 Manual Setup (Step-by-Step)

### 1. Install Docker & Docker Compose

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Verify
docker --version
docker compose version
```

### 2. Install PowerShell Core

```bash
# Install via snap (easiest)
sudo snap install powershell --classic

# Verify
pwsh --version
```

### 3. Install Node.js

```bash
# Install Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify
node --version
npm --version
```

### 4. Install SQL Server Tools

```bash
# Add Microsoft repository
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list

# Install tools
sudo apt update
sudo apt install -y mssql-tools unixodbc-dev

# Add to PATH
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc
```

### 5. Create Playground Directory

```bash
mkdir -p ~/easyway-playground
cd ~/easyway-playground
```

### 6. Create docker-compose.yml

```bash
nano docker-compose.yml
```

**Paste this content:**

```yaml
version: '3.8'

services:
  # n8n - Workflow Automation
  n8n:
    image: n8nio/n8n:latest
    container_name: easyway-n8n
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=easyway2026
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://localhost:5678/
      - GENERIC_TIMEZONE=Europe/Rome
      # LLM API Keys
      - DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      # Database
      - AZURE_SQL_SERVER=${AZURE_SQL_SERVER}
      - AZURE_SQL_DATABASE=${AZURE_SQL_DATABASE}
      - AZURE_SQL_USER=${AZURE_SQL_USER}
      - AZURE_SQL_PASSWORD=${AZURE_SQL_PASSWORD}
    volumes:
      - n8n_data:/home/node/.n8n
      - ./workflows:/workflows
      - ./scripts:/scripts
    restart: unless-stopped
    networks:
      - easyway-net

  # Qdrant - Vector Database
  qdrant:
    image: qdrant/qdrant:latest
    container_name: easyway-qdrant
    ports:
      - "6333:6333"  # REST API
      - "6334:6334"  # gRPC
    volumes:
      - qdrant_storage:/qdrant/storage
    environment:
      - QDRANT__SERVICE__GRPC_PORT=6334
    restart: unless-stopped
    networks:
      - easyway-net

  # Ollama - Local LLM (Optional)
  ollama:
    image: ollama/ollama:latest
    container_name: easyway-ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    restart: unless-stopped
    networks:
      - easyway-net

  # PostgreSQL - n8n Database (Optional but recommended)
  postgres:
    image: postgres:15-alpine
    container_name: easyway-postgres
    environment:
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=n8n
      - POSTGRES_DB=n8n
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped
    networks:
      - easyway-net

volumes:
  n8n_data:
  qdrant_storage:
  ollama_data:
  postgres_data:

networks:
  easyway-net:
    driver: bridge
```

### 7. Create Environment File

```bash
nano .env
```

**Add your credentials:**

```env
# DeepSeek API
DEEPSEEK_API_KEY=sk-your-deepseek-key

# OpenAI API (optional, for fallback)
OPENAI_API_KEY=sk-your-openai-key

# Azure SQL
AZURE_SQL_SERVER=your-server.database.windows.net
AZURE_SQL_DATABASE=EasyWayDataPortal
AZURE_SQL_USER=your-user
AZURE_SQL_PASSWORD=your-password
```

### 8. Start Services

```bash
# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

### 9. Verify Services

```bash
# n8n
curl http://localhost:5678

# Qdrant
curl http://localhost:6333/collections

# Ollama (after pulling a model)
curl http://localhost:11434/api/tags
```

---

## 🧪 Initial Configuration

### 1. Access n8n

```
URL: http://localhost:5678
User: admin
Password: easyway2026
```

### 2. Pull Ollama Model (Optional)

```bash
# Enter Ollama container
docker exec -it easyway-ollama bash

# Pull a model (choose one)
ollama pull llama3.2        # 2GB - Fast, good for simple tasks
ollama pull mistral         # 4GB - Balanced
ollama pull deepseek-r1     # 8GB - Best quality

# Exit container
exit

# Test model
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Hello, how are you?",
  "stream": false
}'
```

### 3. Initialize Qdrant Collections

```bash
# Create collection for Wiki embeddings
curl -X PUT http://localhost:6333/collections/easyway-wiki \
  -H 'Content-Type: application/json' \
  -d '{
    "vectors": {
      "size": 1536,
      "distance": "Cosine"
    }
  }'

# Create collection for Agent memory
curl -X PUT http://localhost:6333/collections/agent-memory \
  -H 'Content-Type: application/json' \
  -d '{
    "vectors": {
      "size": 1536,
      "distance": "Cosine"
    }
  }'
```

---

## 🎯 LLM Strategy & Cost Optimization

### Multi-Tier LLM Approach

```
┌─────────────────────────────────────────┐
│ TIER 0: Ollama (Local)                  │
│ - Simple queries                        │
│ - Testing/Development                   │
│ Cost: $0.00                             │
└─────────────────────────────────────────┘
           ↓ (if local model insufficient)
┌─────────────────────────────────────────┐
│ TIER 1: DeepSeek (Default)              │
│ - 90% of agent tasks                    │
│ - Wiki queries                          │
│ - Data processing                       │
│ Cost: $0.14 input / $0.28 output per 1M │
└─────────────────────────────────────────┘
           ↓ (if complex reasoning needed)
┌─────────────────────────────────────────┐
│ TIER 2: GPT-4o-mini                     │
│ - Complex reasoning                     │
│ - Critical decisions                    │
│ Cost: $0.15 input / $0.60 output per 1M │
└─────────────────────────────────────────┘
           ↓ (only for strategic agents)
┌─────────────────────────────────────────┐
│ TIER 3: GPT-4o                          │
│ - Strategic planning (agent_gedi)       │
│ - High-stakes decisions                 │
│ Cost: $2.50 input / $10 output per 1M   │
└─────────────────────────────────────────┘
```

### Cost Comparison (26 Agents, 100 exec/day)

| Strategy | Monthly Cost | Savings |
|----------|--------------|---------|
| **GPT-4 Only** | $1,560 | - |
| **GPT-4o-mini Only** | $78 | 95% |
| **DeepSeek Only** | $22 | 98.6% |
| **Multi-Tier (Recommended)** | $30 | 98.1% |
| **Multi-Tier + Ollama** | $15 | 99% |

---

## 🔧 n8n Workflows

### Workflow 1: DeepSeek Agent Executor

**Import this JSON into n8n:**

```json
{
  "name": "DeepSeek Agent Executor",
  "nodes": [
    {
      "parameters": {
        "httpMethod": "POST",
        "path": "agent-execute",
        "responseMode": "responseNode",
        "options": {}
      },
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "position": [250, 300]
    },
    {
      "parameters": {
        "url": "https://api.deepseek.com/v1/chat/completions",
        "authentication": "genericCredentialType",
        "genericAuthType": "httpHeaderAuth",
        "sendHeaders": true,
        "headerParameters": {
          "parameters": [
            {
              "name": "Authorization",
              "value": "=Bearer {{$env.DEEPSEEK_API_KEY}}"
            }
          ]
        },
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "model",
              "value": "deepseek-chat"
            },
            {
              "name": "messages",
              "value": "={{$json.messages}}"
            },
            {
              "name": "temperature",
              "value": "={{$json.temperature || 0.7}}"
            }
          ]
        }
      },
      "name": "DeepSeek API",
      "type": "n8n-nodes-base.httpRequest",
      "position": [450, 300]
    },
    {
      "parameters": {
        "respondWith": "json",
        "responseBody": "={{$json}}"
      },
      "name": "Respond to Webhook",
      "type": "n8n-nodes-base.respondToWebhook",
      "position": [650, 300]
    }
  ],
  "connections": {
    "Webhook": {
      "main": [[{"node": "DeepSeek API", "type": "main", "index": 0}]]
    },
    "DeepSeek API": {
      "main": [[{"node": "Respond to Webhook", "type": "main", "index": 0}]]
    }
  }
}
```

### Workflow 2: Smart LLM Router

```json
{
  "name": "Smart LLM Router",
  "nodes": [
    {
      "parameters": {},
      "name": "Start",
      "type": "n8n-nodes-base.start",
      "position": [250, 300]
    },
    {
      "parameters": {
        "conditions": {
          "string": [
            {
              "value1": "={{$json.complexity}}",
              "operation": "equals",
              "value2": "simple"
            }
          ]
        }
      },
      "name": "Check Complexity",
      "type": "n8n-nodes-base.if",
      "position": [450, 300]
    },
    {
      "parameters": {
        "url": "http://ollama:11434/api/generate",
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "model",
              "value": "llama3.2"
            },
            {
              "name": "prompt",
              "value": "={{$json.prompt}}"
            }
          ]
        }
      },
      "name": "Ollama (Free)",
      "type": "n8n-nodes-base.httpRequest",
      "position": [650, 200]
    },
    {
      "parameters": {
        "url": "https://api.deepseek.com/v1/chat/completions",
        "authentication": "headerAuth",
        "sendBody": true
      },
      "name": "DeepSeek (Cheap)",
      "type": "n8n-nodes-base.httpRequest",
      "position": [650, 400]
    }
  ]
}
```

### Workflow 3: Wiki Vectorization

```json
{
  "name": "Wiki to Qdrant",
  "nodes": [
    {
      "parameters": {
        "filePath": "/workflows/wiki/*.md"
      },
      "name": "Read Wiki Files",
      "type": "n8n-nodes-base.readBinaryFiles",
      "position": [250, 300]
    },
    {
      "parameters": {
        "url": "https://api.openai.com/v1/embeddings",
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "model",
              "value": "text-embedding-3-small"
            },
            {
              "name": "input",
              "value": "={{$json.content}}"
            }
          ]
        }
      },
      "name": "Generate Embeddings",
      "type": "n8n-nodes-base.httpRequest",
      "position": [450, 300]
    },
    {
      "parameters": {
        "url": "http://qdrant:6333/collections/easyway-wiki/points",
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "points",
              "value": "={{$json.points}}"
            }
          ]
        }
      },
      "name": "Store in Qdrant",
      "type": "n8n-nodes-base.httpRequest",
      "position": [650, 300]
    }
  ]
}
```

---

## 📊 Database Migration for LLM Tracking

### SQL Migration: Add LLM Cost Tracking

Create file: `c:\old\EasyWayDataPortal\db\migrations\20260120_AGENT_MGMT_llm_tracking.sql`

```sql
-- =============================================
-- Migration: Add LLM Cost Tracking
-- Date: 2026-01-20
-- Description: Track LLM provider, model, tokens, and costs per execution
-- =============================================

USE [EasyWayDataPortal];
GO

-- Add LLM configuration to agent_registry
ALTER TABLE AGENT_MGMT.agent_registry
ADD 
    llm_provider NVARCHAR(50) DEFAULT 'deepseek',
    llm_model NVARCHAR(100) DEFAULT 'deepseek-chat',
    llm_temperature DECIMAL(3,2) DEFAULT 0.7,
    llm_max_tokens INT DEFAULT 4000,
    llm_cost_per_1m_input DECIMAL(10,4) DEFAULT 0.14,
    llm_cost_per_1m_output DECIMAL(10,4) DEFAULT 0.28;
GO

-- Add LLM tracking to agent_executions
ALTER TABLE AGENT_MGMT.agent_executions
ADD 
    llm_provider NVARCHAR(50),
    llm_model NVARCHAR(100),
    llm_input_tokens INT,
    llm_output_tokens INT,
    llm_cost_input_usd DECIMAL(10,6),
    llm_cost_output_usd DECIMAL(10,6),
    llm_cost_total_usd AS (ISNULL(llm_cost_input_usd, 0) + ISNULL(llm_cost_output_usd, 0)) PERSISTED;
GO

-- Create LLM cost summary view
CREATE OR ALTER VIEW AGENT_MGMT.vw_llm_cost_summary AS
SELECT 
    agent_id,
    llm_provider,
    llm_model,
    COUNT(*) as execution_count,
    SUM(llm_input_tokens) as total_input_tokens,
    SUM(llm_output_tokens) as total_output_tokens,
    SUM(llm_cost_total_usd) as total_cost_usd,
    AVG(llm_cost_total_usd) as avg_cost_per_execution,
    MIN(completed_at) as first_execution,
    MAX(completed_at) as last_execution
FROM AGENT_MGMT.agent_executions
WHERE completed_at >= DATEADD(day, -30, GETDATE())
  AND llm_provider IS NOT NULL
GROUP BY agent_id, llm_provider, llm_model;
GO

-- Create stored procedure to log LLM usage
CREATE OR ALTER PROCEDURE AGENT_MGMT.sp_log_llm_usage
    @execution_id UNIQUEIDENTIFIER,
    @llm_provider NVARCHAR(50),
    @llm_model NVARCHAR(100),
    @input_tokens INT,
    @output_tokens INT,
    @cost_per_1m_input DECIMAL(10,4),
    @cost_per_1m_output DECIMAL(10,4)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @cost_input DECIMAL(10,6) = (@input_tokens / 1000000.0) * @cost_per_1m_input;
    DECLARE @cost_output DECIMAL(10,6) = (@output_tokens / 1000000.0) * @cost_per_1m_output;
    
    UPDATE AGENT_MGMT.agent_executions
    SET 
        llm_provider = @llm_provider,
        llm_model = @llm_model,
        llm_input_tokens = @input_tokens,
        llm_output_tokens = @output_tokens,
        llm_cost_input_usd = @cost_input,
        llm_cost_output_usd = @cost_output
    WHERE execution_id = @execution_id;
    
    SELECT 
        execution_id,
        llm_provider,
        llm_model,
        llm_input_tokens,
        llm_output_tokens,
        llm_cost_total_usd
    FROM AGENT_MGMT.agent_executions
    WHERE execution_id = @execution_id;
END;
GO

-- Create daily cost summary view
CREATE OR ALTER VIEW AGENT_MGMT.vw_daily_llm_costs AS
SELECT 
    CAST(completed_at AS DATE) as execution_date,
    llm_provider,
    COUNT(*) as execution_count,
    SUM(llm_input_tokens) as total_input_tokens,
    SUM(llm_output_tokens) as total_output_tokens,
    SUM(llm_cost_total_usd) as total_cost_usd
FROM AGENT_MGMT.agent_executions
WHERE completed_at >= DATEADD(day, -90, GETDATE())
  AND llm_provider IS NOT NULL
GROUP BY CAST(completed_at AS DATE), llm_provider;
GO

-- Update default agents to use DeepSeek
UPDATE AGENT_MGMT.agent_registry
SET 
    llm_provider = 'deepseek',
    llm_model = 'deepseek-chat',
    llm_cost_per_1m_input = 0.14,
    llm_cost_per_1m_output = 0.28
WHERE classification IN ('arm', 'tool');

-- Strategic agents use GPT-4o-mini
UPDATE AGENT_MGMT.agent_registry
SET 
    llm_provider = 'openai',
    llm_model = 'gpt-4o-mini',
    llm_cost_per_1m_input = 0.15,
    llm_cost_per_1m_output = 0.60
WHERE classification = 'brain'
  AND agent_id NOT IN ('agent_gedi', 'agent_architect');

-- Only critical agents use GPT-4o
UPDATE AGENT_MGMT.agent_registry
SET 
    llm_provider = 'openai',
    llm_model = 'gpt-4o',
    llm_cost_per_1m_input = 2.50,
    llm_cost_per_1m_output = 10.00
WHERE agent_id IN ('agent_gedi', 'agent_architect');
GO

PRINT 'LLM tracking migration completed successfully.';
GO
```

---

## 🧪 Testing the Playground

### 1. Test DeepSeek via n8n

```bash
curl -X POST http://localhost:5678/webhook/agent-execute \
  -H 'Content-Type: application/json' \
  -d '{
    "messages": [
      {"role": "user", "content": "Explain EasyWay in one sentence"}
    ],
    "temperature": 0.7
  }'
```

### 2. Test Ollama

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2",
  "prompt": "What is agent governance?",
  "stream": false
}'
```

### 3. Test Qdrant

```bash
# Insert a test point
curl -X PUT http://localhost:6333/collections/easyway-wiki/points \
  -H 'Content-Type: application/json' \
  -d '{
    "points": [
      {
        "id": 1,
        "vector": [0.1, 0.2, 0.3, ...],
        "payload": {"text": "Test document"}
      }
    ]
  }'

# Search
curl -X POST http://localhost:6333/collections/easyway-wiki/points/search \
  -H 'Content-Type: application/json' \
  -d '{
    "vector": [0.1, 0.2, 0.3, ...],
    "limit": 5
  }'
```

### 4. Test Azure SQL Connection

```bash
sqlcmd -S your-server.database.windows.net \
  -d EasyWayDataPortal \
  -U your-user \
  -P your-password \
  -Q "SELECT COUNT(*) FROM AGENT_MGMT.agent_registry"
```

---

## 📈 Monitoring & Dashboards

### n8n Workflow: Cost Dashboard

Create a workflow that queries `AGENT_MGMT.vw_llm_cost_summary` and sends daily reports.

### Qdrant Dashboard

Access: `http://localhost:6333/dashboard`

### Docker Stats

```bash
# Real-time resource usage
docker stats

# Logs
docker compose logs -f n8n
docker compose logs -f qdrant
docker compose logs -f ollama
```

---

## 🛡️ Security Best Practices

### 1. Change Default Passwords

```bash
# Edit docker-compose.yml
nano docker-compose.yml

# Change:
# - N8N_BASIC_AUTH_PASSWORD
# - POSTGRES_PASSWORD
```

### 2. Use Azure Key Vault

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login
az login

# Get secrets
az keyvault secret show --name "deepseek-api-key" --vault-name "your-vault" --query value -o tsv
```

### 3. Restrict Firewall

```bash
# Only allow your IP to access Azure SQL
az sql server firewall-rule create \
  --resource-group your-rg \
  --server your-server \
  --name AllowPlaygroundVM \
  --start-ip-address YOUR_VM_IP \
  --end-ip-address YOUR_VM_IP
```

---

## 🔧 Troubleshooting

### n8n Won't Start

```bash
# Check logs
docker compose logs n8n

# Common fix: permissions
sudo chown -R 1000:1000 ~/easyway-playground/n8n_data
```

### Qdrant Connection Refused

```bash
# Check if running
docker compose ps qdrant

# Restart
docker compose restart qdrant
```

### Ollama Model Not Found

```bash
# List available models
docker exec easyway-ollama ollama list

# Pull model
docker exec easyway-ollama ollama pull llama3.2
```

### Azure SQL Connection Fails

```bash
# Test connectivity
nc -zv your-server.database.windows.net 1433

# Check firewall rules
az sql server firewall-rule list --resource-group your-rg --server your-server
```

---

## 📚 Next Steps

### 1. Clone EasyWay Repository

```bash
cd ~
git clone <your-repo-url> EasyWayDataPortal
cd EasyWayDataPortal
```

### 2. Apply Migrations

```bash
pwsh
cd ~/EasyWayDataPortal

# Apply LLM tracking migration
./db/scripts/apply-migration-simple.ps1 -MigrationFile "./db/migrations/20260120_AGENT_MGMT_llm_tracking.sql"
```

### 3. Import n8n Workflows

1. Access n8n: `http://localhost:5678`
2. Go to Workflows → Import from File
3. Import workflows from `~/easyway-playground/workflows/`

### 4. Start Experimenting!

- Create agent workflows in n8n
- Vectorize Wiki content to Qdrant
- Test different LLMs (Ollama vs DeepSeek vs GPT-4)
- Monitor costs in real-time

---

## 💰 Cost Optimization Tips

### 1. Use Ollama for Development

```bash
# Free, runs locally
# Good for: testing, development, simple queries
```

### 2. DeepSeek for Production

```bash
# $0.14/1M tokens
# Good for: 90% of agent tasks
```

### 3. GPT-4o-mini for Complex Tasks

```bash
# $0.15/1M tokens
# Good for: complex reasoning, critical decisions
```

### 4. GPT-4o Only for Strategic Agents

```bash
# $2.50/1M tokens
# Good for: agent_gedi, agent_architect only
```

### 5. Monitor Daily Costs

```sql
-- Query daily costs
SELECT * FROM AGENT_MGMT.vw_daily_llm_costs
ORDER BY execution_date DESC;

-- Set alerts if cost > threshold
```

---

## 🎯 Success Metrics

After setup, you should have:

- ✅ n8n running and accessible
- ✅ Qdrant with 2 collections created
- ✅ Ollama with at least 1 model pulled
- ✅ Azure SQL connection working
- ✅ DeepSeek API tested
- ✅ First workflow executed successfully
- ✅ Cost tracking enabled in database

---

## 📖 Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Qdrant Documentation](https://qdrant.tech/documentation/)
- [Ollama Models](https://ollama.com/library)
- [DeepSeek API](https://platform.deepseek.com/api-docs/)
- [EasyWay Wiki](../Wiki/EasyWayData.wiki/home.md)

---

**Created:** 2026-01-20  
**Updated:** 2026-01-20  
**Owner:** team-platform  
**Status:** Ready for deployment

---

## 🚀 Quick Reference

```bash
# Start playground
cd ~/easyway-playground
docker compose up -d

# Stop playground
docker compose down

# View logs
docker compose logs -f

# Restart service
docker compose restart n8n

# Access services
# n8n:    http://localhost:5678 (admin/easyway2026)
# Qdrant: http://localhost:6333/dashboard
# Ollama: http://localhost:11434
```

**Happy experimenting! 🎮**


