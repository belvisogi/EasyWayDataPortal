# 🌐 MCP Protocol Specification - Axet Implementation

**Version**: 1.0  
**Date**: 2026-01-13  
**Status**: Implemented

---

## 📋 Overview

Axet implements an **MCP-compatible protocol** for modular server architecture, allowing independent deployment, versioning, and lifecycle management of capability servers.

---

## 🏗️ Server Structure

Every server MUST follow this structure:

```
servers/<server-name>/
├─ manifest.json       # Server metadata (REQUIRED)
├─ tools.json          # Tool definitions (REQUIRED)
├─ resources.json      # Resource definitions (OPTIONAL)
└─ handler.ps1         # Tool executor (REQUIRED)
```

---

## 📄 manifest.json Specification

```json
{
  "name": "string (required)",
  "version": "semver (required)",
  "description": "string (required)",
  "type": "mcp-compatible (required)",
  "category": "string (optional)",
  "domain": "string (optional)",
  
  "capabilities": {
    "tools": ["array of tool names"],
    "resources": ["array of resource names"]
  },
  
  "dependencies": {
    "required": ["environment variables needed"],
    "optional": ["optional env vars"]
  },
  
  "endpoints": {
    "tools": "tools.json",
    "resources": "resources.json",
    "handler": "handler.ps1"
  },
  
  "metadata": {
    "author": "string",
    "license": "string",
    "repository": "url (optional)",
    "documentation": "url (optional)"
  }
}
```

---

## 🔧 tools.json Specification

```json
{
  "tools": [
    {
      "name": "string (required, unique)",
      "description": "string (required)",
      
      "inputSchema": {
        "type": "object",
        "properties": { ... },
        "required": ["array of required fields"]
      },
      
      "outputSchema": {
        "type": "object",
        "properties": { ... }
      },
      
      "execution": {
        "handler": "function name in handler.ps1",
        "safe": "boolean",
        "autoExecute": "boolean",
        "estimatedTokens": "integer",
        "avgDurationMs": "integer"
      },
      
      "examples": [
        { "param1": "value1" }
      ]
    }
  ]
}
```

---

## 🔌 ServerClient Protocol

### 1. Discovery
```javascript
const client = new ServerClient('./servers');
const available = client.discoverServers();
// Returns: [{ name, version, description, capabilities }]
```

### 2. Connection
```javascript
const manifest = client.connect('ado-server');
// Loads manifest + tools + resources
```

### 3. Tool Invocation
```javascript
const result = await client.callTool('ado-server', 'pbi.get', { id: 184797 });
// Returns: { success, data, duration, server, tool }
```

### 4. Disconnection
```javascript
client.disconnect('ado-server');
// Or: client.disconnectAll();
```

---

## ✅ Compliance Checklist

Server is MCP-compliant if:
- [ ] manifest.json present with all required fields
- [ ] tools.json defines all capabilities.tools
- [ ] handler.ps1 implements all tool handlers
- [ ] Input schemas valid JSON Schema
- [ ] Handler accepts `-Function` and `-Params` args
- [ ] Handler returns valid JSON
- [ ] Dependencies documented
- [ ] Safe/unsafe tools correctly marked

---

## 🔐 Security Model

### Safe Tools
- Read-only operations
- No state mutation
- Auto-executable
- Examples: pbi.get, validate, review

### Unsafe Tools
- Write operations
- State changes
- Require approval
- Examples: sync, normalize, create

---

## 📊 Tool Execution Flow

```
Client Request
  ↓
1. Validate params against inputSchema
  ↓
2. Check if server connected
  ↓
3. Find tool in tools.json
  ↓
4. Execute handler:
   pwsh handler.ps1 -Function <handler> -Params <json>
  ↓
5. Parse JSON output
  ↓
6. Return result + metadata
```

---

## 🎯 Handler Implementation Pattern

```powershell
# handler.ps1
param(
    [string]$Function,
    [string]$Params
)

# Parse params
$paramsObj = $Params | ConvertFrom-Json

# Route to function
switch ($Function) {
    "Get-PBI" {
        $result = Get-WorkItem -Id $paramsObj.id
        $result | ConvertTo-Json -Depth 10
    }
    "Export-WorkItems" {
        $result = Export-Items -Query $paramsObj.query
        $result | ConvertTo-Json
    }
}
```

---

## 📈 Versioning Strategy

### Semantic Versioning
```
MAJOR.MINOR.PATCH

MAJOR: Breaking changes to tools/schemas
MINOR: New tools, backward compatible
PATCH: Bug fixes, no API changes
```

### Example
```
ado-server v1.2.3
  v1.x.x → Stable API
  v2.x.x → New API (e.g., tools renamed)
```

---

## 🔄 Backward Compatibility

### Server Upgrades
1. Old clients can connect to new servers (minor/patch)
2. New clients should handle old servers gracefully
3. Breaking changes require MAJOR version bump

### Tool Deprecation
```json
{
  "name": "old-tool",
  "deprecated": true,
  "deprecatedSince": "1.5.0",
  "replacedBy": "new-tool",
  "description": "..."
}
```

---

## 🌟 Axet Implementation

### Current Servers
1. **ado-server** v1.0.0
   - 6 tools (pbi.get, export, pipeline.*)
   - 4 resources

2. **docs-server** v1.0.0
   - 4 tools (validate, check, sync, report)
   - 3 resources

3. **wiki-server** v1.0.0
   - 3 tools (review, normalize, glossary-check)
   - 2 resources

---

**Compliance**: ✅ 100% MCP-compatible  
**Status**: Production ready
