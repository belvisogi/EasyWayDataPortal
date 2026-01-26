---
id: ew-06-frontend-architecture
title: 06 Frontend Architecture
summary: Architettura Frontend (Next.js), integrazione Backend/API, gestione Auth/ACL e Logging strutturato.
status: active
owner: team-docs
created: '2025-01-01'
updated: '2026-01-16'
tags: [domain/frontend, layer/spec, audience/dev, privacy/internal, language/it, architecture]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: Dettagliare componenti UI.
---

[Home](../../../docs/project-root/DEVELOPER_START_HERE.md) > [[domains/frontend|frontend]] > [[Layer - Spec|Spec]]

# EasyWay Data Portal - Frontend Architecture & Integration

## Obiettivo
Definire l'architettura frontend di EasyWay Data Portal in modo coerente con:
- la struttura backend `easyway-portal-api`
- le policy multi-tenant, ACL e sicurezza definite nel progetto
- le tabelle logiche e fisiche del database (`EasyWay DataPortal - DB`)
- la roadmap AI e self-service dell'utente finale

## Struttura Progetto Frontend (Next.js)

```text
/app
/dashboard -> Dashboard overview globale
/upload -> Modulo caricamento file
/enrichment -> Stato arricchimenti e controlli qualità
/notifications -> Visualizzazione notifiche per utente/tenant
/workspace -> Area self-service e AI Assistant
/components
/ui -> Componenti riutilizzabili (Button, Card, Table)
/layout -> Sidebar, Topbar, Breadcrumb
/lib
/api -> Connettori API per ogni controller
/auth -> Gestione token, ACL, context utente
/acl -> Logica permessi per visualizzazione moduli
/utils
/logger.ts -> Audit azioni frontend verso backend
```sql

---

## Mappatura Controller Backend -> Frontend UI

| Backend Controller (`src/controllers`) | Frontend Sezione `/app/` | API Connector (`lib/api/...`) |
|----------------------------------------|---------------------------|-------------------------------|
| `usersController.ts`                   | `/users` (gestione profili) | `lib/api/users.ts` |
| `notificationsController.ts`           | `/notifications` | `lib/api/notifications.ts` |
| `onboardingController.ts`              | `/workspace` | `lib/api/onboarding.ts` |
| `brandingController.ts`                | globale (topbar, logo, tema) | `lib/api/branding.ts` |
| `configController.ts`                  | `/settings` (admin only) | `lib/api/config.ts` |
| `healthController.ts`                  | invisibile, usato per checkup | `lib/api/health.ts` |

---

## Multi-Tenant e ACL (Access Control Layer)

Tutte le richieste frontend includono nel contesto:
- `tenant_id`
- `user_id` (formato `CDI00000001000`)
- `profile` ACL (es. `can_upload`, `can_view_enrichment`, `can_manage_users`)

Queste informazioni sono ottenute dopo login via API e salvate in context globale React (es. `TenantContext`, `AuthContext`).

---

## Sicurezza & Logging

Ogni azione utente frontend:
- viene loggata con chiamata POST a `api/audit/log`
- include i metadati:
  - `event_type` (es: `UPLOAD_FILE`, `AI_DASHBOARD_REQUEST`)
  - `user_id`, `tenant_id`
  - `timestamp`
- supporta masking dinamico se il dataset o colonna è marcata come `MASKED` nel backend (`PORTAL.MASKING_METADATA`)

---

## AI Dashboard Assistant

La sezione `/workspace` integra:
- Textarea per richieste tipo "Mostrami i report con successo <95% negli ultimi 3 mesi"
- Backend AI (OpenAI / Azure OpenAI) con API POST a `/api/assistant/ask`
- Visualizzazione dinamica dei widget suggeriti
- Salvataggio query/risposta per audit

---

## Esempio ACL e Componente Condizionale

```tsx
{user?.profile?.can_upload && (
  <UploadArea />
)}
```sql

## Domande a cui risponde
1. Qual è la struttura del progetto Next.js Frontend?
2. Come viene gestito il contesto utente (Tenant/ACL)?
3. Come funziona l'audit logging dal Frontend?




