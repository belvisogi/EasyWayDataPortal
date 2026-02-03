---
id: ew-architecture-appliance-model
title: The Sovereign Appliance Model (Il Modello Mac Mini) 📦
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
# The Sovereign Appliance Model (Il Modello Mac Mini) 📦

> **"Smetti di affittare l'intelligenza. Comprala."**

## 1. The Concept
EasyWay non è venduto come un servizio SaaS (Software as a Service) dove i dati vivono "nel cloud di qualcun altro".
È venduto come una **Appliance**: una "scatola" (virtuale o fisica) che il cliente possiede.

Simile a comprare un **Mac Mini**:
*   Paghi una volta (o a canone hardware).
*   La scatola è tua.
*   I dati restano nella scatola.
*   Il software è pre-installato e standardizzato.

## 2. The Dual Face Architecture (Giano Bifronte) 🎭
Ogni istanza di EasyWay serve due scopi contemporaneamente, utilizzando lo stesso hardware ma esponendo interfacce diverse.

### 🌍 A. Public Face (Marketing Website)
*   **Ruolo**: Vetrina pubblica dell'azienda.
*   **Accesso**: `https://azienda.com/` (Libero).
*   **Contenuto**: Home Page, Landing Pages, Form di contatto (`demo.html`).
*   **Valore**: Sostituisce i costi di hosting web (Wix, Wordpress). È "Gratis" col server.

### 🔒 B. Private Face (Sovereign Intranet)
*   **Ruolo**: Il cervello operativo.
*   **Accesso**: `https://azienda.com/app/` o `/memory.html` (Protetto da Login).
*   **Contenuto**:
    *   **Memory**: Esplorazione RAG vettoriale.
    *   **Dashboard**: KPI e statistiche.
    *   **N8N**: Automazioni e flussi di lavoro.
*   **Valore**: Sostituisce SaaS costosi (Zapier, Notion Enterprise, ChatGPT Team).

## 3. Tech Stack: The Split Router 🚦
Tecnicamente, questo è realizzato tramite **Traefik** in modalità Split-Router:

```yaml
# Router 1: Public (No Auth)
- "traefik.http.routers.frontend-public.rule=Path(`/`) || Path(`/demo.html`)"

# Router 2: Private (Basic Auth / OIDC)
- "traefik.http.routers.frontend-private.rule=PathPrefix(`/memory.html`) || PathPrefix(`/n8n`)"
- "traefik.http.routers.frontend-private.middlewares=auth"
```

## 4. Fleet Standardization (1 a 100) ⚓
Per permettere a EasyWay Inc. di gestire 100 o 1000 Appliance diverse:
1.  **Immagini Immutabili**: Tutti i clienti usano GLI STESSI container Docker.
2.  **Configurazione .env**: Le differenze (Nome Azienda, Colori, Password) sono solo variabili d'ambiente.
3.  **Zero Custom Code**: Non modifichiamo il PHP/code del cliente. Aggiorniamo il container.

Questo garantisce che un aggiornamento di sicurezza possa essere pushato su 1000 server in un click.


