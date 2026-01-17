# ADO Configuration Setup Guide

**Quick Start**: 5 minuti per configurare l'accesso Azure DevOps

---

## 📋 Step-by-Step Setup

### Step 1: Crea `connections.json`

**Path**: `Rules.Vault/config/connections.json`

```json
{
  "ado": {
    "organization": "GeneraliHeadOfficeIT",
    "project": "ADA Project - Data Strategy",
    "team": "ADA Project - Data Strategy Team",
    "repository": "ADA"
  }
}
```

**Come trovare i valori**:
- `organization`: URL ADO → `https://dev.azure.com/[ORGANIZATION]`
- `project`: Nome del progetto in ADO
- `team`: Nome team (spesso = project name)
- `repository`: Nome repo Git (opzionale)

---

### Step 2: Crea `secrets.json`

**Path**: `Rules.Vault/config/secrets.json`

```json
{
  "ado_pat": "YOUR_PERSONAL_ACCESS_TOKEN_HERE"
}
```

**Come ottenere PAT**:
1. Vai su: `https://dev.azure.com/YOUR_ORG/_usersSettings/tokens`
2. Click "New Token"
3. Nome: "Axet ADO Access"
4. Scopes richiesti:
   - ✅ `Work Items` (Read)
   - ✅ `Code` (Read) - per PR
   - ✅ `Test Management` (Read) - per test plans
   - ✅ `Build` (Read) - per pipelines
5. Expiration: 90 giorni (o custom)
6. Click "Create"
7. **COPIA IL TOKEN** (non sarà più visibile!)
8. Incolla in `secrets.json`

---

### Step 3: Verifica Setup

**Command**:
```powershell
pwsh Rules/scripts/get-ado-iterations.ps1
```

**Expected Output**:
```
🔍 Querying ADO Iterations...
  Organization: GeneraliHeadOfficeIT
  Project: ADA Project - Data Strategy
  Team: ADA Project - Data Strategy Team

📊 Iterations Found: X
...
```

**Se vedi errori**:
- `Organization, Project, or PAT missing` → Verifica connections.json e secrets.json
- `401 Unauthorized` → PAT scaduto o scopes insufficienti
- `404 Not Found` → Organization/Project name errato

---

## 🚀 Quick Test Commands

Una volta configurato, prova:

```powershell
# Lista sprint
pwsh Rules/scripts/get-ado-iterations.ps1

# Sprint attivo
pwsh Rules/scripts/get-ado-iterations.ps1 -OnlyActive

# Test plans
pwsh Rules/scripts/get-ado-testplans.ps1 -ListPlans

# Pull requests
pwsh Rules/scripts/get-ado-pullrequests.ps1 -Status active
```

---

## 📁 File Structure

```
Rules.Vault/
└── config/
    ├── connections.json          ← Organization, Project, Team
    ├── connections.json.template ← Template per riferimento
    ├── secrets.json              ← PAT (GITIGNORE!)
    └── secrets.json.template     ← Template per riferimento
```

**IMPORTANTE**: 
- ✅ `connections.json` può essere committato (no secrets)
- ❌ `secrets.json` deve essere in `.gitignore` (contiene PAT!)

---

## 🔐 Security Best Practices

1. **Non committare secrets.json**
   ```gitignore
   # .gitignore
   Rules.Vault/config/secrets.json
   ```

2. **Usa PAT con scopes minimi**
   - Solo Read scopes
   - No Write/Delete
   - Expiration ragionevole (90 giorni)

3. **Rigenera PAT periodicamente**
   - Ogni 3-6 mesi
   - Se compromesso

4. **Alternative a secrets.json**
   - Environment variable: `$env:ADO_PAT`
   - Azure Key Vault (enterprise)
   - Windows Credential Manager

---

## 🛠️ Troubleshooting

### Error: "Missing required parameters"

**Causa**: `connections.json` o `secrets.json` non trovati

**Fix**:
```powershell
# Check file esistono
Test-Path Rules.Vault/config/connections.json
Test-Path Rules.Vault/config/secrets.json

# Se no, copia da template
Copy-Item connections.json.template connections.json
Copy-Item secrets.json.template secrets.json

# Poi edita con valori reali
```

### Error: "401 Unauthorized"

**Causa**: PAT invalido o scaduto

**Fix**:
1. Verifica PAT corretto in `secrets.json`
2. Controlla expiration in ADO
3. Rigenera PAT se necessario

### Error: "404 Not Found"

**Causa**: Organization/Project name errato

**Fix**:
1. Verifica URL ADO: `https://dev.azure.com/[ORG]/[PROJECT]`
2. Copia esattamente i nomi (case-sensitive!)
3. Check spazi e caratteri speciali

---

## 📝 Example Real Config

**connections.json** (ADA Project):
```json
{
  "ado": {
    "organization": "GeneraliHeadOfficeIT",
    "project": "ADA Project - Data Strategy",
    "team": "ADA Project - Data Strategy Team",
    "repository": "ADA"
  }
}
```

**secrets.json**:
```json
{
  "ado_pat": "aabbccddee1122334455..."
}
```

---

## ✅ Checklist Setup

- [ ] Creato `Rules.Vault/config/` directory
- [ ] Creato `connections.json` con org/project
- [ ] Ottenuto PAT da ADO User Settings
- [ ] Creato `secrets.json` con PAT
- [ ] Aggiunto `secrets.json` a `.gitignore`
- [ ] Testato: `pwsh get-ado-iterations.ps1`
- [ ] Verificato output corretto

**Tempo totale**: ~5 minuti

---

## 🎯 Post-Setup

Dopo setup, puoi usare:
- 39 recipes sprint/deploy/backlog
- 9 recipes test/PR
- Tutti gli script ADO senza parametri manuali

**L'AI riconoscerà automaticamente** richieste tipo:
- "lista sprint"
- "pull request aperti"
- "test runs ultimi giorni"
- "dammi i deploy 2025"

Tutto funzionerà **senza dover passare parametri**! 🚀

---

**Setup Time**: 5 min  
**One-Time**: Yes  
**Benefits**: Tutti gli script ADO funzionanti
