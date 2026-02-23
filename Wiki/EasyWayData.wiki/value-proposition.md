---
id: ew-value-proposition
title: Visione & Value Proposition
summary: Perché EasyWay Data Portal e cosa fa. Messaggio chiaro per persone e agenti.
status: active
owner: team-platform
tags: [domain/docs, layer/spec, audience/non-expert, audience/dev, privacy/internal, language/it, vision, value, onboarding]
llm:
  include: true
  pii: none
  chunk_hint: 300-500
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
type: guide
---

[Home](../../scripts/docs/project-root/DEVELOPER_START_HERE.md) > [[domains/docs-governance|Docs]] > 

# Visione & Value Proposition
Breadcrumb: Home / Visione & Value

Perché EasyWay Data Portal
- Crediamo che la gestione dei dati debba essere semplice, accessibile e sicura per tutti: dalla piccola impresa al grande gruppo. Vogliamo abbattere le barriere tecniche e democratizzare l’accesso a strumenti avanzati, permettendo a chiunque di ottenere valore dai propri dati senza complessità, costi nascosti o dipendenza da specialisti.

Cosa fa EasyWay Data Portal
- Piattaforma intuitiva: anche senza competenze tecniche, gestisci e valorizzi i dati in modo sicuro e automatizzato.
- Automazione agentica: gli agenti eliminano attività ripetitive e complesse.
- Sicurezza e compliance by design: tracciabilità, policy, audit.
- Due rubinetti: locale low‑cost (mock) e cloud pronto (sql/kv) — senza rework.
- Per chi usa e per chi costruisce: servizi pronti e framework modulare.

Stato: Preview in evoluzione
- Stiamo costruendo un portale per tutti. Le fondamenta sono già operative (agent‑first, dual‑mode, WhatIf, gates, Doc Alignment). La roadmap accompagna i prossimi mesi fino al rilascio pubblico.

Riferimenti
- README (sezione “Perché e Cosa Fa”)
- agentic‑portal‑vision.md
- dev‑dual‑mode.md
- roadmap.md

## Start With Why (S. Sinek)

Tagline
- Inclusività digitale: dar voce ai tuoi dati.

Why (Perché)
- EasyWay Data Portal nasce dalla convinzione che la gestione dei dati debba essere semplice, accessibile e sicura per tutti. Il nostro scopo è abbattere le barriere tecniche e democratizzare l’accesso a strumenti avanzati, affinché chiunque possa ottenere valore dai propri dati senza complessità, costi nascosti o dipendenze da specialisti.

How (Come)
- Piattaforma agent‑first, cloud‑native, automatizzata e sicura.
- Agenti che rendono semplici e automatizzati i processi complessi (WhatIf, gates, doc alignment).
- Sicurezza, compliance e tracciabilità by design.
- Framework modulare, estendibile, per chi vuole “usare” e per chi vuole “costruire”.

What (Cosa)
- Portale dati multi‑tenant e API‑first con automazione avanzata e agenti specializzati.
- Gestione, analisi e valorizzazione dei dati tramite interfaccia intuitiva e API.
- Automazione di processi ripetitivi, sicurezza e auditing centralizzati, onboarding e documentazione facilitati.

---

## 🚀 The Enterprise Go-To-Market Strategy (Integration & Governance)

La vera potenza commerciale di **EasyWay Agentic Framework** non risiede solo nel fornire "bot che scrivono codice", ma nell'offrire un **Wrapper di Governance Agnostico** vendibile a qualsiasi azienda Enterprise.

Molte grandi aziende sono frenate nell'adozione dell'AI generativa dai rischi di sicurezza, costi incontrollati e perdita di controllo sui processi IT (ITIL/Scrum).
La nostra Value Proposition per aggredire il mercato B2B è: **"Ti diamo il framework sicuro per far atterrare l'AI nella tua azienda, senza dover cambiare i tuoi strumenti attuali."**

### Agnosticismo Architetturale
Il Framework EasyWay si inserisce come un livello di orchestrazione "sopra" gli strumenti già in uso dal cliente. Non importa quale stack tecnologico l'azienda utilizzi:
- **Azure DevOps (ADO)**
- **GitHub / GitLab**
- **Atlassian Jira / Bitbucket**
- **Witboost**
- **...o persino se non usano nulla di tutto questo.**

### Perché le Enterprise avranno bisogno di EasyWay:
1. **Integrazione in Elevata Sicurezza:** Il nostro *Sovereign Gatekeeper* evita che le AI tocchino codice, rilasci o database senza l'esplicita validazione Umana (Four-Eyes Principle).
2. **Controllo del Budget:** Il modulo di *Stop-Loss RBAC* a livello OS impedisce matematicamente che un agente "impazzito" bruci migliaia di dollari in chiamate API incontrollate.
3. **Pluggable & Bring-Your-Own-LLM:** Il framework pilota in sicurezza OpenAI, DeepSeek o modelli on-premise, mascherandoli dietro interfacce standard.
4. **Agenti "Scrum-Ready":** Non offriamo plugin per l'IDE dei programmatori, offriamo "Assunti Digitali" (Agent Product Owner, Agent Scrum Master) che dialogano nativamente con Jira/ADO per convertire requisiti aziendali in User Story, rispettando rigorosamente le board e le cerimonie Agile dell'azienda cliente.

---

## 🧪 The "Kiuwan for AI": Benchmark Sandbox as a Service

Oltre all'integrazione, EasyWay apre un mercato totalmente nuovo: la **Valutazione e il Benchmarking degli Agenti AI Enterprise**.

Proprio come *Kiuwan* o *SonarQube* misurano la qualità del codice, e piattaforme come *Artificial Analysis* misurano le performance brute degli LLM, EasyWay si posiziona come l'**Analizzatore delle Performance Operative dell'AI**.

Le Enterprise sono inondate di offerte da vendor AI (Copilot, Devin, agenti custom). Come fanno a sapere di chi fidarsi?
EasyWay fornisce una **Sandbox Isolata e Certificata** dove le aziende possono "testare" gli agenti AI su task reali misurandone l'efficacia tramite metriche di business chiare (KPI).

### I KPI di Benchmarking forniti da EasyWay:
1. **Resolution Rate Reale:** L'agente è riuscito a chiudere la User Story senza rompere la compilazione in un ambiente strutturato?
2. **Cost-per-Task:** Quanto budget (token) ha bruciato l'agente per risolvere un singolo requisito? (Il framework lo espelle se sfora il limite).
3. **Governance Compliance:** Quante volte l'agente ha tentato un'azione vietata (es. deploy senza branch) venendo bloccato dal Sovereign Gatekeeper?
4. **Documentation Alignment:** L'agente ha aggiornato correttamente la documentazione di prodotto dopi aver modificato il codice?

*Visione per i CISO/CIO:* **"Prima di assumere il nuovo super-agente AI dell'azienda X, fallo girare nella Sandobx di EasyWay. Noi ti forniremo la pagella crittografica sulle sue reali performance, sui suoi costi nascosti e sulla sua conformità alle policy Zero-Trust."**








