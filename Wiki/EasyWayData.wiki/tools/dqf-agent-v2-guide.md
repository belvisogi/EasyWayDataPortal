---
type: guide
status: active
tags:
  - layer/tool
  - domain/ai
  - domain/dq
version: 2.0.0
created: 2026-02-04
parent: standards/agent-hybrid-architecture
---

# DQF Agent V2 - User Guide

## Overview

**DQF Agent V2** is a Hybrid Agent that helps maintain documentation quality through intelligent validation, analysis, and suggestions.

**Key Features**:
- 🧠 Understands natural language (Italian/English)
- 💭 Remembers conversation history
- 🧭 Intelligently routes between RAG/TOOL/CHAT modes
- 📊 Validates metadata compliance
- 🔗 Suggests cross-links and tags

---

## Quick Start

### Installation

DQF Agent V2 is already installed in the project. No setup required!

### Basic Usage

```powershell
# Navigate to project root
cd c:\old\EasyWayDataPortal

# Run a command
scripts\pwsh\dqf-agent-v2.ps1 "Valida i file nella cartella agents"
```

---

## Command Examples

### 1. Validate Metadata

Check for missing required fields:

```powershell
dqf-agent-v2.ps1 "Valida i file nella cartella Wiki/EasyWayData.wiki/agents"
```

**Output**:
```
🧠 Parsing intent...
   Intent Type: validate
   
🧭 Router analyzing intent...
   Mode: TOOL
   Confidence: 95%
   
📤 Agent Response:
Found 4 files.

❌ agent-example.md
   Missing: status

✅ All other files are compliant!
```

---

### 2. Analyze Files

Get AI-powered analysis and suggestions:

```powershell
dqf-agent-v2.ps1 "Analizza i primi 3 file e suggerisci miglioramenti"
```

**Router Decision**: RAG mode (uses AI with document context)

---

### 3. Ask About Documentation

Query the knowledge base:

```powershell
dqf-agent-v2.ps1 "Cosa dice la documentazione sui tag obbligatori?"
dqf-agent-v2.ps1 "Secondo i miei documenti, quali metadata sono richiesti?"
```

**Router Decision**: RAG mode (document-based response)

---

### 4. Request Actions

Execute fixes or updates:

```powershell
dqf-agent-v2.ps1 "Correggi i metadata mancanti"
dqf-agent-v2.ps1 "Aggiorna i file con i tag corretti"
```

**Router Decision**: TOOL mode (action execution)

---

### 5. Conversational Mode

Ask general questions:

```powershell
dqf-agent-v2.ps1 "Come posso migliorare la qualità della documentazione?"
dqf-agent-v2.ps1 "Quali sono le best practice per i tag?"
```

**Router Decision**: CHAT mode (conversational AI)

---

## How It Works

### 1. Interpreter

Parses your natural language input:
- Detects language (IT/EN)
- Identifies intent type
- Extracts constraints (path, limit, etc.)

### 2. Router

Decides how to respond:
- **TOOL**: For validation, fixes, actions
- **RAG**: For document queries, analysis
- **CHAT**: For general conversation
- **WORKFLOW**: For multi-step processes

### 3. Memory

Remembers your conversations:
- Recent turns for context
- User preferences
- Event history for improvement

---

## Advanced Usage

### Session Management

Each terminal session gets a unique ID. To continue a previous session:

```powershell
$env:DQF_SESSION_ID = "your-session-id"
dqf-agent-v2.ps1 "Continue from where we left off"
```

### Check Memory

View conversation history:

```powershell
sqlite3 packages/dqf-agent/memory.db "SELECT * FROM conversations LIMIT 5;"
```

### Clear Memory

Reset conversation history:

```powershell
Remove-Item packages/dqf-agent/memory.db
```

---

## Troubleshooting

### "AI connection failed"

**Cause**: Ollama tunnel is down  
**Fix**: Restart tunnel
```powershell
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" -L 11434:localhost:11434 -N ubuntu@80.225.86.168
```

### "Path not found"

**Cause**: Relative path resolution  
**Fix**: Use absolute paths or run from project root

### Slow responses

**Cause**: DeepSeek-R1 reasoning takes time  
**Expected**: 5-30 seconds for complex queries

---

## Intent Types Reference

| Intent | Trigger Keywords | Router Mode | Example |
|--------|-----------------|-------------|---------|
| `validate` | valida, check, verifica | TOOL | "Valida i file" |
| `analyze` | analizza, analyze, suggerisci | RAG | "Analizza i file" |
| `fix` | correggi, fix, ripara | TOOL | "Correggi i metadata" |
| `link` | collega, link, wikilink | RAG | "Suggerisci collegamenti" |
| `chat` | (default) | CHAT/RAG/TOOL* | "Come posso..." |

*Chat intent is routed based on keywords in the message

---

## Feedback & Improvement

DQF Agent V2 learns from usage. To help improve it:

1. **Use it regularly**: More usage = better routing
2. **Report issues**: Note commands that fail
3. **Suggest intents**: What's missing?

**Feedback Log**: Create `validation-log.md` with your observations

---

## Related Documentation

- [[standards/agent-hybrid-architecture]] - Architecture details
- [[standards/agent-portability-standard]] - LLM model selection
- [[standards/tag-taxonomy]] - Metadata standards

---

## Version History

### v2.0.0 (2026-02-04)
- ✨ New: Hybrid Agent architecture
- ✨ New: Interpreter module
- ✨ New: Memory Manager
- ✨ New: Router with intelligent mode selection
- 🔧 Improved: Natural language understanding
- 🔧 Improved: Context awareness

### v1.0.0 (Previous)
- Basic PowerShell script
- Simple validation logic
- No memory or routing
