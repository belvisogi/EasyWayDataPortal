---
id: ew-api-ext
title: API Esterne - Integrazione
summary: Integrazioni verso API esterne (lookup, tabella integrazioni, policy sicurezza, best practice).
status: active
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [domain/control-plane, layer/reference, audience/dev, privacy/internal, language/it, integration, external-api]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---

[[start-here|Home]] > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Reference|Reference]]

# Integrazione API Esterne - EasyWay Data Portal

## Lookup - Integrazione API Esterne

| Cosa vuoi | Cosa devi scrivere | Dammi il .md | Stato |
|-----------|--------------------|--------------|-------|
| Tabella integrazioni API | Dammi tabella integrazioni API | Dammi il .md tabella integrazioni API | IN BOZZA |
| Dettaglio API Microsoft Graph | Dammi dettaglio API Microsoft Graph | Dammi il .md dettaglio API Microsoft Graph | IN BOZZA |
| Dettaglio API Shopify | Dammi dettaglio API Shopify | Dammi il .md dettaglio API Shopify | IN BOZZA |
| Dettaglio API Fatture in Cloud | Dammi dettaglio API Fatture in Cloud | Dammi il .md dettaglio API Fatture in Cloud | IN BOZZA |
| Dettaglio API Amazon | Dammi dettaglio API Amazon | Dammi il .md dettaglio API Amazon | IN BOZZA |
| Policy sicurezza/gestione key | Dammi policy API key security | Dammi il .md policy API key security | IN BOZZA |
| Flusso esempio chiamata esterna | Dammi esempio flusso chiamata API esterna | Dammi il .md esempio flusso chiamata API esterna | IN BOZZA |

## Tabella Integrazioni API Esterne

| Servizio/API | Scopo integrazione | Endpoint principali | Autenticazione | Frequenza / Modalità | Note operative |
|--------------|--------------------|---------------------|----------------|----------------------|----------------|
| Microsoft Graph API | Identity, Teams, Calendari, utenti, email | /me, /users, /groups, /mail | OAuth2, Entra ID | Real-time, scheduled | Gestione deleghe, permessi granulari |
| Shopify | Sync ordini, prodotti, clienti | /orders, /products, /customers | OAuth2, API Key | Batch, webhooks | Gestione multi-shop, mapping tenant |
| Fatture in Cloud | Import/export fatture, clienti, documenti | /invoices, /clients, /products | OAuth2, API Key | Batch, schedulato | Gestione errori e validazione dati |
| Amazon Seller API | Sync ordini, stock, prezzi | /orders, /inventory, /products | OAuth2, AWS IAM | Batch, polling | Attenzione limiti rate API |
| Altri SaaS | CRM, analytics, storage, ecc. | Vari | Vari | Da valutare | Architettura plug-in, versioning API |

---

## Policy Sicurezza & Gestione Key/API

- Gestione centralizzata key e segreti: tutte le API Key/token OAuth sono salvate in Azure Key Vault, mai in chiaro nel codice o config file.
- Token rotation: pianificare la rotazione periodica dei token/key secondo policy vendor.
- Scope e permessi minimi: ogni integrazione riceve solo i permessi realmente necessari (principio di least privilege).
- Audit e logging: tutte le chiamate a API esterne vanno loggate con dettaglio (successo, errore, payload minimale).
- Gestione errori e fallback: implementare retry, alerting e circuit breaker su errori ripetuti o API non disponibili.

---

## Best Practice Integrazione API Esterne

- Architettura plug-in/microservizio dedicato: ogni integrazione vive in un proprio microservizio/container, gestibile e scalabile indipendentemente.
- Versioning e backward compatibility: adattare logica e mapping dati per gestire evoluzioni API vendor senza rompere i flussi esistenti.
- Gestione mapping tenant: ogni chiamata esterna è sempre associata a uno specifico tenant_id, per evitare mix dati tra clienti.
- Mock e sandbox: testare sempre su ambienti sandbox/dev forniti dai vendor prima di passare in produzione.

## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?



