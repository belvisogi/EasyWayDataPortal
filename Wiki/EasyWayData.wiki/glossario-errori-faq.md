---
id: ew-glossario-errori-faq
title: Glossario EasyWay & FAQ Errori Tipici
tags: [onboarding, faq, devx, audience/dev, language/it]
summary: Glossario di termini chiave usati in EasyWay DataPortal e soluzioni rapide agli errori più frequenti per chi sviluppa/contribuisce.
status: draft
owner: team-platform
updated: '2026-01-06'
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
type: guide
---

[Home](../../scripts/docs/project-root/DEVELOPER_START_HERE.md)

# Glossario Essenziale EasyWay

| Termine      | Significato rapido                              | Esempio/Nota operativa                                       |
|--------------|------------------------------------------------|--------------------------------------------------------------|
| **Intent**   | Descrizione strutturata di un obiettivo o task | `intent.db-table-create.json`: definisce nuova tabella, colonne, privacy |
| **Gate**     | Check/validatore automatico in CI/CD o doc     | Gate “wiki-gap-report”: blocca merge se doc non aggiornata   |
| **Drift**    | Differenza tra stato atteso e reale (es. su DB, doc, config) | “DB drift”: DDL repository ≠ struttura reale sul database    |
| **Agent**    | Script/servizio autonomo che esegue task specifici secondo manifest | `agent_dba` automatizza inventario DB, controlla drift       |
| **Manifest** | File JSON/YAML che descrive comportamento/goal di un agente | `manifest.json` in agent/                                    |
| **Orchestrazione** | Workflow automatizzato che collega task e agent/script | n8n-db-ddl-inventory aggiorna inventario + pagina Wiki       |
| **WhatIf**   | Modalità (simula senza modificare) per vedere effetti di un task | “pwsh ... -WhatIf” non scrive su DB, mostra solo azioni      |
| **Artifact** | File di output/intermedio generato da pipeline o agente | Esempio: `db-ddl-inventory.json`, report QA, log eventi      |
| **Gate verde** | Stato “ok” per check / validazione automatica | Tutti i gate verdi → puoi fare merge o rilasciare            |

---

# FAQ Errori/Pitfall Comuni

**❓ Il test fallisce o il gate non è verde: cosa faccio?**
- Controlla l’output dettagliato: usualmente trovato in `logs/events.jsonl`, artefatti runner, o output CLI (Postman/k6 per API, PowerShell per script).
- Verifica che PR o commit abbiano aggiornato anche doc/manifest, NON solo il codice/sorgente.
- Se il gate richiede aggiornamento wiki/doc, lancia i fix script indicati (es: `pwsh scripts/wiki-gap-report.ps1` per checklist, `wiki-frontmatter-autofix.ps1` per meta info).
- Consulta la sezione “Verify” nelle guide/ricette: ogni workflow/scheda agent fornisce i punti di controllo e recovery.

**❓ Perché un gate (es. wiki-gap, drift, lint) non diventa “verde”?**
- La doc/wiki non è stata aggiornata con l’ultimo schema/output.
- I file generati da script/agent non sono nel path giusto o non rispettano il naming richiesto.
- Lancia lo script di validazione (“lint” o “gap-report”) dedicato; se restituisce errori, leggere la riga e correggere secondo il template.
- Se persistono errori formali, confronta con l’esempio fornito nel primo riquadro della ricetta.

**❓ Dove trovo i log/artifact?**
- Output standard: directory `agents/logs/`, `db-ddl-inventory.json`, `tests/` oppure summary stampato dallo script.
- Nei workflow n8n/agentici: ogni run produce artefatti/log in percorso temporaneo e link esplicito nella summary script (cerca output tipo “Artifact scritto in: ...”).
- Per test cloud: dashboard Azure DevOps / log pipeline.

**❓ Come fixo errori di formattazione/lint/”frontmatter”?**
- Usa direttamente gli script di lint/fix suggeriti nei messaggi errore (`wiki-frontmatter-autofix.ps1`, `scripts/wiki-frontmatter-lint.ps1`).
- Segui i rimandi/suggerimenti nei messaggi CLI: spesso c’è direttamente il comando “autofix” riportato.


---

**Suggerisci altri termini o errori ricorrenti: la pagina cresce con le domande della community!**



**❓ Problemi di Encoding su PowerShell 5.1 (Windows)?**
- **Sintomo**: Stringhe troncate o caratteri strani (es. `â€”`).
- **Causa**: PS 5.1 interpreta UTF-8 no-BOM come Windows-1252 se non configurato. Caratteri come Em Dash (`—`, byte `E2 80 94`) possono rompere il parsing (il byte `94` viene letto come `"` troncando la stringa).
- **Workaround**: Usare solo ASCII (sostituire `—` con `-`) o forzare output encoding UTF8.
- **File Affetti (Identificati)**: `New-DecisionProfile.ps1`, `db-generate-table-artifacts.ps1`, `agent-pr.ps1`, `agent-llm-router.ps1`, `agent-governance.ps1`.

## Vedi anche

- [Proposte Cross-link, FAQ mancanti, Ricette edge-case e automazioni](./onboarding/proposte-crosslink-faq-edgecase.md)
- [HOWTO — Tagging e metadati in EasyWay DataPortal](./onboarding/howto-tagging.md)
- [Developer & Agent Experience Upgrades](./onboarding/developer-agent-experience-upgrades.md)
- [Setup ambiente di test/Sandbox e Zero Trust](./onboarding/setup-playground-zero-trust.md)
- [Documentazione - Contesto standard (obbligatorio)](./onboarding/documentazione-contesto-standard.md)





