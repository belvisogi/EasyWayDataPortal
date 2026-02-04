---
id: ew-archive-imported-docs-2026-01-30-project-root-future-roadmap
title: 🚀 EasyWay Future Roadmap: "The Iron Man Suit"
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
# 🚀 EasyWay Future Roadmap: "The Iron Man Suit"

> **"Averlo fatto è una figata."** - *User, 2026-01-27*

Abbiamo costruito l'architettura perfetta ("The Suit"). Ecco come possiamo potenziarla ulteriormente in futuro (Mk. II, Mk. III...).

## 1. Zero-Trust SSH (The "Keymaster" Pattern) 🔐
**Corrente**: n8n si collega via SSH e può lanciare *qualsiasi* comando come utente `easyway`.
**Upgrade**: Limitare la chiave SSH a *soli* comandi specifici.
**Come**: Nel file `authorized_keys` dell'Host:
```bash
command="/opt/easyway/bin/agent-dispatcher.sh",no-port-forwarding,no-x11-forwarding,no-agent-forwarding ssh-ed25519 AAA... n8n-key
```
In questo modo, anche se rubano la chiave di n8n, possono solo lanciare il "Dispatcher", non fare `rm -rf /`.

## 2. Agent Auto-Discovery (The "Jarvis" Protocol) 📡
**Corrente**: Devi configurare a mano il nodo n8n per chiamare `agent-gedi.ps1`.
**Upgrade**: n8n interroga l'Host: *"Quali agenti hai?"*
**Come**: 
1. `easyway-agent --list-capabilities` restituisce un JSON con tutti gli agenti e i loro input.
2. n8n legge questo JSON e crea dinamicamente i tool.
3. Aggiungi un agente sull'Host -> Appare magicamente su n8n.

## 3. The "Black Box" Logging ✈️
**Corrente**: Log file su Host (`agent-history.jsonl`).
**Upgrade**: Centralized Flight Recorder.
**Come**: Gli agenti non scrivono solo su disco, ma sparano l'evento a un container **Loki** o **Elasticsearch** (via HTTP/UDP).
n8n può mostrare una dashboard in tempo reale di *tutti* i pensieri degli agenti.

## 4. "Air-Gapped" Intelligence 🛡️
**Corrente**: Hybrid Cloud (DeepSeek API).
**Upgrade**: Full On-Premises.
**Come**: Quando avrai il Server d'Ufficio (GPU), dockerizzi **Ollama** o **vLLM**.
L'architettura "Socket" è già pronta: cambi solo `-Provider Ollama` e `-ApiEndpoint http://localhost...`.
Il sistema diventa invisibile al mondo esterno.

## 5. Agent Swarm (Multi-Host) 🐝
**Corrente**: 1 Host, 1 n8n.
**Upgrade**: n8n orchestra agenti su *più* server (es. 1 Oracle per il Web, 1 Hetzner per i Dati).
**Come**: n8n ha solo bisogno di chiavi SSH diverse.
*"Agent Frontend, deploya su Oracle. Agent Backend, migra DB su Hetzner."*
Il "Cervello Remote" coordina il "Corpo Distribuito".

---
*Documento creato per non dimenticare dove possiamo arrivare.*


