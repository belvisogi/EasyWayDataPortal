# Database-First Template Generation

## 🎯 Concept

**Idea:** Il database schema è la **single source of truth**. 
Tutto il resto (API, forms, validation) viene **generato automaticamente**.

```
Database Schema (AGENT_MGMT)
    ↓
Auto-Generate
    ↓
├── REST API endpoints
├── TypeScript types
├── React forms
├── Validation schemas
├── Documentation
└── Test fixtures
```

---

## 🏗️ Architettura

### 1. **Schema Introspection**

```powershell
# Extract schema metadata
.\db-extract-schema.ps1 -Schema "AGENT_MGMT" -OutputFile "schema.json"
```

**Output: `schema.json`**
```json
{
  "schema": "AGENT_MGMT",
  "tables": [
    {
      "name": "agent_registry",
      "columns": [
        {
          "name": "agent_id",
          "type": "NVARCHAR(100)",
          "nullable": false,
          "primary_key": true
        },
        {
          "name": "agent_name",
          "type": "NVARCHAR(255)",
          "nullable": false
        },
        {
          "name": "is_enabled",
          "type": "BIT",
          "nullable": false,
          "default": 1
        }
      ],
      "indexes": [...],
      "foreign_keys": [...]
    }
  ],
  "stored_procedures": [...],
  "views": [...]
}
```

### 2. **Template Generators**

```
generators/
├── api-generator.js          → Express/Fastify endpoints
├── types-generator.js        → TypeScript interfaces
├── forms-generator.js        → React components
├── validation-generator.js   → Zod/Yup schemas
├── docs-generator.js         → OpenAPI/Swagger
└── tests-generator.js        → Jest test suites
```

### 3. **Generated Output**

```
generated/
├── api/
│   ├── agent-registry.routes.js
│   ├── agent-executions.routes.js
│   └── agent-metrics.routes.js
├── types/
│   ├── AgentRegistry.ts
│   ├── AgentExecution.ts
│   └── AgentMetrics.ts
├── forms/
│   ├── AgentRegistryForm.tsx
│   ├── AgentExecutionForm.tsx
│   └── AgentMetricsForm.tsx
├── validation/
│   ├── agent-registry.schema.js
│   └── agent-execution.schema.js
└── docs/
    └── openapi.yaml
```

---

## 💡 Esempi Concreti

### Esempio 1: API Endpoint Generation

**Input:** `agent_registry` table schema

**Generated:** `api/agent-registry.routes.js`
```javascript
// Auto-generated from AGENT_MGMT.agent_registry
import express from 'express';
import { pool } from '../db';

const router = express.Router();

// GET /api/agents - List all agents
router.get('/agents', async (req, res) => {
  try {
    const result = await pool.request()
      .query('SELECT * FROM AGENT_MGMT.agent_registry');
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/agents/:id - Get agent by ID
router.get('/agents/:id', async (req, res) => {
  try {
    const result = await pool.request()
      .input('agent_id', sql.NVarChar(100), req.params.id)
      .query('SELECT * FROM AGENT_MGMT.agent_registry WHERE agent_id = @agent_id');
    
    if (result.recordset.length === 0) {
      return res.status(404).json({ error: 'Agent not found' });
    }
    
    res.json(result.recordset[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/agents/:id/enable - Enable/disable agent
router.put('/agents/:id/enable', async (req, res) => {
  try {
    const { enabled } = req.body;
    
    await pool.request()
      .input('agent_id', sql.NVarChar(100), req.params.id)
      .input('is_enabled', sql.Bit, enabled)
      .execute('AGENT_MGMT.sp_toggle_agent_status');
    
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
```

### Esempio 2: TypeScript Types

**Input:** `agent_registry` table schema

**Generated:** `types/AgentRegistry.ts`
```typescript
// Auto-generated from AGENT_MGMT.agent_registry

export interface AgentRegistry {
  agent_id: string;              // NVARCHAR(100), PK
  agent_name: string;            // NVARCHAR(255)
  classification: string;        // NVARCHAR(50)
  role: string;                  // NVARCHAR(100)
  version: string;               // NVARCHAR(20)
  owner: string;                 // NVARCHAR(100)
  description: string | null;    // NVARCHAR(MAX), nullable
  is_enabled: boolean;           // BIT
  is_active: boolean;            // BIT
  llm_model: string | null;      // NVARCHAR(100), nullable
  llm_temperature: number | null; // DECIMAL(3,2), nullable
  context_limit_tokens: number | null; // INT, nullable
  created_at: Date;              // DATETIME2
  updated_at: Date;              // DATETIME2
  created_by: string;            // NVARCHAR(100)
  updated_by: string;            // NVARCHAR(100)
  last_sync_at: Date | null;     // DATETIME2, nullable
  manifest_hash: string | null;  // NVARCHAR(64), nullable
}

export interface CreateAgentRegistryDto {
  agent_id: string;
  agent_name: string;
  classification: string;
  role: string;
  version: string;
  owner: string;
  description?: string;
  is_enabled?: boolean;
  llm_model?: string;
  llm_temperature?: number;
  context_limit_tokens?: number;
}

export interface UpdateAgentRegistryDto {
  agent_name?: string;
  is_enabled?: boolean;
  llm_model?: string;
  llm_temperature?: number;
}
```

### Esempio 3: React Form Component

**Input:** `agent_registry` table schema

**Generated:** `forms/AgentRegistryForm.tsx`
```typescript
// Auto-generated from AGENT_MGMT.agent_registry
import React from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { agentRegistrySchema } from '../validation/agent-registry.schema';

interface AgentRegistryFormProps {
  initialData?: Partial<AgentRegistry>;
  onSubmit: (data: CreateAgentRegistryDto) => void;
}

export const AgentRegistryForm: React.FC<AgentRegistryFormProps> = ({
  initialData,
  onSubmit
}) => {
  const { register, handleSubmit, formState: { errors } } = useForm({
    resolver: zodResolver(agentRegistrySchema),
    defaultValues: initialData
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <div>
        <label>Agent ID</label>
        <input {...register('agent_id')} />
        {errors.agent_id && <span>{errors.agent_id.message}</span>}
      </div>

      <div>
        <label>Agent Name</label>
        <input {...register('agent_name')} />
        {errors.agent_name && <span>{errors.agent_name.message}</span>}
      </div>

      <div>
        <label>Classification</label>
        <select {...register('classification')}>
          <option value="brain">Brain</option>
          <option value="specialist">Specialist</option>
          <option value="worker">Worker</option>
        </select>
        {errors.classification && <span>{errors.classification.message}</span>}
      </div>

      <div>
        <label>Enabled</label>
        <input type="checkbox" {...register('is_enabled')} />
      </div>

      <button type="submit">Save</button>
    </form>
  );
};
```

### Esempio 4: Validation Schema

**Input:** `agent_registry` table schema

**Generated:** `validation/agent-registry.schema.js`
```javascript
// Auto-generated from AGENT_MGMT.agent_registry
import { z } from 'zod';

export const agentRegistrySchema = z.object({
  agent_id: z.string()
    .max(100, 'Agent ID must be 100 characters or less')
    .regex(/^[a-z_]+$/, 'Agent ID must be lowercase with underscores'),
  
  agent_name: z.string()
    .max(255, 'Agent name must be 255 characters or less')
    .min(1, 'Agent name is required'),
  
  classification: z.enum(['brain', 'specialist', 'worker']),
  
  role: z.string()
    .max(100, 'Role must be 100 characters or less'),
  
  version: z.string()
    .max(20, 'Version must be 20 characters or less')
    .regex(/^\d+\.\d+\.\d+$/, 'Version must be semver format'),
  
  owner: z.string()
    .max(100, 'Owner must be 100 characters or less'),
  
  description: z.string().optional(),
  
  is_enabled: z.boolean().default(true),
  
  llm_model: z.string().max(100).optional(),
  
  llm_temperature: z.number()
    .min(0)
    .max(2)
    .optional(),
  
  context_limit_tokens: z.number()
    .int()
    .positive()
    .optional()
});
```

---

## 🚀 Workflow

### Step 1: Schema Change
```sql
-- Add new column to agent_registry
ALTER TABLE AGENT_MGMT.agent_registry
ADD priority INT NULL;
```

### Step 2: Regenerate Templates
```powershell
# Extract updated schema
.\db-extract-schema.ps1 -Schema "AGENT_MGMT"

# Regenerate all templates
.\generate-templates.ps1 -Schema "AGENT_MGMT"
```

### Step 3: Auto-Updated
```
✅ API endpoint updated (new field in response)
✅ TypeScript types updated (priority: number | null)
✅ Form component updated (new input field)
✅ Validation schema updated (priority validation)
✅ Documentation updated (OpenAPI spec)
```

**Zero manual coding!** 🎉

---

## 🎯 Vantaggi

### 1. **Single Source of Truth**
- ✅ Database schema = definizione autoritativa
- ✅ Nessuna duplicazione
- ✅ Nessun drift tra DB e codice

### 2. **Velocità**
- ✅ Nuova tabella → API completa in secondi
- ✅ Cambio schema → Tutto aggiornato automaticamente
- ✅ Zero boilerplate manuale

### 3. **Consistenza**
- ✅ Validation rules derivate da DB constraints
- ✅ Types sempre sincronizzati
- ✅ Nessun errore di battitura

### 4. **Manutenibilità**
- ✅ Un solo posto da aggiornare (DB)
- ✅ Generazione ripetibile
- ✅ Facile refactoring

---

## 🔧 Implementazione

### Generator Script (PowerShell)

```powershell
# generate-templates.ps1
param(
    [string]$Schema = "AGENT_MGMT",
    [string]$OutputDir = "./generated"
)

# 1. Extract schema
Write-Host "📊 Extracting schema..."
.\db-extract-schema.ps1 -Schema $Schema -OutputFile "schema.json"

# 2. Generate API
Write-Host "🔌 Generating API endpoints..."
node generators/api-generator.js schema.json $OutputDir/api

# 3. Generate Types
Write-Host "📝 Generating TypeScript types..."
node generators/types-generator.js schema.json $OutputDir/types

# 4. Generate Forms
Write-Host "📋 Generating React forms..."
node generators/forms-generator.js schema.json $OutputDir/forms

# 5. Generate Validation
Write-Host "✅ Generating validation schemas..."
node generators/validation-generator.js schema.json $OutputDir/validation

# 6. Generate Docs
Write-Host "📚 Generating OpenAPI docs..."
node generators/docs-generator.js schema.json $OutputDir/docs

Write-Host "✅ Generation complete!"
```

---

## 💡 Estensioni Future

### 1. **Custom Annotations**
```sql
-- Add metadata to schema
EXEC sys.sp_addextendedproperty 
    @name = N'UI_Component', 
    @value = N'DatePicker',
    @level0type = N'SCHEMA', @level0name = 'AGENT_MGMT',
    @level1type = N'TABLE',  @level1name = 'agent_executions',
    @level2type = N'COLUMN', @level2name = 'started_at';
```

**Generator usa annotation:**
```typescript
// Auto-detects DatePicker from extended property
<DatePicker {...register('started_at')} />
```

### 2. **Relationship Detection**
```sql
-- FK detected automatically
FOREIGN KEY (agent_id) REFERENCES agent_registry(agent_id)
```

**Generator crea:**
```typescript
// Auto-generates dropdown with agent options
<Select {...register('agent_id')}>
  {agents.map(a => <option value={a.agent_id}>{a.agent_name}</option>)}
</Select>
```

### 3. **Business Logic Injection**
```javascript
// Custom hooks for business logic
export const useAgentRegistry = () => {
  // Generated CRUD
  const { data, create, update, delete } = useGeneratedCRUD('agent_registry');
  
  // Custom business logic
  const enableAgent = (id) => update(id, { is_enabled: true });
  const disableAgent = (id) => update(id, { is_enabled: false });
  
  return { data, enableAgent, disableAgent };
};
```

---

## ✅ Conclusione

**Database-First = Game Changer!** 🚀

**Cosa ottieni:**
- ✅ API completa auto-generata
- ✅ Frontend forms auto-generati
- ✅ Validation auto-generata
- ✅ Types sempre sincronizzati
- ✅ Zero boilerplate manuale

**Prossimo step:**
Vuoi che creiamo il primo generator (API o Types)? 🎯
