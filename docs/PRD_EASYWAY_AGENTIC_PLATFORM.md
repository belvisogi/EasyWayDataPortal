# PRD - EasyWay Agentic Platform

Version: 1.1 (Hybrid Core Edition)
Date: 2026-02-17
Status: Execution (Level 3 - Hybrid)
Owner: team-platform

## 1. Visione e Missione
(Invariato)

## 10.b Hybrid Core Architecture (v1.1)

### Pipeline Pattern (The "Pipe")
Per gestire input di grandi dimensioni (es. `git diff` o file di log) senza rompere il parser della shell, EasyWay adotta il **Pipeline Pattern**.
*   **Standard**: `Source | Invoke-AgentTool -Task <Task>`
*   **Vantaggio**: I dati viaggiano sullo stream Stdin, evitando limiti di lunghezza cmdline e caratteri speciali.
*   **Strumenti abilitati**: `Invoke-AgentTool` supporta nativamente input da pipeline.

### Smart Commit Protocol (`ewctl commit`)
Il comando `git commit` diretto è deprecato per gli agenti.
*   **Nuovo Standard**: `ewctl commit -m "..."`
*   **Funzionamento**:
    1.  **Anti-Pattern Scan**: Blocca commit se rileva pattern vietati (es. `Invoke-AgentTool -Target ...`).
    2.  **Rapid Audit**: Esegue `agent-audit` (manifest check) prima del commit.
    3.  **Safe Execute**: Se i check passano, esegue il commit reale.

## 13. KPI e SLA
(Aggiornamento v1.1)
### KPI di Qualità
- **Pipeline Compliance**: 100% degli agenti devono usare `|` per input > 1KB.
- **Commit Safety**: 0 commit diretti da agenti (devono passare da `ewctl commit`).

### Visione
Rendere l'adozione di agenti AI affidabile per processi reali, non solo per demo.
Rendere EasyWay una "fabbrica prodotto" capace di generare nuovi prodotti coerenti, governati e manutenibili con lo stesso modello operativo.

### Missione
EasyWay consente a ogni organizzazione di scegliere liberamente come usare l'AI agentica: cloud, locale o ibrido, con governance, qualita' misurabile e controllo totale su dati, costi e rischio operativo.

### Principio guida
L'utente non deve solo "abilitare/disabilitare" un provider. Deve poter decidere il profilo di utilizzo che preferisce (qualita', privacy, costo, latenza, affidabilita') e cambiarlo nel tempo senza riscrivere il sistema.
Per ogni processo operativo, l'automazione deve essere "agenti-by-default" con conferma umana obbligatoria ai checkpoint definiti.

## 2. Problema da risolvere

Le piattaforme agentiche sul mercato spesso:
- automatizzano task semplici ma non processi critici;
- offrono poca trasparenza nelle decisioni dei modelli;
- vincolano a un solo provider;
- non hanno controllo forte su approval, audit, fallback;
- non misurano in modo rigoroso la qualita' operativa.

EasyWay deve coprire questi gap con un prodotto enterprise-ready.

## 3. Obiettivi di Prodotto

1. Fornire una piattaforma agentica governata per processi critici (DB, security, docs, release).
2. Abilitare routing cloud/locale/ibrido con policy configurabili.
3. Garantire qualita' e affidabilita' con KPI/SLA e auditing completo.
4. Ridurre tempo operativo manuale mantenendo human-in-the-loop sulle azioni ad alto impatto.
5. Trasformare EasyWay nel core di una product factory, per creare prodotti derivati con standard tecnici e operativi uniformi.

## 4. Non-Obiettivi

- Costruire un "general assistant" consumer.
- Autonomia totale senza controllo umano.
- Dipendenza hard da un solo vendor LLM.
- Ottimizzazione perfetta costi/qualita' dal giorno 1 (si procede per iterazioni).

## 5. Utenti e Jobs-to-be-Done

### Persona A - Platform Lead
- Job: governare standard, sicurezza, compliance e costi.
- Bisogni: policy, approval gates, audit log, metriche per decisioni.

### Persona B - Team tecnico (DBA/Security/Dev)
- Job: eseguire task operativi in modo veloce ma sicuro.
- Bisogni: suggerimenti utili, piani eseguibili, fallback affidabile.

### Persona C - Product/Operations Manager
- Job: capire impatto business e ROI.
- Bisogni: dashboard KPI, trend di qualita', tempo risparmiato.

## 6. Value Proposition

EasyWay non vende "chat". Vende:
- orchestrazione agentica affidabile;
- scelta reale del runtime AI (cloud/locale/ibrido);
- governance enterprise by design;
- miglioramento continuo basato su metriche.

Messaggio di posizionamento:
- EasyWay va venduto come pacchetto unico, non come insieme di software aggiuntivi.
- Proposta: un ecosistema operativo completo, con un solo pannello, un solo audit trail e capability native integrate (non patchwork di tool scollegati).
- Obiettivo commerciale: ridurre complessita' percepita dal cliente e aumentare valore/margine tramite piattaforma unificata.
- Il Portale EasyWay e' al tempo stesso sito digitale e centro operativo: una "digital front door" da cui il cliente gestisce il proprio mondo (processi, comunicazioni, appuntamenti, dati, automazioni).

## 6.a North Star Economica (versione concreta)

1. E' possibile scalare molto forte se il core diventa davvero riusabile e vendibile piu' volte.
2. La leva vera non e' "AI wow", e' il loop: `custom -> productization -> riuso -> margine`.
3. Formula operativa: pochi umani senior + macchina disciplinata + standard duri + canale commerciale.
4. Se qualita', governance e factory economics restano difesi nel tempo, il modello puo' crescere con forte effetto leva.

## 6.d Cambio di Paradigma (da copilot individuale a sistema organizzativo)

Contesto:
- Molte soluzioni AI attuali sono orientate al singolo utente e al singolo device/tool.
- Questo approccio e' utile, ma resta "a valle" dei processi aziendali.

Posizionamento EasyWay:
1. Non solo copilot personale: piattaforma agentica per l'intera organizzazione.
2. Non solo assistenza al task: orchestrazione interpolata nei processi end-to-end.
3. Non solo automazione locale: governance, audit, approval e qualita' condivise.
4. Non solo output immediato: productization e riuso sistematico in ottica factory.

Obiettivo:
- Spostare il valore da "AI che aiuta la persona" a "sistema che governa in modo affidabile il lavoro multi-team".

## 6.b Product Factory Strategy

EasyWay deve funzionare come piattaforma madre da cui derivano nuovi prodotti (es. moduli verticali, pacchetti domain-specific, edition clienti) senza reinventare ogni volta architettura, sicurezza e operations.

Principi factory:
- un core condiviso per policy, audit, provider routing, execution governance;
- template standard per bootstrap di nuovi prodotti;
- pipeline e runbook uniformi per deploy, monitoraggio e incident response;
- manutenzione convergente: fix e miglioramenti nel core propagabili a tutti i prodotti derivati.

## 6.c Use Case Productization Loop (artigianato + dime)

Modello operativo:
- EasyWay lavora come un laboratorio di abiti su misura: ogni cliente puo' ricevere una soluzione custom.
- Le "dime" (pattern riusabili) restano nel core EasyWay.
- Ogni use case custom deve produrre asset riutilizzabili e rivendibili con piccoli adattamenti.

Ciclo standard:
1. Discovery use case cliente.
2. Delivery custom con separazione netta tra parti specifiche e parti generiche.
3. Estrazione asset riusabili (template, action pack, policy pack, connector, runbook).
4. Productization in catalogo factory con versioning e quality gate.
5. Reuse su nuovi clienti con delta minimo e tempi ridotti.

Regola architetturale:
- codice/flow specifico cliente isolato in layer di configurazione/adapter;
- nessun dato o logica cliente hardcoded nei moduli core.

## 7. Scope per Release

### R0 - Foundation (2 settimane)
- API chat agenti stabile in server.
- Deploy ripetibile con reverse proxy corretto.
- Auth dev/prod funzionante.
- DB mock mode per bootstrap rapido.

### R1 - Agentic Runtime V1 (4-6 settimane)
- Intent resolution LLM + fallback deterministico.
- Action routing da manifest (`actions`, `allowed_tools`, `allowed_paths`).
- Execution mode `plan/apply` con approval ticket.
- Audit completo input/output/decision path.

### R2 - Provider Choice e Preference Engine (6-10 settimane)
- Routing per policy + preferenze utente/team.
- Supporto locale/API/ibrido con fallback automatico.
- Cost guardrails e quality guardrails.

### R3 - Multi-Agent Collaboration (10-16 settimane)
- Workflow tra agenti con passaggio contesto verificabile.
- Correzione iterativa con limiti e policy.
- Report di performance per agente e per dominio.

### R4 - Product Factory Enablement (16-20 settimane)
- Product template kit per creare nuovi prodotti in modo guidato.
- Catalogo capability riusabili (policy, auth, observability, approval flows).
- Processo di upgrade centralizzato core -> prodotti derivati.
- Governance di compatibilita' versione per evitare drift tra prodotti.

## 8. Requisiti Funzionali

### FR-01 Provider Abstraction
- Il runtime deve supportare provider multipli via interfaccia unica.
- Provider iniziali: OpenAI API, DeepSeek API, provider locale (es. Ollama/compatibile OpenAI API).
- Nessun path business deve dipendere da SDK proprietari.

### FR-02 Policy + Preference Engine
- Livelli policy: tenant, team, user, request.
- Preferenze configurabili: `privacy_first`, `quality_first`, `cost_first`, `latency_first`, `balanced`.
- Routing model scelto da policy + preferenza + disponibilita'.

### FR-03 Intent e Planning
- Chat deve estrarre intent da linguaggio naturale senza obbligo `intent: ...`.
- Fallback deterministico se confidence bassa.
- Ogni risposta deve includere `intent`, `confidence`, `reasoning_summary`.

### FR-04 Action Execution Governata
- Azioni derivate da manifest (`actions`) con validazione parametri.
- `plan` sempre consentito; `apply` richiede approval per azioni critiche.
- Tutte le esecuzioni devono essere idempotenti o con rollback esplicito.

### FR-05 Sicurezza e Guardrails
- Input sanitization e output policy enforcement.
- Redaction segreti obbligatoria in log e chat history.
- Allowlist strumenti/percorsi applicata prima di ogni execution.
- Human confirmation obbligatoria per step classificati come critici dal policy engine.

### FR-06 Osservabilita' e Audit
- Eventi standardizzati per: request, intent, routing, execution, failure, approval.
- Conversation log per tenant/user/agent con ricerca.
- Tracciamento modello usato, motivo scelta, costo stimato/effettivo.

### FR-07 UX Decisionale
- UI/API deve mostrare opzioni profilo (non solo on/off).
- Utente deve poter cambiare preferenza senza downtime.
- Risposta deve sempre chiarire se output viene da cloud, locale o ibrido.

### FR-08 Product Factory e Riuso
- Deve esistere un blueprint ufficiale per avviare un nuovo prodotto dalla piattaforma EasyWay.
- Ogni prodotto derivato deve ereditare guardrail minimi (security, audit, approval, logging).
- Le capability core devono essere versionate e riusabili tramite moduli/shared packages.
- Il processo di manutenzione deve prevedere propagazione standard di fix critici a tutti i prodotti aderenti.

### FR-09 Productization by Default
- Ogni progetto cliente deve includere una "Productization Review" prima della chiusura.
- Per ogni use case completato devono essere classificati:
  - componenti commodity (riutilizzabili);
  - componenti custom (cliente-specifici);
  - effort stimato per generalizzazione.
- Deve esistere un catalogo interno delle "dime" con owner, versione, prerequisiti e domini supportati.
- Deve esistere una policy commerciale/tecnica per il riuso cross-cliente con adattamenti minimi.

## 9. Requisiti Non Funzionali

- NFR-01 Availability: 99.5% su componenti API core.
- NFR-02 Latency: p95 `plan` < 3s, p95 `apply` < 10s (escluso task lunghi esterni).
- NFR-03 Security: zero secret in clear text nei log.
- NFR-04 Compliance: audit trail immutabile per operazioni critiche.
- NFR-05 Scalability: multi-tenant isolamento logico.
- NFR-06 Portability: deploy su server sovereign senza lock-in cloud obbligatorio.
- NFR-07 Economics: ogni richiesta deve tracciare costo stimato/effettivo e budget residuo per tenant.

## 10. Architettura di riferimento

### Componenti
- `Agent Chat API` (entrypoint conversazionale).
- `Intent + Planner` (LLM + fallback regole).
- `Policy/Preference Engine`.
- `Action Executor` (manifest-driven).
- `Provider Gateway` (cloud/local).
- `Audit & Metrics Pipeline`.

### Decisione architetturale chiave
Provider gateway separato dal planner: il planner decide il "cosa", il gateway decide "con quale modello/provider" in base a policy e preferenze.

## 11. API Contract (v1)

### POST `/api/agents/{agentId}/chat`
Request (core):
- `message`
- `conversationId` (optional)
- `context.executionMode` = `plan|apply`
- `context.preferenceProfile` (optional)
- `context.approvalId` (required for critical apply)

Response (core):
- `message`
- `metadata.intent`
- `metadata.confidence`
- `metadata.provider` (`cloud|local|hybrid`)
- `metadata.model`
- `metadata.policyDecision`
- `suggestions[]`

## 12. Multi-Agent Collaboration Model (Codex + Antigravity + ClaudeCode)

### Obiettivo
Usare piu' agenti di sviluppo senza perdere coerenza architetturale.

### Regole operative
1. Un solo backlog canonico (questa roadmap + ticket).
2. Contratti condivisi obbligatori: API schema, eventi audit, manifest schema.
3. PR piccole e verticali con test e DoD verificabile.
4. Nessuna modifica ai guardrail senza review congiunta.
5. Decision log unico (`docs/decisions.md`) per ADR sintetiche.

### Ruoli suggeriti
- Codex: implementazione runtime/API e integrazioni.
- Antigravity: hardening, affidabilita', riduzione rischio operativo.
- ClaudeCode: quality gates, coverage, refactoring e consistency.

## 13. KPI e SLA

### KPI di prodotto
- Intent resolution success rate >= 85% (R1), >= 92% (R2).
- Task completion rate `plan` >= 95%.
- Task completion rate `apply` con approval >= 90%.
- Manual rework reduction >= 30% entro 90 giorni dal go-live.
- Provider switch success >= 99% (nessun downtime percepito).
- Tempo di bootstrap nuovo prodotto <= 5 giorni lavorativi.
- Percentuale componenti core riusate nei nuovi prodotti >= 70%.
- Tempo medio propagazione fix critico core -> prodotti derivati <= 72 ore.
- Percentuale use case cliente convertiti in asset riusabili >= 60%.
- Tempo medio da delivery custom a asset in catalogo <= 10 giorni lavorativi.
- Quota delivery su componenti gia' esistenti (vs nuovo sviluppo) >= 50%.
- Margine medio su use case productizzati >= margine medio use case custom + 20%.
- Sforamento budget AI per tenant < 5% mensile.

### KPI di qualita'
- Policy violation leakage = 0.
- False block rate < 5%.
- p95 latenza dentro soglie NFR.
- Error rate API < 2%.

## 14. Piano di delivery

### Fase A - Server Talk Ready (Week 1-2)
1. Allineare compose/proxy per esposizione API agenti.
2. Stabilizzare auth dev/prod e bootstrap token.
3. E2E smoke test chat + conversations.

### Fase B - Agentic Runtime (Week 3-6)
1. Integrare intent LLM con fallback.
2. Allowlist intent/actions da manifest reale.
3. Execution policy engine (`plan/apply`, approval gates).

### Fase C - Provider Decision Layer (Week 7-10)
1. Implementare preference profiles.
2. Implementare routing cloud/local/ibrido.
3. Implementare cost/latency/privacy-aware fallback.

### Fase D - Scale & Trust (Week 11-16)
1. Dashboard KPI e reporting.
2. Chaos tests provider failure.
3. Rollout progressivo tenant per tenant.

## 14.b Exit Criteria (Pass/Fail) per fase

### R0 Pass/Fail
- PASS se:
  - API chat su server raggiungibile e stabile per 7 giorni;
  - smoke E2E verdi su list/info/chat/conversations;
  - audit base attivo;
  - auth dev/prod verificata.
- FAIL se uno dei punti sopra non e' soddisfatto.

## 14.c Readiness Gate 0 (obbligatorio prima di iniziare)

Nessuna fase operativa parte senza Gate 0 superato.

Checklist Gate 0:
1. Backlog Sprint 1 definito in task atomici con owner, DoD, dipendenze.
2. Piattaforma pilota selezionata (`GitHub` o `ADO` o `Forgejo`) con motivazione.
3. RACI approvato e approvatori assegnati (Tech/Security/Product).
4. Policy minime attive: branch protection, check obbligatori, merge rules.
5. Baseline tecnica verificata: API up, auth valida, logging/audit attivi.
6. KPI baseline inizializzati e soglie pass/fail configurate.
7. Runbook incident e rollback disponibili.
8. Cadence review fissata (es. weekly) con owner e calendario.

Regola:
- Se almeno un item Gate 0 e' `not-ready`, la fase resta bloccata.

### R1 Pass/Fail
- PASS se:
  - intent resolution >= 85%;
  - output con metadata obbligatori (`intent`, `confidence`, `provider`, `model`, `policyDecision`);
  - apply critico sempre bloccato senza approval valida;
  - false block rate < 8%.
- FAIL se uno dei punti sopra non e' soddisfatto.

### R2 Pass/Fail
- PASS se:
  - routing cloud/local/ibrido attivo via policy + preferenze;
  - provider switch success >= 99%;
  - budget guardrails attivi per tenant;
  - p95 latenza entro soglia NFR.
- FAIL se uno dei punti sopra non e' soddisfatto.

### R3/R4 Pass/Fail
- PASS se:
  - multi-agent flow tracciabile end-to-end;
  - productization loop attivo con KPI di conversione;
  - propagation fix critici entro 72 ore.
- FAIL se uno dei punti sopra non e' soddisfatto.

## 15. Backlog iniziale (prioritizzato)

### P0
1. Fix deploy path API in server stack e reverse proxy.
2. Unificare contratto intent in manifest + chat service.
3. Aggiungere test automatici per `/api/agents/*`.
4. Rendere output metadata completo (provider/model/policyDecision).

### P1
1. Provider gateway con adapter cloud/local [DONE].
2. Preference profile e routing policy [DONE].
3. Telemetria costi per request [DONE].
   - Stima token in/out per provider.
   - Calcolo costo USD basato su listino pubblico.
   - Logging su `llm-router-events.jsonl`.

### P2
1. Learning loop su quality metrics [DONE].
3. Product Factory Kit (template + checklist + pipeline standard) [DONE].
   - *Motivazione*: Standardizzare struttura agenti (Manifest, Memory) è prerequisito per l'orchestrazione.
   - *Strategia*:
     - **Phase 1 (Bootstrap Local)**: Uso di `scripts/pwsh/agent-bootstrap.ps1` per creazione rapida e test locale (Developer Experience).
     - **Phase 2 (Automated Factory)**: Aggiornamento di `agent_creator` (n8n-driven) per usare i nuovi template standard, per creazione massiva/governata.
4. Multi-agent workflow orchestration [DONE].
   - *Result*: Implementato `Invoke_SubAgent` tool nel Router. Permette chiamate ricorsive e governate tra agenti.
5. UX avanzata per decision profile guidato (P2.4) [DONE].
   - *Result (P3)*: Implementato `New-DecisionProfile.ps1` wizard interattivo + `decision-profile.schema.json` + 3 profili starter (conservative, moderate, aggressive). Integrato come Step 3 nel Router UX.
6. Processo di propagazione manutenzione core verso prodotti derivati [DONE].
   - *Result*: Implementato `scripts/pwsh/agent-maintenance.ps1` per Lint/Update automatico dei manifesti.
7. Productization Review checklist obbligatoria in chiusura progetto cliente [DONE].
   - *Result*: Creata checklist in `docs/ops/productization-review.md`.
8. Catalogo "dime" (pattern riusabili) con scoring di maturita' e riuso [DONE].
   - *Result (P3)*: Implementate 3 COSTAR Skills (Invoke-Summarize, Invoke-SQLQuery, Invoke-ClassifyIntent) con campo `costar_prompt` in `registry.json`. n8n bridge operativo per composizione visuale agenti.

## 16. Rischi e mitigazioni

1. Drift tra manifest e runtime.
- Mitigazione: validazione schema in CI + contract tests.

2. Complessita' multi-provider.
- Mitigazione: adapter pattern + fallback gerarchico semplice.

3. Costi API non prevedibili.
- Mitigazione: budget caps per tenant + routing cost-aware.

4. Qualita' inconsistente tra modelli.
- Mitigazione: benchmark per dominio + golden prompts + evaluator automatico.

5. Over-automation senza controllo.
- Mitigazione: mandatory approval su classi di azione critiche.

6. Customizzazione eccessiva che rompe la standardizzazione factory.
- Mitigazione:
  - policy "core first": il core non si modifica per esigenze locali senza ADR approvata;
  - ogni richiesta custom deve passare da classificazione `core|config|adapter`;
  - limite massimo di codice cliente-specifico per modulo (soglia definita per team);
  - review obbligatoria di impatto riuso prima del merge.

## 17. Assunzioni

- Esiste un team in grado di mantenere almeno 1 provider cloud e 1 locale.
- Le policy di sicurezza aziendali permettono chat auditing strutturato.
- I manifest agenti restano il contratto canonico di capability.

## 18. Definition of Done (DoD) per milestone

Una milestone e' completata se:
1. requisiti P0/P1 della fase sono implementati;
2. test automatici passano;
3. runbook operativo aggiornato;
4. KPI baseline misurabili in ambiente target;
5. review congiunta multi-agent completata e tracciata.
6. confine `core vs custom` verificato e documentato nei change principali.

## 18.b Guardrail Core vs Custom

Regole vincolanti:
1. Le variazioni cliente-specifiche devono stare in configurazione, template o adapter.
2. Il core condiviso cambia solo per capability riutilizzabili o fix trasversali.
3. Ogni PR con impatto su core deve dichiarare:
- motivo;
- riuso previsto;
- rischio di lock-in cliente.
4. Se una customizzazione non e' riusabile, deve restare isolata fuori dal core.
5. Ogni release include report sintetico: quante modifiche core, quante custom, quante productizzate.

## 18.c Legge Operativa (Flow Vincolante)

Questo flow e' obbligatorio per ogni use case cliente e per ogni evoluzione prodotto.

1. Intake obbligatorio
- Registrare il caso con obiettivo, vincoli, rischio, dominio.

2. Classificazione tecnica obbligatoria
- Classificare ogni richiesta in: `core`, `config`, `adapter`.
- Se non classificata, il lavoro non parte.

3. Design check obbligatorio
- Verificare impatto su riuso, sicurezza, audit, costi.
- Se tocca `core`, aprire ADR prima dell'implementazione.

4. Implementazione governata
- Applicare guardrail policy, approval gates, test minimi richiesti.
- Nessun hardcode cliente nel core.

5. Review pre-merge
- Validare: quality gates, confine `core vs custom`, compliance PRD.
- Se una regola non e' rispettata: merge bloccato.

6. Productization Review (pre-chiusura)
- Estrarre asset riusabili (dime) e registrarli in catalogo.
- Marcare esplicitamente cosa resta custom e perche'.

7. Release + Audit
- Pubblicare changelog con impatti su core/custom.
- Salvare audit trail tecnico e decisionale.

8. KPI checkpoint
- Aggiornare KPI obbligatori (riuso, tempi, errori, propagazione fix).
- Se KPI sotto soglia per 2 cicli: aprire piano correttivo.

9. Maintenance propagation
- Ogni fix critico core deve avere piano di propagazione verso prodotti derivati.
- Stato propagazione tracciato fino a completamento.

### Modalita' di esecuzione per ogni step
- Ogni step e' eseguito dagli agenti quando possibile.
- Ogni step richiede conferma umana prima di passare allo step successivo.
- Se la conferma umana manca, il workflow resta in stato `pending_human_confirmation`.
- Le conferme devono essere auditabili (chi, quando, cosa ha approvato/rifiutato).

Checkpoint minimi con human confirmation obbligatoria:
1. fine classificazione `core|config|adapter`;
2. approvazione ADR quando impatta il core;
3. pre-merge su quality/compliance;
4. productization review finale;
5. release e propagation fix critici.

## 18.d RACI Operativo (vincolante)

Ruoli:
- `Agent System`: esecuzione automatica step, raccolta evidenze, proposta decisioni.
- `Tech Owner`: approvazione tecnica su core/ADR/merge.
- `Product Owner`: approvazione valore prodotto e productization.
- `Security/Compliance Owner`: approvazione per rischio/security/compliance.

RACI per step:
1. Intake
- R: Agent System
- A: Product Owner
- C: Tech Owner
- I: Security/Compliance Owner

2. Classificazione `core|config|adapter`
- R: Agent System
- A: Tech Owner
- C: Product Owner
- I: Security/Compliance Owner

3. Design check + ADR core
- R: Agent System
- A: Tech Owner
- C: Security/Compliance Owner
- I: Product Owner

4. Implementazione governata
- R: Agent System
- A: Tech Owner
- C: Security/Compliance Owner
- I: Product Owner

5. Review pre-merge
- R: Agent System
- A: Tech Owner
- C: Security/Compliance Owner
- I: Product Owner

6. Productization Review
- R: Agent System
- A: Product Owner
- C: Tech Owner
- I: Security/Compliance Owner

7. Release + Audit
- R: Agent System
- A: Tech Owner
- C: Security/Compliance Owner
- I: Product Owner

8. KPI checkpoint
- R: Agent System
- A: Product Owner
- C: Tech Owner
- I: Security/Compliance Owner

9. Maintenance propagation
- R: Agent System
- A: Tech Owner
- C: Product Owner
- I: Security/Compliance Owner

## 18.e Soglie Step Critico (Human Confirmation obbligatoria)

Uno step e' automaticamente `critical` se almeno una condizione e' vera:
1. impatta `core` condiviso;
2. coinvolge dati sensibili o policy security/compliance;
3. execution mode = `apply` su azioni non read-only;
4. costo stimato per singola operazione > 20 EUR;
5. costo mensile tenant previsto > 110% del budget;
6. rischio operativo classificato `high` o `very_high`;
7. modifica guardrail, approval flow o audit pipeline.

Regola:
- se `critical = true`, senza conferma umana lo step non procede.

## 18.f Disciplina Step-by-Step (no-skip policy)

1. Ogni step deve produrre evidenze verificabili (test, log, report, approvazioni).
2. Lo step successivo parte solo se lo step corrente e' `pass`.
3. Se uno step fallisce, si apre remediation task prima di avanzare.
4. Non sono ammessi "salti di fase" per urgenza senza eccezione approvata e tracciata.
5. Il tempo (settimane) non e' criterio di passaggio: vale solo il criterio pass/fail.

## 18.g Principi Antifragili Operativi

1. Piccoli batch, feedback rapidi: preferire rilasci incrementali e frequenti.
2. Failure visible: ogni errore deve essere osservabile e classificabile.
3. Learning loop obbligatorio: ogni incidente produce azione preventiva nel core.
4. Safe-to-fail: testare fallback e rollback in modo periodico.
5. Single source of truth: PRD + backlog canonico + audit trail allineati.
6. No silent debt: deviazioni dagli standard sempre tracciate con owner e data rientro.

## 19. Decisione Go/No-Go

### Go se:
- chat in server stabile;
- policy/approval operative;
- metriche base visibili;
- almeno 1 percorso cloud e 1 locale validato.

### No-Go se:
- apply critico senza approval;
- assenza audit trail;
- fallback provider non affidabile.

## 20. Allegati consigliati (prossimo step)

1. ADR-001 Provider Abstraction.
2. ADR-002 Policy & Preference Hierarchy.
3. Test Plan E2E chat agentica.
4. Runbook Incident Response (provider down, policy breach).
5. Template ADR (obbligatorio per modifiche core).
6. Template Productization Review (obbligatorio in chiusura use case cliente).
7. Template Release Audit Report (obbligatorio per release in ambienti target).

## 21. Propositi di Start e Direzione

Direzione operativa immediata:
1. Creare backlog Sprint 1 (DevOps-first) in task atomici con owner, DoD e dipendenze.
2. Allineare i task a Codex, Antigravity e ClaudeCode con responsabilita' esplicite.
3. Partire con le prime PR P0 e chiuderle con evidenze test/audit.

Principio di auto-allenamento:
- EasyWay deve essere applicato prima di tutto su EasyWay ("self-dogfooding"): usiamo internamente gli stessi standard che proponiamo ai clienti.
- La fiducia si guadagna mostrando execution reale: prima lo facciamo noi, poi lo vendiamo.
- Regola di credibilita': ogni capability proposta al mercato deve avere almeno un caso interno completo e tracciato end-to-end.

## 21.b Integrazione Sprint 1 su Ecosistema DevOps (GitHub, ADO, Forgejo)

Obiettivo:
- Integrare lo Sprint 1 DevOps-first atomico nei tre mondi (`GitHub`, `Azure DevOps`, `Forgejo`), valorizzando le specificita' di ciascuna piattaforma e unificando il controllo tramite agenti.

Regole:
1. Un backlog unico canonico con task atomici, owner, DoD e dipendenze.
2. Mapping piattaforma-specifico per pipeline, policy e workflow PR/MR.
3. Eventi e audit normalizzati in un formato comune per gli agenti.
4. No approccio "big bang": non validare tutti e tre gli ecosistemi in parallelo nella prima iterazione.

Strategia di rollout:
1. Selezionare un ecosistema pilota (es. ADO o Forgejo) per Sprint 1.
2. Validare i task P0 end-to-end sul pilota con evidenze.
3. Estrarre pattern riusabili ("dime DevOps").
4. Replicare progressivamente su GitHub/ADO/Forgejo con adattamenti minimi.

Vincolo di prodotto:
- Ogni capability DevOps introdotta deve dichiarare esplicitamente:
  - livello di supporto per `GitHub`, `Azure DevOps`, `Forgejo`;
  - gap noti;
  - data target di convergenza.

## 21.c Platform Approval Model (GitHub, ADO, Forgejo)

Obiettivo:
- Definire approvatori, controlli e regole di merge per ogni piattaforma, mantenendo un modello di governance coerente.

Requisiti minimi per ogni piattaforma:
1. Definizione ruoli approvatori:
- `Tech Approver` (core/runtime)
- `Security Approver` (policy/compliance/secrets)
- `Product Approver` (scope/valore/release readiness)

2. Regole branch/merge:
- protezione branch principali;
- numero minimo reviewer;
- check obbligatori prima del merge;
- blocco merge su gate falliti.

3. Mapping RACI locale:
- mappare ruoli PR/MR/pipeline ai ruoli RACI del PRD.

4. Audit uniforme:
- ogni approvazione deve essere tracciata con chi/quando/cosa;
- eventi normalizzati in formato comune cross-platform.

5. Matrice capability per piattaforma:
- per ogni capability dichiarare `supported`, `partial`, `planned`.

Nota operativa:
- i nomi tecnici dei ruoli possono cambiare per piattaforma, ma la responsabilita' funzionale deve restare equivalente.

## 21.d PRD come Roadmap Vivente

Questo PRD e' la roadmap operativa passo-passo.

Regole di evoluzione:
1. Il PRD viene aggiornato a ogni sprint con decisioni, gap e priorita' emergenti.
2. Le nuove esigenze importanti entrano come requisiti formalizzati (non solo note informali).
3. Ogni aggiornamento deve mantenere coerenza con missione, KPI e guardrail.

Obiettivo strategico:
- Se il modello e' eseguito bene, il flow risultante deve essere estraibile e riutilizzabile come processo standard per qualsiasi altro progetto della factory.

## 21.e Use Case Pilota Ecosistema Unico (Scheduling Conversazionale)

Titolo:
- Gestione appuntamenti clienti via Portale + Telegram + Calendar Sync.

Descrizione:
- L'utente interagisce dal portale o da Telegram.
- L'agente propone slot disponibili, riceve conferma, blocca il calendario e invia conferma finale.
- Il portale resta la fonte unica di stato e audit.
- Sincronizzazione verso provider esterni (Google/Microsoft/altro) tramite connettori governati.

Perche' e' strategico:
1. E' utile internamente a EasyWay per gestire i propri clienti.
2. E' vendibile come capability immediata verso altri clienti.
3. Dimostra il principio "vendiamo cio' che usiamo davvero e funziona".

Requisiti minimi del pilota:
1. Vista unica portale con stato appuntamento (`pending`, `confirmed`, `rescheduled`, `cancelled`, `sync_error`).
2. Conversazione Telegram tracciata con correlazione a booking.
3. Sync bidirezionale controllata con almeno un provider calendar in fase pilota.
4. Audit end-to-end su intent, azioni, conferme umane, sync esterne.
5. Policy di fallback su errore sync (retry + notifica + remediation task).
6. UX portale orientata anche a utenti non tecnici, con percorsi chiari "da sito" oltre alle funzioni operative avanzate.

## 22. Policy Git Multi-Remote (ADO, GitHub, Forgejo)

### 22.1 Architettura consigliata (stabile)

Single Source of Truth operativo: repository locale sul PC di sviluppo.
Policy generale per tutti gli agenti: `local-first, server-second`.
Ogni agente deve proporre/modificare/validare prima in locale e operare sul server solo dopo conferma, con evidenze e tracciamento audit.

Flusso standard:
- PC -> commit locale -> push verso `ado`
- PC -> commit locale -> push verso `github`
- PC -> commit locale -> push verso `forgejo`

Regola:
- il server non e' master per il lavoro quotidiano;
- niente commit diretti su server/remoti, salvo procedure eccezionali tracciate.

### 22.2 Strategia remoti (consigliata)

Usare 3 remote separati (no multi-push su un solo `origin`), per avere errori chiari e controllo per target.

Esempio:

```bash
git remote add ado     git@ssh.dev.azure.com:v3/ORG/PROJECT/REPO
git remote add github  git@github.com:username/repo.git
git remote add forgejo git@80.225.86.168:username/repo.git
git remote -v
```

Nota standard:
- Best practice target: `SSH for Git`, `PAT only for CLI/API`.
- HTTPS per `git push` e PAT in credential cache e' ammesso solo come fallback temporaneo.

### 22.3 Workflow quotidiano

```bash
git add -A
git commit -m "messaggio"
git push ado <branch>
git push github <branch>
git push forgejo <branch>
```

### 22.4 Regole anti-drift

1. Non fare commit via web UI su GitHub/ADO/Forgejo.
2. Se succede, riallineare esplicitamente dal remoto dove e' avvenuta la modifica:

```bash
git pull github <branch>
git push ado <branch>
git push forgejo <branch>
```

3. Ogni riallineamento cross-remote deve essere tracciato in audit operativo.

### 22.5 SSH Forgejo

Accesso amministrativo server:

```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168
```

Test autenticazione git verso Forgejo:

```bash
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" git@80.225.86.168
```

Checklist:
- Forgejo SSH attivo (porta configurata);
- chiave pubblica registrata nell'account Forgejo;
- risposta di autenticazione positiva.

### 22.6 Script di push sequenziale (obbligatorio consigliato)

```bash
#!/bin/bash
set -euo pipefail

BRANCH="${2:-main}"
MSG="${1:-Update}"

git add -A
git commit -m "$MSG" || true

echo "Pushing to Azure DevOps..."
git push ado "$BRANCH"

echo "Pushing to GitHub..."
git push github "$BRANCH"

echo "Pushing to Forgejo..."
git push forgejo "$BRANCH"

echo "All repositories updated successfully."
```

Regola:
- se un push fallisce, il processo si ferma;
- non si prosegue con merge/release finche' i 3 remoti non sono riallineati.

### 22.6.b Standardizzazione script multi-remote (strutturale)

Lo script di sync non e' opzionale: diventa capability standard della factory.

Requisiti minimi dello script:
1. supporto nativo a `ado`, `github`, `forgejo`;
2. branch parametrico (non solo `main`);
3. modalita' `dry-run`;
4. stop immediato su errore (`fail-fast`);
5. output finale con stato per ogni remoto (`ok|failed`);
6. comando di verifica post-push (`git ls-remote --heads <remote> <branch>`).

Regole operative:
1. nessun merge/release senza esecuzione script con esito completo `ok`;
2. log esecuzione salvato come evidenza in `docs/ops/agent-task-records/` o pipeline artifacts;
3. in caso di failure parziale, aprire task di riallineamento prima di proseguire.

Roadmap miglioramento script:
1. V1: push sequenziale + fail-fast.
2. V2: verifica automatica branch su tutti i remoti.
3. V3: supporto PR automation per ADO/GitHub/Forgejo.
4. V4: integrazione policy engine (blocco se quality gates non verdi).

### 22.7 Opzione enterprise (futura)

Pattern avanzato:
- ADO come primary remote;
- GitHub e Forgejo come mirror automatici (pipeline/webhook);
- PC push solo su ADO.

Nota:
- questa opzione e' prevista come evoluzione DevOps, non come prerequisito iniziale.

### 22.8 Enforcement automatico (obbligatorio)

Per rendere eseguibile la policy `local-first, server-second`, introdurre controlli automatici:
1. CI check che richiede evidenze locali minime prima del merge (test/log/report).
2. PR check che valida presenza di:
- piano step-by-step;
- conferma umana ai checkpoint critici;
- strategia rollback.
3. Blocco merge automatico se manca almeno un requisito.

### 22.9 Agent Task Record (template operativo)

Ogni task eseguito da agenti deve avere un record standard (file o commento strutturato) con:
1. contesto e obiettivo;
2. classificazione `core|config|adapter`;
3. step eseguiti in locale;
4. evidenze prodotte;
5. approvazioni umane ricevute;
6. azioni server eseguite;
7. esito finale e rollback (se applicato).

Formato consigliato:
- `docs/ops/agent-task-records/<YYYY-MM-DD>-<task-id>.md`

### 22.10 Exception Policy (gestione urgenze)

Eccezioni alla regola `local-first` sono ammesse solo per incidenti critici.

Regole:
1. approvazione esplicita di `Tech Owner` o `Security Owner`;
2. tracciare motivazione e rischio prima dell'azione server;
3. aprire post-mortem entro 24 ore;
4. convertire la lezione appresa in controllo permanente (script, gate, runbook).

Vincolo:
- una eccezione senza post-mortem chiuso blocca le successive release non critiche.

### 22.11 Azione prioritaria aperta: migrazione credenziali Git

Problema osservato:
- conflitti tra autenticazione HTTPS Git (credential cache) e token usati da Azure DevOps CLI.

Decisione:
1. migrare i remoti Git critici a SSH (`ssh.dev.azure.com`, `github`, `forgejo`);
2. usare PAT solo per comandi API/CLI (`az repos`, automazioni PR, governance);
3. eliminare credenziali obsolete HTTPS dal credential manager.

Criterio di chiusura:
- push/fetch/clone stabili su SSH in tutti i remoti primari;
- nessun errore ricorrente `Authentication failed` su workflow standard.

### 22.12 Benchmark esterni (adottare per accelerare)

Principio:
- non reinventare: adottare pattern gia' validati e adattarli al contesto EasyWay.

Baseline da seguire:
1. GitHub SSH setup ufficiale:
- https://docs.github.com/en/authentication/connecting-to-github-with-ssh
2. Azure DevOps SSH for Git:
- https://devblogs.microsoft.com/devops/ssh-support-for-git-repos-is-now-available/
3. Git push mirror/prune (rischi e comportamento):
- https://git-scm.com/docs/git-push/2.20.0
4. Riduzione uso PAT (linea Microsoft):
- https://devblogs.microsoft.com/devops/reducing-pat-usage-across-azure-devops/
5. Esempio pratico ssh config Azure multi-key:
- https://gist.github.com/johnkors/f5bb409056934ad289517e3611161bd9

Regola operativa:
1. ogni decisione tecnica su auth/sync deve citare almeno una baseline esterna;
2. se deviamo dalle baseline, documentare motivo e mitigazione nel decision log.

### 22.13 Best Practice vincolante: Branch Governance ADO (anti-sparizione)

Decisione operativa validata (2026-02-14):
- per evitare sparizione branch dovuta a rewrite/delete refs da actor concorrenti, non basta la policy PR;
- serve hardening esplicito in `Branch security` e `Repository security`.

Regole minime obbligatorie:
1. su `main` e `develop` impostare `Deny` su `Force push (rewrite history, delete branches and tags)` per:
- `Contributors`;
- `EasyWay-DataPortal Build Service (EasyWayData)`;
- `Project Collection Build Service Accounts`;
- `Project Collection Service Accounts`.
2. mantenere override solo per gruppi admin (`Project Administrators`, `Project Collection Administrators`) per break-glass controllato.
3. non usare `Not set` per permessi critici: puo' ereditare `Allow`.
4. in caso di incidente branch disappearance, eseguire subito:
- snapshot `git ls-remote --heads ado`;
- monitor multi-sample;
- correlazione con `Organization settings -> Audit logs`.

KPI di stabilita':
1. zero eventi `missing` nei monitor post-push;
2. zero `forced-update` inattesi su branch protetti;
3. nessuna ricorrenza di ripristino manuale branch oltre 7 giorni operativi.

Riferimenti operativi (vincolanti):
1. runbook multi-provider:
- `Wiki/EasyWayData.wiki/Runbooks/multivcs-branch-guardrails.md`
2. sync standard branch:
- `docs/ops/GIT_SAFE_SYNC.md`
3. policy check required in PR (ADO):
- `Wiki/EasyWayData.wiki/checklist-ado-required-job.md`
4. enforcer guardrail CI:
- `Wiki/EasyWayData.wiki/enforcer-guardrail.md`

### 22.14 Regola vincolante: Retrieval sempre da RAG server

Decisione:
- ogni agente deve leggere contesto/knowledge operativo interrogando il RAG server-side come fonte primaria.

Regole obbligatorie:
1. vietato usare copie locali non sincronizzate come source of truth per decisioni operative;
2. prima di ogni task rilevante, eseguire retrieval da endpoint RAG del server;
3. se il RAG server non e' disponibile:
- aprire stato `degraded`;
- usare fallback locale solo in read-only;
- tracciare evento in audit con motivazione e timestamp;
- rieseguire retrieval server prima di push/merge/release.
4. ogni output agente deve indicare evidenza minima di retrieval (query id, timestamp o riferimento log).

Criterio di conformita':
1. `no retrieval evidence -> no merge` per task agentici core;
2. deviazioni ammesse solo come eccezione incident, con approvazione esplicita.

### 22.15 Multi-VCS Agent MVP (capability distribuibile)

Obiettivo:
- avere un agente unico riusabile anche fuori EasyWay che gestisca ADO, GitHub, Forgejo con lo stesso workflow operativo.

Capability minime:
1. `validate-auth`: verifica accesso SSH/API ai remoti configurati;
2. `sync`: push multi-remote con verifica post-push multi-pass e repair opzionale;
3. `monitor`: monitor branch presence con log evidenza;
4. `create-pr`: apertura PR cross-provider (ADO/GitHub/Forgejo) via CLI dedicati.

Artefatti MVP:
1. `agents/core/tools/agent-multi-vcs.ps1`
2. `scripts/pwsh/multi-vcs.config.example.ps1`
3. `docs/ops/MULTI_VCS_AGENT_MVP.md`

Regola di prodotto:
- il comportamento deve essere provider-agnostic lato workflow, provider-specific solo nel layer di integrazione CLI/API.

### 22.16 Access Matrix (RAG server + template agent)

Scopo:
- rendere espliciti endpoint e path operativi da usare come riferimento unico per tutti gli agenti.

Server validato:
- host: `ubuntu@80.225.86.168`
- repo root: `/home/ubuntu/EasyWayDataPortal`

RAG runtime (server-side):
1. script retrieval principale:
- `/home/ubuntu/EasyWayDataPortal/agents/skills/retrieval/rag_search.py`
2. configurazione endpoint:
- `QDRANT_HOST` (default `localhost`)
- `QDRANT_PORT` (default `6333`)
- `QDRANT_API_KEY` (required in ambienti protetti)
3. collection canonica:
- `easyway_wiki`
4. url base runtime:
- `http://<QDRANT_HOST>:<QDRANT_PORT>`

Runbook RAG:
1. file:
- `/home/ubuntu/EasyWayDataPortal/Wiki/EasyWayData.wiki/Runbooks/rag-operations.md`
2. ingestion standard:
- `docker exec easyway-runner bash -c 'cd /app/scripts && node ingest_wiki.js'`

Template agent (server-side):
1. template per singolo agente:
- `/home/ubuntu/EasyWayDataPortal/agents/<agent_name>/templates`
2. template core condivisi:
- `/home/ubuntu/EasyWayDataPortal/agents/core/templates`
3. retrieval skills condivise:
- `/home/ubuntu/EasyWayDataPortal/agents/skills/retrieval`

Regola operativa:
1. ogni agente deve fare retrieval contro il RAG server usando questa matrice;
2. ogni scaffolding/modifica template deve partire dai path canonici sopra, non da copie locali non allineate;
3. qualsiasi variazione endpoint/path richiede update immediato di questa sezione PRD + runbook.

### 22.17 Branch Coordination Agent (multi-worker scheduling)

Obiettivo:
- permettere lavoro parallelo su piu' branch da piu' worker (macchine locali, Codex, Antigravity, ClaudeCode) senza collisioni.

Capability:
1. recommendation automatica `stay|switch-branch|create-and-switch`;
2. lease esplicita branch per worker (`claim`);
3. heartbeat lease durante il lavoro;
4. release a fine task/handoff.

Artefatti:
1. `agents/core/tools/agent-branch-coordinator.ps1`
2. `docs/ops/BRANCH_COORDINATION_AGENT.md`
3. lease store: `docs/ops/branch-leases.json`

Regola:
1. nessun worker inizia implementazione senza `recommend` + `claim`;
2. branch protette (`main`, `develop`, `baseline`) non devono essere usate come branch di lavoro ordinario.

### 22.18 LLM Router Antifragile (control plane minimo)

Obiettivo:
- introdurre un punto unico di controllo per chiamate LLM multi-provider con fallback, audit e safety gate umano.

Capability:
1. routing provider con priorita' e circuit breaker;
2. policy `critical action -> mandatory human approval`;
3. log eventi append-only (`invoke_success|invoke_failed|invoke_blocked|approval_*`);
4. enforcement `no RAG evidence -> no operational invoke`.

Artefatti:
1. `agents/core/tools/agent-llm-router.ps1`
2. `scripts/pwsh/llm-router.config.ps1` (da template)
3. `scripts/pwsh/llm-router.config.example.ps1`
4. `docs/ops/LLM_ROUTER_ANTIFRAGILE.md`
5. integrazione opzionale in:
- `agents/core/tools/agent-multi-vcs.ps1` (`-UseLlmRouter` per drafting PR)
- `agents/core/tools/agent-branch-coordinator.ps1` (`-UseLlmRouter` per advisory scheduling)

Stato runtime (git-ignored):
1. `docs/ops/llm-router-state.json`
2. `docs/ops/logs/llm-router-events.jsonl`
3. `docs/ops/approvals/*.json`

### 22.19 Handoff operativo ad Antigravity (vincolante)

Obiettivo:
- trasferire l'operativita' quotidiana ad Antigravity mantenendo gli stessi guardrail e la stessa evidenza audit.

Nota di governance:
- le regole di questa sezione sono standard EasyWay trasversali e si applicano a qualunque operatore/team/agent runtime (non solo Antigravity).

Entrypoint canonici:
1. sync branch sicuro:
- `pwsh -NoProfile -File .\scripts\pwsh\git-safe-sync.ps1 -Branch develop -Remote origin -Mode align -SetGuardrails`
2. runbook branch guardrails multi-provider:
- `Wiki/EasyWayData.wiki/Runbooks/multivcs-branch-guardrails.md`
3. policy check required (ADO):
- `Wiki/EasyWayData.wiki/checklist-ado-required-job.md`
4. guardrail CI enforcer:
- `Wiki/EasyWayData.wiki/enforcer-guardrail.md`

Checklist minima prima del passaggio:
1. branch protection coerente su `Azure DevOps`, `GitHub`, `Forgejo` per `main`/`develop`;
2. `Force push` e delete branch negati ai contributor su branch critici;
3. PR policy con check required attivi e verificati;
4. runbook aggiornati e versionati in repo;
5. owner e backup owner nominati per ogni piattaforma.

Definition of Done handoff:
1. Antigravity completa almeno 1 ciclo end-to-end (`sync -> branch -> commit -> PR -> merge`) senza bypass policy;
2. audit log disponibile con evidenza di controlli e approvazioni;
3. nessun incidente `branch missing` per almeno 7 giorni operativi consecutivi;
4. documentazione allineata: PRD + runbook + eventuali note operative.

Regole naming branch per PBI (vincolanti):
1. pattern primario DevOps: `feature/devops/PBI-<id>-<slug>`;
2. pattern ammessi dominio-specifici:
- `feature/frontend/PBI-<id>-<slug>`
- `feature/backend/PBI-<id>-<slug>`
- `hotfix/devops/INC-<id>-<slug>`
- `hotfix/devops/BUG-<id>-<slug>`
- `chore/devops/PBI-<id>-<slug>`
3. sotto `hotfix` non usare `PBI`: usare solo `INC-<id>` o `BUG-<id>`.
4. ogni PR deve mantenere corrispondenza branch <-> titolo usando stesso id (`PBI`, `INC` o `BUG`).

Modello identita' Antigravity (vincolante):
1. vietato uso account personali per operazioni agentiche;
2. creare gruppi minimi:
- `grp.repo.agents.read`
- `grp.repo.agents.write`
- `grp.repo.agents.pr`
- `grp.repo.agents.release`
- `grp.repo.agents.admin` (break-glass)
3. creare utenti servizio minimi:
- `svc.agent.antigravity.devops`
- `svc.agent.antigravity.release`
- `svc.agent.antigravity.guard`
4. assegnare least privilege ai gruppi e non direttamente agli utenti;
5. credenziali separate per provider (`ADO`/`GitHub`/`Forgejo`) con rotazione periodica.

Riferimento operativo RBAC multi-provider:
- `Wiki/EasyWayData.wiki/Runbooks/multivcs-rbac-bootstrap.md`

### 22.20 Protocollo di Partenza Pulita (vincolante)

Obiettivo:
- garantire che ogni nuovo ciclo di lavoro parta da regole, branch e policy coerenti, evitando eredita' operative ambigue.

Regole di ingresso (obbligatorie):
1. usare `develop` come base di lavoro sincronizzata;
2. non avviare attivita' su branch legacy/non conformi;
3. applicare naming branch canonico:
- `feature/<domain>/PBI-<id>-<slug>`
- `chore/devops/PBI-<id>-<slug>`
- `bugfix/FIX-<id>-<slug>`
- `hotfix/devops/INC-<id>-<slug>` o `hotfix/devops/BUG-<id>-<slug>`
4. vietato usare `PBI` sotto `hotfix`;
5. PR obbligatoria verso `develop` (eccetto hotfix: `main` poi back-merge su `develop`).

Checklist di bootstrap (prima di iniziare):
1. confermare branch protection attiva su `main`/`develop`;
2. confermare check required attivi:
- `BranchPolicyGuard`
- `EnforcerCheck`
3. confermare gruppi/identita' tecniche allineate al runbook RBAC;
4. confermare assenza di bypass policy non autorizzati;
5. confermare runbook e PRD allineati all'ultima decisione.

Criterio di conformita' operativa:
1. nessun task entra in implementazione se la checklist bootstrap non e' verde;
2. nessun merge se naming/target branch non rispettano le policy;
3. ogni eccezione deve essere tracciata con owner, motivazione e data di rientro.

Pulizia branch bootstrap (regola operativa):
1. i branch temporanei di bootstrap (`chore-*`, `*-template`) devono essere chiusi/rimossi dopo il merge su `develop`;
2. la nuova operativita' deve partire solo da branch `feature/<domain>/PBI-*` per sviluppo ordinario;
3. usare branch `hotfix/devops/INC-*` o `hotfix/devops/BUG-*` solo per incident reali e urgenti.

## 23. ToDo List Vivente e Gestione Contesto

### 23.1 ToDo List Vivente

Il PRD mantiene una todo-list operativa da aggiornare a ogni sprint.

Regole:
1. ogni nuova decisione importante genera una voce todo (implementare/validare/documentare);
2. ogni voce ha owner, priorita', data target, stato;
3. nessuna voce critica puo' restare senza owner.

Formato minimo:
- `ID`
- `Titolo`
- `Owner`
- `Priorita'` (`P0|P1|P2`)
- `Stato` (`todo|in_progress|blocked|done`)
- `Next action`

### 23.2 Regola di Context Hygiene (80%)

Per evitare degradazione del contesto in chat lunghe:
1. quando il contesto utile stimato raggiunge ~80%, l'agente deve produrre un sunto strutturato;
2. il sunto deve includere: decisioni prese, stato task, blocchi aperti, prossimi passi;
3. l'agente deve consigliare esplicitamente di ripartire da una nuova chat usando quel sunto come input;
4. il sunto diventa artefatto persistente in `docs/ops/` o sezione log del PRD.

Output consigliato del sunto:
1. `Stato attuale`
2. `Decisioni chiave`
3. `Task completati`
4. `Task aperti`
5. `Rischi/Blocchi`
6. `Prompt di ripartenza per nuova chat`

### 22.19 Regola vincolante: Agent Pre-Flight Branch Check

Decisione operativa (2026-02-16):
- ogni agente (Codex, Antigravity, ClaudeCode, o qualsiasi tool agentico) DEVE verificare il branch attivo PRIMA di toccare qualsiasi file.

Regole obbligatorie:
1. prima di qualsiasi modifica codice, eseguire: `git branch --show-current`;
2. se il branch e' `main`, `develop` o `baseline`: STOP. Creare un feature branch (`feature/<scope>-<short-name>`);
3. il nome del feature branch deve essere concordato con l'utente se non ovvio dal contesto;
4. solo dopo conferma del branch corretto, procedere con le modifiche;
5. a fine lavoro, ricordare all'utente di procedere via PR per il merge.

Enforcement tecnico:
- le istruzioni operative per gli agenti risiedono in `.agent/workflows/`;
- il file `.agent/workflows/start-feature.md` contiene il workflow pre-flight vincolante;
- la cartella `.agent/` e' riservata a istruzioni macchina per gli agenti: NON e' documentazione per umani;
- ogni agente con accesso alla repository deve leggere `.agent/workflows/` prima di iniziare il lavoro.

Relazione con altre regole:
- 22.17 (Branch Coordination Agent): gli agenti devono eseguire `recommend + claim` prima di lavorare;
- 22.13 (Branch Governance ADO): i branch protetti hanno `Deny` su force push;
- la presente regola aggiunge il check pre-flight obbligatorio come primo step operativo.

Criterio di conformita':
1. commit diretto su `main` o `develop` da parte di un agente = violazione tracciabile;
2. se avviene, aprire post-mortem con azione correttiva entro 24 ore.

### 22.21 Regola vincolante: Agent-Assisted PR Link Pattern

Decisione operativa (2026-02-16):
- per mitigare rischi di credenziali (PAT management) e garantire ownership umana, l'agente DEVE privilegiare la creazione assistita rispetto alla creazione diretta via CLI.

Regole obbligatorie:
1. L'agente prepara il branch (feature), il commit e il push.
2. L'agente genera il **link diretto pre-compilato** per la creazione della PR (es. `https://dev.azure.com/.../pullrequestcreate?...`).
3. L'agente fornisce all'utente il link, il titolo e la descrizione da usare.
4. L'utente umano clicca, verifica visivamente e crea la PR con la propria identità.

Eccezioni ammesse:
- Pipeline CI/CD completamente automatizzate (dove l'identità è un Service Principal).
- Task massivi ripetitivi esplicitamente autorizzati (es. dependency update automatici).

Vantaggi attesi:
- Zero gestione PAT lato agente locale.
- Audit trail sempre riconducibile a una persona fisica responsabile.
- Ultimo controllo umano (HITL) obbligatorio prima dell'apertura formale.

### 22.22 Merge Strategy e Eternal Branches (Policy DevOps)

Decisione operativa (2026-02-16):
- Al fine di mantenere una history pulita su `main` ma dettagliata su `develop`, si adottano le seguenti strategie di merge vincolanti.

#### A. Strategie di Merge per Target Branch

| Target Branch | Strategia | Settings Policy ADO | Motivo |
|---------------|-----------|---------------------|--------|
| **`main`** | **Squash Commit** | `Limit merge types` = `Squash` | Mantiene la history di produzione lineare e pulita (1 release = 1 commit). |
| **`develop`** | **Merge (No Fast-Forward)** | `Limit merge types` = `Merge` | Mantiene il dettaglio completo di ogni feature e i riferimenti ai branch originali per debug. |
| **`feature/*`** | **Squash o Rebase** | (Opzionale) | Per feature branch di lunga durata, preferire rebase su develop locale. |

#### B. Eternal Branches (Mai cancellare)

Regola assoluta:
- I branch **`main`** e **`develop`** sono **ETERNI**.
- **Mai** selezionare "Delete source branch" quando si fa merge DA `develop`.
- **Sempre** selezionare "Delete source branch" quando si fa merge DA `feature/*` (o `bugfix/*`, `hotfix/*`).

#### C. Configurazione DevOps (Branch Policies)

Per ogni repo EasyWay, le seguenti policy devono essere attive su `main` e `develop`:
1. **Require a minimum number of reviewers**: 1 (o 2 per main).
2. **Check for linked work items**: Required (tracciabilità PBI).
3. **Limit merge types**:
   - Su `main`: Bloccare `Merge`, permettere solo `Squash`.
   - Su `develop`: Permettere `Merge` e `Squash`.
4. **Build validation**: Pipeline di CI obbligatoria (se presente).


