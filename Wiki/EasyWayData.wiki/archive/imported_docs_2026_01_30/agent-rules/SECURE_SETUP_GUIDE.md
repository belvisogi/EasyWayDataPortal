---
id: ew-archive-imported-docs-2026-01-30-agent-rules-secure-setup-guide
title: 🔒 Secure Setup - Environment Variables Migration
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
---
# 🔒 Secure Setup - Environment Variables Migration

**Purpose**: Migrare da `secrets.json` a **Environment Variables** per maggiore sicurezza  
**Time**: 10 minuti  
**Security Level**: ⭐⭐⭐⭐⭐ (Alto)

---

## ⚠️ Perché Migrare?

**Problemi secrets.json**:
- ❌ File in chiaro sul filesystem
- ❌ Rischio commit accidentale su Git
- ❌ Visibile a chiunque legga il file
- ❌ Difficile da rotare

**Vantaggi Environment Variables**:
- ✅ Non persistiti su file
- ✅ Isolati per sessione/utente
- ✅ Facili da rotare
- ✅ Best practice industry

---

## 📋 Migration Steps

### Step 1: Rigenera PAT ADO

**IMPORTANTE**: Il vecchio PAT è da considerare compromesso!

1. Vai su: `https://dev.azure.com/GeneraliHeadOfficeIT/_usersSettings/tokens`
2. Click su **"Revoke"** sul vecchio token (se presente)
3. Click **"New Token"**
4. Config:
   - Name: `Axet ADO Access`
   - Expiration: 90 giorni
   - Scopes: Work Items (Read), Code (Read), Test (Read), Build (Read)
5. Click **"Create"**
6. **COPIA IL NUOVO TOKEN** (solo visualizzazione!)

---

### Step 2: Setup Environment Variable

#### Opzione A: Session Variable (Temporaneo - ogni sessione)

```powershell
# Set per sessione corrente
$env:ADO_PAT = "NUOVO-PAT-QUI"

# Verifica
Write-Host "ADO_PAT set: $($env:ADO_PAT.Length) chars"
```

**Pro**: Veloce  
**Con**: Si perde al riavvio PowerShell

---

#### Opzione B: User Variable (Permanente - raccomandato)

**PowerShell**:
```powershell
# Set permanente per utente corrente
[System.Environment]::SetEnvironmentVariable('ADO_PAT', 'NUOVO-PAT-QUI', 'User')

# Riavvia PowerShell e verifica
$env:ADO_PAT
```

**GUI** (alternativa):
1. Windows → Cerca "environment variables"
2. Click "Edit environment variables for your account"
3. Click "New"
4. Variable name: `ADO_PAT`
5. Variable value: `NUOVO-PAT-QUI`
6. Click OK
7. **Riavvia PowerShell**

**Pro**: Persistente tra sessioni  
**Con**: Visibile a tutti i processi dell'utente

---

#### Opzione C: System Variable (Enterprise)

Per ambiente aziendale condiviso:

```powershell
# Richiede Admin
[System.Environment]::SetEnvironmentVariable('ADO_PAT', 'NUOVO-PAT-QUI', 'Machine')
```

---

### Step 3: Aggiorna Script per Usare Env Var

Gli script sono **già pronti**! Cercano automaticamente:
1. Prima: Parametro `-PAT`
2. Poi: `secrets.json` (ado_pat)
3. **Ultima**: `$env:ADO_PAT` ✅

**Nessuna modifica necessaria** - funziona out-of-the-box!

---

### Step 4: Test Nuovo Setup

```powershell
# Verifica env var settata
if ($env:ADO_PAT) {
    Write-Host "✅ ADO_PAT trovato (length: $($env:ADO_PAT.Length))" -ForegroundColor Green
} else {
    Write-Host "❌ ADO_PAT non settato!" -ForegroundColor Red
}

# Test script
pwsh Rules/scripts/get-ado-iterations.ps1
```

**Expected**: Script funziona senza errori!

---

### Step 5: Cleanup secrets.json (Opzionale)

**Dopo aver verificato che tutto funziona**:

```powershell
# Backup prima di rimuovere
Copy-Item Rules.Vault/config/secrets.json Rules.Vault/config/secrets.json.backup

# OPZIONE A: Rimuovi solo ado_pat (mantieni altri secrets)
# Edita manualmente secrets.json e rimuovi la riga ado_pat

# OPZIONE B: Rimuovi tutto il file (se non contiene altri secrets)
# Remove-Item Rules.Vault/config/secrets.json
```

**ATTENZIONE**: `secrets.json` contiene anche password per:
- synapse-prod
- snowflake-dev
- oracle-legacy
- snow-main

**Raccomandazione**: Rimuovi **solo** `ado_pat`, lascia il resto!

---

## 🔒 Security Best Practices

### 1. Rotation Policy
```powershell
# Rigenera PAT ogni 90 giorni
# Reminder in calendar: "Rotate ADO PAT"
```

### 2. Minimal Scopes
Solo Read scopes - mai Write/Delete

### 3. Monitoring
```powershell
# Check expiration
# ADO → User Settings → Tokens → Check expiration date
```

### 4. Revoke on Compromise
Se PAT compromesso:
1. Revoke immediatamente in ADO
2. Rigenera nuovo
3. Update env var

---

## 🛠️ Helper Script

**File**: `Rules/scripts/setup-ado-env.ps1`

```powershell
# Quick setup ADO environment variable

param(
    [string]$PAT
)

if (-not $PAT) {
    Write-Host "Usage: pwsh setup-ado-env.ps1 -PAT 'your-new-pat'" -ForegroundColor Yellow
    exit 1
}

# Set user-level env var
[System.Environment]::SetEnvironmentVariable('ADO_PAT', $PAT, 'User')

Write-Host "✅ ADO_PAT set successfully!" -ForegroundColor Green
Write-Host "⚠️  Restart PowerShell for changes to take effect" -ForegroundColor Yellow
Write-Host ""
Write-Host "Verify with: `$env:ADO_PAT" -ForegroundColor Cyan
```

**Usage**:
```powershell
pwsh Rules/scripts/setup-ado-env.ps1 -PAT "nuovo-pat-qui"
# Riavvia PowerShell
$env:ADO_PAT  # Verifica
```

---

## 📊 Comparison Matrix

| Metodo | Security | Persistenza | Setup | Raccomandato |
|--------|----------|-------------|-------|--------------|
| **secrets.json** | ⭐⭐ | ✅ | Facile | ❌ No |
| **Session Env Var** | ⭐⭐⭐ | ❌ | Veloce | Per test |
| **User Env Var** | ⭐⭐⭐⭐ | ✅ | Medio | ✅ **Sì** |
| **System Env Var** | ⭐⭐⭐⭐ | ✅ | Admin | Enterprise |
| **Azure Key Vault** | ⭐⭐⭐⭐⭐ | ✅ | Complesso | Production |

---

## ✅ Migration Checklist

- [ ] Rigenera nuovo PAT in ADO
- [ ] Revoca vecchio PAT
- [ ] Set `$env:ADO_PAT` (User level)
- [ ] Riavvia PowerShell
- [ ] Test: `pwsh get-ado-iterations.ps1`
- [ ] Verifica funzionamento
- [ ] Rimuovi `ado_pat` da `secrets.json`
- [ ] (Opzionale) Rimuovi anche `ado-main.pat`
- [ ] Set calendar reminder: Rotate PAT in 90 giorni

**Tempo totale**: ~10 minuti  
**Security gain**: Da ⭐⭐ a ⭐⭐⭐⭐

---

## 🔮 Advanced: Azure Key Vault (Future)

Per ambiente **production/enterprise**:

```powershell
# Retrieve from Key Vault
Connect-AzAccount
$PAT = Get-AzKeyVaultSecret -VaultName "MyVault" -Name "ADO-PAT" -AsPlainText

# Use in scripts
pwsh get-ado-iterations.ps1 -PAT $PAT
```

**Pro**: Massima sicurezza, audit trail, access control  
**Con**: Richiede Azure subscription, setup complesso

---

## 🆘 Troubleshooting

### "ADO_PAT not found"
```powershell
# Check se settato
Get-ChildItem Env:ADO_PAT

# Se vuoto, set manualmente
$env:ADO_PAT = "your-pat"
```

### "Still reading from secrets.json"
Script cerca in ordine:
1. `-PAT` parameter (priority)
2. `secrets.json` 
3. `$env:ADO_PAT`

Se `secrets.json` esiste, ha precedenza! Rimuovi `ado_pat` dal file.

### "Works in terminal, not in IDE"
IDE potrebbe non vedere env vars. Restart IDE dopo setup.

---

**Setup Time**: 10 min  
**Security**: ⭐⭐⭐⭐/5  
**Maintainability**: Eccellente  
**Status**: ✅ Production Ready


