# PLAYBOOK_GLOBAL – Framework Playbook EasyWayDataPortal

## Scopo

Definire un framework di playbook per questa repo, in modo che gli agent (LLM) sappiano:
- quali regole seguire a seconda del tipo di task,
- quale **perimetro applicativo** considerare (wiki e codice),
- quali altri playbook specializzati applicare,
- quali tool possono usare in autonomia,
- come allineare il proprio comportamento alla **flotta di agent** sotto `agents/` e agli script in `scripts/`.

Questo file è il “papà” dei playbook locali in `.axetrules/`.

---

## Perimetro applicativo

Questa repo contiene due pilastri principali:

1. **Wiki / Documentazione operativa**
   - Root canonica: `Wiki/EasyWayData.wiki/...`
   - Contiene:
     - step-N della webapp / portale / API,
     - policy, checklist, guide operative per team (dev, ops, governance, sicurezza, ecc.).

2. **Codice e infrastruttura EasyWay Data Portal**
   - `EasyWay-DataPortal/…` (backend, frontend, API, IaC, scripts),
   - `scripts/…` (script di supporto e automation),
   - `agents/…` (manifest, regole e priorità per agent specifici).

I playbook devono riflettere questa struttura: **le applicazioni e le guide operative sono sempre mappate nella wiki** `Wiki/EasyWayData.wiki/...`, e gli agent lavorano in coordinamento con:

- codice (`EasyWay-DataPortal/*`),
- script (`scripts/*`),
- knowledge base (`Wiki/EasyWayData.wiki/*`).

---

## Convenzioni generali

- Tutti i playbook locali hanno nome: `PLAYBOOK_*.md`.
- I playbook sono **linee guida operative**, non codice eseguibile.
- L’agente può:
  - leggere questi file (`read_file`),
  - applicarne le istruzioni,
  - combinarne più di uno nello stesso task (es. `PLAYBOOK_GLOBAL` + `PLAYBOOK_WIKI_STEP`).

Quando l’agente lavora su task che coinvolgono wiki + codice + automation, deve ispirarsi al modo in cui sono progettati gli **agent specializzati** in `agents/`:

- `agent_api`, `agent_backend`, `agent_frontend`, `agent_docs_review`, `agent_datalake`, `agent_governance`, `agent_security`, ecc.
- Ogni agent ha:
  - un `manifest.json` con scopo e perimetro,
  - una `priority.json` (o simile),
  - uno o più script di orchestrazione in `scripts/agent-*.ps1`.

Il comportamento dei playbook deve essere **coerente** con questi ruoli:
- non fare operazioni che normalmente sarebbero delegate a un agent specialist (es. deploy infra, modifiche DB) se non previsto,
- concentrarsi su:
  - wiki / documentazione LLM-ready,
  - supporto alla qualità (lint, gap, index, report),
  - piccole modifiche non distruttive al codice quando esplicitamente richiesto.

---

## Tool consentiti in generale

Per task limitati a questa repo, l’agente può usare in autonomia:

- `search_files`, `list_files`, `read_file`
- `write_to_file`, `replace_in_file`
- `execute_command` SOLO per:
  - comandi non distruttivi (no delete, no drop DB, no rm -rf),
  - script di utility locale (es. `wiki-*`, `*_lint`, `*_report`, `agent-*`) che lavorano su:
    - file di documentazione (`Wiki/EasyWayData.wiki/*`),
    - indici / report wiki,
    - manifest e config degli agent (`agents/*`),
    - analisi/lint del codice senza side-effect (es. report).

Se un comando può avere impatto distruttivo (delete massivi, modifiche DB, deploy), deve essere:
- esplicitamente autorizzato nel task,
- oppure previsto in un playbook specializzato (es. futuro `PLAYBOOK_DB`, `PLAYBOOK_INFRA`) e comunque **chiaramente richiesto** dall’utente.

---

## Mappa Playbook

### PLAYBOOK_WIKI_STEP.md

**Quando usarlo**

- Task che riguardano pagine “step-N-*.md” della wiki EasyWayDataPortal, in particolare:
  - `Wiki/EasyWayData.wiki/.../step-1-*.md`, `step-2-*.md`, …, `step-N-*.md`
- Esempi:
  - “sistemi lo step‑5 lo vedo orfano”
  - “allinea step‑N con gli index”
  - “aggiungi FAQ e edge case allo step‑X”
  - “normalizza i legacy STEP-* in coppia canonico + stub”.

**Cosa fa in sintesi**

- Mappa le pagine step-N (parent + child) in **tutta** la wiki `Wiki/EasyWayData.wiki/...`.
- Allinea il contenuto del parent seguendo il pattern standard (Perché serve, Q&A, Prerequisiti, Passi, Verify, Vedi anche).
- Gestisce naming legacy vs canonico (kebab-case) secondo strategia:
  - `keep+link`
  - `canonical-copy+redirect-note`
  - (futuro) spostamento fisico in `old/wiki/` quando la migrazione è completata.
- Collega i link in ingresso/uscita (step chain, child spec, checklist, pagine di policy, orchestrazioni/flow).
- Verifica riferimenti usando script/report wiki (`scripts/wiki-*`) quando disponibili.

Vedi dettagli operativi in `PLAYBOOK_WIKI_STEP.md`.

---

## Allineamento con la flotta di agent (`agents/`)

Gli agent definiti in `agents/*` rappresentano **ruoli** specializzati (API, backend, frontend, docs_review, governance, security, ecc.).  
Il comportamento guidato dai playbook deve:

- essere **compatibile** con questi ruoli,
- evitare di sovrapporsi a funzioni ad alto impatto (deploy, modifiche DB, provisioning infra),
- concentrarsi su:

1. **Preparare materiale LLM-ready e agent-ready**
   - Wiki strutturata (`Wiki/EasyWayData.wiki/*`):
     - front‑matter completi,
     - sezioni standard (Q&A, Prerequisiti, Passi, Verify, Vedi anche),
     - naming coerente (kebab-case, step-N-…),
     - gestione legacy → canonico + stub.
   - Documentazione chiara sui **comportamenti attesi** degli agent (cosa fanno `agent_api`, `agent_backend`, ecc.).

2. **Supportare gli script `agent-*` e `wiki-*`**
   - I playbook possono usare `execute_command` per:
     - lanciare script `wiki-*` (lint, gap, index, links, anchors),
     - lanciare script `agent-*` quando richiesto in modalità **report / simulazione** (no side effect critici).

3. **Ridurre ambiguità per gli agent**
   - Chiarire nei testi wiki:
     - quali step sono canonici,
     - quali file sono deprecated e dove si trova la versione nuova,
     - dove sono gli esempi “di riferimento” che gli agent devono usare (es. endpoint reali, policy, checklist).

---

## Regole di composizione playbook

Quando il task è ambiguo o tocca più aree, l’agente deve:

1. Applicare sempre le regole di questo `PLAYBOOK_GLOBAL.md`.
2. Per task sulla wiki step-based, applicare anche `PLAYBOOK_WIKI_STEP.md`.
3. Per task futuri (es. agent, DB, infra), applicare anche i playbook dedicati quando saranno creati:
   - `PLAYBOOK_AGENTIC.md` (comportamento generico degli agent e orchestrazione multi-agent),
   - `PLAYBOOK_DB.md` (operazioni DB non distruttive, lint, inventory),
   - `PLAYBOOK_INFRA.md` (infra as code, pipeline, deployment),
   - ecc.

L’agente può leggere più playbook e combinarne le istruzioni, dando priorità a:

1. Regole del task esplicito dell’utente (ultimo messaggio).
2. Regole del playbook più specifico (es. WIKI_STEP) rispetto a quello globale.
3. Regole generali di sicurezza (no operazioni distruttive non autorizzate).

---

## Criteri di “Done” per un task guidato da playbook

Un task può essere considerato completato dall’agente quando:

- Ha seguito i passi operativi indicati nel/i playbook pertinente/i.
- Ha usato i tool consentiti rispettando le policy (incluso l’uso prudente di `execute_command` e degli script `wiki-*` / `agent-*`).
- Ha prodotto un riepilogo finale per l’utente che includa:
  - quali playbook sono stati applicati,
  - quali file sono stati modificati,
  - eventuali script eseguiti (wiki/agent, in modalità report o apply),
  - eventuali TODO espliciti rimasti (che richiedono decisioni umane o altre autorizzazioni),
  - eventuali proposte di migrazione aggiuntive (es. spostamento future di legacy in `old/wiki/`).
