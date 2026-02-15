---
title: PRD - Agentic Release Multi-VCS (MVP)
tags: [domain/control-plane, layer/spec, audience/dev, audience/ops, privacy/internal, language/it, agents, release, devops, forgejo, github]
status: draft
updated: 2026-02-12
redaction: [email, phone, token]
id: ew-control-plane-prd-agentic-release-multivcs-mvp
chunk_hint: 220-360
entities: []
include: true
summary: PRD MVP per rendere il flusso release agentico portabile su Azure DevOps, Forgejo e GitHub con un unico contratto azioni.
llm:
  pii: none
  redaction: [email, phone]
pii: none
owner: team-platform

llm:
  redaction: [email, phone]
  include: true
  chunk_hint: 5000
type: guide
---

[[../start-here.md|Home]] > [[index.md|Control-Plane]] > PRD

# PRD - Agentic Release Multi-VCS (MVP)

## 1) Visione
Costruire un "motore release agentico" unico che mantenga la stessa UX e gli stessi guardrail su tre provider:
- Azure DevOps
- Forgejo
- GitHub

Obiettivo pratico: usare lo stesso flusso `promote + server-sync` gia' validato nel progetto, senza riscrivere la logica per ogni piattaforma.

## 2) Problema
Oggi i workflow release sono robusti, ma fortemente dipendenti dal contesto corrente.
Questo rallenta adozione esterna e rende piu' costosa la manutenzione multi-provider.

## 3) Obiettivi MVP
- O1: Contratto unico azioni release (`release:promote`, `release:server-sync`).
- O2: Adapter provider pluggable (`ado`, `forgejo`, `github`) con stesso output contract.
- O3: Guardrail invarianti su tutti i provider (branch policy, backup, audit trail).
- O4: Quickstart installabile per team terzi (self-hosted o cloud).

## 4) Non-obiettivi MVP
- Gestione completa di tutti i workflow CI/CD enterprise.
- UI dedicata custom.
- Orchestrazione multirepo avanzata con dipendenze transitive.

## 5) Personas
- Dev Lead: vuole promuovere in sicurezza senza attivita' manuali ripetitive.
- Ops/SRE: vuole server sync ripetibile con rollback path.
- Platform Owner: vuole audit, policy enforcement e portabilita' provider.

## 6) Scope funzionale MVP
### 6.1 Azioni canoniche
- `release:promote`
  - input: `source`, `target`, `strategy`
  - output: risultato merge/push + release notes draft + warning policy
- `release:server-sync`
  - input: `server_host`, `server_user`, `target`, `server_repo_path`
  - output: backup refs, stash ref, stato finale repo remoto

### 6.2 Provider adapter
- `provider: ado`
  - PR checks, branch policy, merge status via Azure DevOps API/CLI
- `provider: forgejo`
  - PR checks e merge status via Forgejo API
- `provider: github`
  - PR checks e merge status via GitHub API

### 6.3 Skill layer
- Riutilizzo `git.checkout`, `git.merge`, `git.push`, `git.server-sync`.
- Nuova astrazione: `vcs.provider.*` per differenze API provider.

## 7) Requisiti funzionali
- RF1: L'agente deve bloccare target non conforme alla policy naming/branch.
- RF2: In `server-sync` deve creare backup (branch/tag) prima del riallineamento.
- RF3: Deve produrre audit trail strutturato (decisioni + comandi + esiti).
- RF4: Deve supportare modalita' non-interattiva (`-Yes`) per pipeline.
- RF5: Deve esporre output contract uniforme indipendentemente dal provider.

## 8) Requisiti non funzionali
- RNF1: Idempotenza operativa per i casi standard.
- RNF2: Sicurezza: nessun secret in log/eventi.
- RNF3: Tracciabilita': eventi e run metadata persistenti.
- RNF4: Estendibilita': aggiunta nuovo provider senza toccare il core flow.

## 9) Architettura proposta (MVP)
- Layer 1: `agent_release` (reasoning + policy + orchestrazione)
- Layer 2: skill git (`git.*`) e provider adapters (`vcs.provider.*`)
- Layer 3: runtime execution (local CLI / CI / n8n dispatch)
- Layer 4: knowledge/docs sync (Wiki + chunks + KB recipes)

## 10) Metriche di successo (MVP)
- M1: 3 provider attivati con lo stesso contratto azione.
- M2: >= 90% dei release run senza intervento manuale.
- M3: 100% run con backup+audit presenti.
- M4: tempo medio `develop -> main -> server-sync` ridotto di almeno 40%.

## 11) Piano delivery (prossimi giorni)
### Fase A - Adapter contract
- Definire interfaccia `vcs.provider` e mapping azioni base.

### Fase B - Implementazione provider
- Implementare adapter `ado`, `forgejo`, `github`.
- Test smoke per ciascun provider.

### Fase C - Orchestrazione e docs
- Collegare in `ewctl` / orchestratore.
- Aggiornare docs, roster, chunks e KB.

## 12) Rischi e mitigazioni
- R1: API diverse tra provider -> mitigazione: adapter contract rigido + test contract.
- R2: drift policy branch -> mitigazione: policy centrale nel core flow, non negli adapter.
- R3: complessita' rollout -> mitigazione: feature flags per provider.

## 13) Acceptance criteria MVP
- AC1: Esecuzione E2E su ADO, Forgejo, GitHub con stesso comando logico.
- AC2: Guardrail rispettati e verificabili in audit log.
- AC3: Runbook quickstart per team esterni pubblicato e testato.
- AC4: Documentazione RAG-ready indicizzata.

## 14) Wishlist MVP (decisione)
Questo item entra ufficialmente nella wishlist MVP come iniziativa prioritaria:
- Nome: `Agentic Release Multi-VCS`
- Priorita': High
- Owner: `team-platform`
- Stato: `planned`

## 15) Q&A rapido
Q: E' un prodotto interno o esterno?
- A: Parte come interno, ma progettato da subito per adozione esterna.

Q: Perche' tre provider invece di uno?
- A: Riduce lock-in e aumenta riuso della piattaforma agentica.

Q: Cosa rende questo diverso dai tool gia' sul mercato?
- A: Policy-driven orchestration + reasoning + server-safe-sync + docs/RAG alignment nello stesso ciclo.

