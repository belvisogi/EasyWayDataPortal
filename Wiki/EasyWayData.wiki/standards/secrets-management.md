---
owner: team-security
tags: ['layer/security', 'domain/devops']
status: active
title: Standard Gestione Segreti (Azure Key Vault)
summary: Linee guida per la gestione sicura dei segreti tramite Azure Key Vault e naming convention.
updated: 2026-01-16
---

# Standard di Gestione Segreti (Azure Key Vault)

## 1. Strategia Environment (Isolamento)
Per evitare confusione e rischi di sicurezza, la Best Practice Azure è **"Un Key Vault per Environment"**.
Questo permette di usare gli stessi nomi per i segreti (es. `DB-PASS`) senza doverli prefissare con l'ambiente (es. `DEV-DB-PASS`), semplificando il codice.

| Environment | Pattern Nome Key Vault | Esempio |
| :--- | :--- | :--- |
| **Development** | `kv-[project]-dev` | `kv-easyway-dev` |
| **Staging/UAT** | `kv-[project]-stg` | `kv-easyway-stg` |
| **Production** | `kv-[project]-prod` | `kv-easyway-prod` |

## 2. Naming Convention (Secret Names)
Azure Key Vault accetta solo caratteri alfanumerici e trattini (`-`).
Le Variabili d'Ambiente usano solitamente underscore (`_`).

**Standard**: Usare `UPPER-KEBAB-CASE` su Key Vault.
Il codice (`secrets.ts`) convertirà automaticamente i trattini in underscore.

| Env Variable (Node.js) | Key Vault Secret Name | Esempio |
| :--- | :--- | :--- |
| `DB_PASS` | `DB-PASS` | `MySecretPass` |
| `AUTH_CLIENT_ID` | `AUTH-CLIENT-ID` | `0000-1111-2222` |
| `API_KEY` | `API-KEY` | `xyz123` |

## 3. Gestione Accessi (RBAC)
- **Dev Vault**: Accesso Lettura/Scrittura per i Developer.
- **Prod Vault**: Accesso **SOLO** alla Pipeline CI/CD e all'Identità Gestita dell'App (Managed Identity). Nessun umano dovrebbe leggere i segreti di prod.

## 4. Automazione
Usare lo script `scripts/sync-env-to-akv.ps1` per popolare massivamente i segreti partendo da un file locale `.env`.

```powershell
# Esempio: Popolare Ambiente DEV
./scripts/sync-env-to-akv.ps1 -EnvFile ".env.local" -VaultName "kv-easyway-dev"
```

