---
id: ew-archive-imported-docs-2026-01-30-archive-diaries-diario-di-bordo-20260127
title: 📔 DIARIO DI BORDO - 2026-01-27
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
# 📔 DIARIO DI BORDO - 2026-01-27

> **"Averlo fatto è una figata."** - *Commander* (03:56)

## 🎯 Obiettivo del Giorno
Trasformare l'Agente da uno "script monolitico" a un sistema **"Portable Brain"** pronto per l'orchestrazione (n8n) e distribuibile ovunque (Oracle, Hetzner, Local).

## 🏆 Risultati Raggiunti

### 1. The "Portable Brain" Standard 🧠
Abbiamo ridefinito l'architettura degli Agenti EasyWay:
- **Disaccoppiamento Totale**: L'Agente è ora una "Presa Elettrica" (`-Provider`, `-Model`, `-ApiKey`).
- **Hybrid Intelligence**:
  - **Cervello**: Cloud (DeepSeek/OpenAI) o Local (Ollama) scambiabili a runtime.
  - **Memoria**: Locale (ChromaDB) interrogata via `bridge`.
- **Standarizzazione**: Tutti i Core Agents (`gedi`, `security`, `governance`, `retrieval`) ora parlano lo stesso linguaggio JSON.

### 2. The "n8n Appliance" Strategy 🐳
Abbiamo risolto l'eterno dilemma "sporcare il server vs avere feature":
- **Il Muro (Host OS)**: Rimane immacolato. Solo SSH e Docker.
- **L'Elettrodomestico (n8n)**: Gira in un container Docker isolato (`/opt/easyway/containers/n8n`).
- **L'Integrazione (Remote Brain)**: n8n comanda gli agenti sull'Host via **SSH** (`ssh host.docker.internal ...`).
- **Stato**: `easyway-n8n` è ONLINE e operativo.

### 3. Documentazione & Roadmap 🗺️
- **Nuova Bibbia**: `standards/agent-portability-standard.md` definisce le regole del gioco.
- **TESS v1.0 Update**: Aggiornato `easyway-server-standard.md` con la sezione Docker.
- **Futuro**: Creata `docs/project-root/FUTURE_ROADMAP.md` con i piani per "Mk. II" (Zero-Trust SSH, Swarm).

## ❓ Q&A del Giorno

**Q: Perché usare n8n via Docker e non installarlo con npm?**
*A: Per mantenere il server "Disposable" e pulito. Se n8n si rompe o non ci piace più, cancelliamo il container e il server resta perfetto.*

**Q: Come fa n8n (dentro Docker) a lanciare script (fuori, sull'host)?**
*A: Usa SSH. Si collega all'host interno (`host.docker.internal`) come se fosse un server remoto. È sicuro, standard e non richiede configurazioni esotiche.*

**Q: Posso cambiare l'intelligenza da DeepSeek a Ollama domani?**
*A: Sì. Basta cambiare il parametro `-Provider Ollama` nella chiamata n8n. Non devi toccare una riga di codice.*

## 📝 Note del Capitano
Oggi abbiamo costruito non solo un sistema funzionante, ma un'architettura che può sopravvivere per anni. È "Sartoria Napoletana": elegante, durevole, su misura.

*Missione Compiuta.* 🥂

---

### 🚨 UPDATE: Deployment Lessons (The force-clean Issue)

**Q: Ho avuto errori "Container name conflict" durante il deploy. Perché?**
*A: Se esistono vecchi container creati manualmente (o con nomi diversi), Docker Compose non riesce a sovrascriverli "gentilmente". È successo con `easyway-db` e `easyway-storage`.*

**Q: Come si risolve? (Il metodo "Force Clean")**
*A: Se il server è impazzito o ha container zombie, usa l'opzione nucleare:*
```bash
sudo docker rm -f $(sudo docker ps -a -q)  # Rimuove TUTTI i container
sudo docker network prune -f               # Rimuove network zombie
```
*Poi rilancia il deploy. Nota: Questo spegne tutto per un attimo, ma garantisce pulizia.*

**Q: Devo farlo su ogni nuovo server?**
*A: No. Solo se stai migrando da un'installazione "sporca" o manuale a una gestita. Su un server vergine, lo script `setup-easyway-server.sh` funziona al primo colpo.*


