---
id: ew-developer-agent-experience-upgrades
title: Developer & Agent Experience Upgrades
tags: [onboarding, devx, agentic, scalability, repo-structure, audience/dev, language/it]
summary: Suggerimenti e redesign operativi per rendere la struttura EasyWay DataPortal ancora più developer-friendly e agent-ready.
status: draft
owner: team-platform
updated: '2026-01-06'
---

[Home](../../../docs/project-root/DEVELOPER_START_HERE.md)

# 🚀 Potenziare l’alberatura: più developer-friendly, più scalabile, più agent-ready

Questa guida raccoglie le azioni proposte per migliorare l’esperienza di sviluppo, l’onboarding e la scalabilità (umana e tecnica) del progetto EasyWay DataPortal, con focus architettura agentica.

---

## 1. Sotto-README, manifest e intro micro per ogni cartella chiave

- Ogni folder (agents/, atomic_flows/, scripts/, infra/, docs/, old/, ...) deve avere il proprio README.md, con:
  - Descrizione dello scopo e dei sottodir principali
  - Link alle ricette/riferimenti, manifest/etc.
  - Guideline su come aggiungere/estendere/contribuire

---

## 2. Ogni agent come "micro-root" self-contained

- Struttura minima per ogni agent:
  ```
  agents/agent_nome/
      manifest.json
      README.md           <-- intro/riferimenti/contesto
      src/                <-- codice specifico (opzionale)
      templates/          <-- template o intent usati/agenti
      doc/                <-- brevi how-to e ricette locali
      test/               <-- test/sandbox/fake/mock
      priority.json       <-- orchestrazione build/usage
  ```
- Così ogni agent è plug&play, forkabile e testabile in isolamento.

---

## 3. Wizard/script per accensione nuovo agent

- CLI “add-agent” (`pwsh scripts/agent-add.ps1 setup-nuovo-agent`) che:
  - Crea micro-root con struttura base
  - Compila manifest di esempio + stub template/recipe
  - Inserisce README con TODO rimpiazzabili via prompt

---

## 4. Ricette e checklist di parità tra agent

- Ogni nuovo agent pubblica una “agent recipe” (atomic_flows/templates/) con:
  - Use case esempio
  - Test locale runnable (pwsh/test, stub input)
  - Passaggi minimi “pronti per CI/CD”

---

## 5. Uniformare path e discovery di manifest/template/recipes

- Allineare la posizione di manifest e template all’interno di ciascun agent (`agents/agent_x/template/`).
- Global index (`agents/agent-registry.json`) che registra tutti gli agent e ne permette la discovery automatica da tooling/script.

---

## 6. Tagging automatico e searchable nei manifest/recipe

- Aggiungi tag (standard: domain, capability, input/output type, version) a manifest e recipe per supportare agent browsing e ricerca automatica.

---

## 7. Welcome wizard per chi sviluppa

- Script di onboarding interattivo (“pwsh scripts/welcome-to-easyway.ps1”) che guida nuovo dev o maintainer su:
  - Struttura della repo
  - Agenti disponibili
  - Come testare/integrare/contribuire (link ricette)
  - Avviso su checklist cross-platform, zero trust e sandbox

---

## 8. Sotto-README “veloce” per atomic_flows/, scripts/ e old/

- Anche i toolkit comuni vanno documentati (1-2 screen/info, mapping agli agent).
- In old/ sottolineare cosa può essere migrato e cosa è “reference only”.

---

## 9. Automazione CI/CD sugli agent

- Pipeline/CD-pipeline che gira lint, test lint e doc per ogni nuovo agent/commit.
- Se un manifest/recipe non è in standard → warning + suggest PR.

---

**Con queste azioni, EasyWay DataPortal diventa ancora più:
- Facile da navigare e contribuire
- Scalabile a molti team/feature/plugin
- Agent-first, con discovery dinamica e automazione plug&play!**


