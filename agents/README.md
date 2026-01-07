# 🧑‍💻 agents/ — EntryPoint per tutti gli agent di EasyWay DataPortal

Questa directory raccoglie _tutti gli agent_ agentici del progetto EasyWay DataPortal.  
Gli agent sono servizi/script modulari, ognuno responsabile di una funzione chiave (provisioning, audit, doc, governance, QA, ecc), **self-contained**, con manifest/documentazione propria, pronti per essere usati, estesi, automatizzati o orchestrati (anche via n8n).

---

## 📁 Indice agent attuali

| Agent                    | Manifest      | Descrizione breve                                 | Template/Ricetta demo       |
|--------------------------|--------------|--------------------------------------------------|-----------------------------|
| agent_ams                | manifest.json | Automazione operativa conversazionale (Checklist, Variable Group, deploy helpers) | templates/, doc/ |
| agent_api                | manifest.json | Triage e tracciamento errori API; produce output strutturato per orchestrazioni n8n. | templates/, doc/ |
| agent_datalake           | manifest.json | Gestione operativa e compliance del Datalake: naming, ACL, audit, retention, export log, policy. | templates/, doc/ |
| agent_dba                | manifest.json | Gestione migrazioni DB, drift check, documentazione ERD/SP, RLS rollout | templates/, doc/ |
| agent_docs_review        | manifest.json | Revisione documentazione: normalizzazione Wiki, indici/chunk, coerenza KB, supporto aggiunta ricette. | templates/, doc/ |
| agent_dq_blueprint       | manifest.json | Genera un blueprint iniziale di regole DQ (Policy Proposal + Policy Set) da CSV/XLSX/schema, integrato con ARGOS. | templates/, doc/ |
| agent_frontend           | manifest.json | Mini-portal e UI demo, integrazione branding, MSAL wiring | templates/, doc/ |
| agent_governance         | manifest.json | Policy, qualità, gates e approvazioni per DB/API/Docs | templates/, doc/ |
| agent_pr_manager         | manifest.json | Crea e propone Pull Request agentiche con esiti gates e riferimenti artifact. Nessun merge autonomo. | templates/, doc/ |
| agent_scrummaster        | manifest.json | Facilitatione agile conversazionale: backlog/roadmap, governance operativa, DoD/gates, allineamento Epics/Features/Tasks. | templates/, doc/ |
| agent_template           | manifest.json | Scheletro di agente agent-first: intent JSON, azioni idempotenti, output strutturato, allowed_paths. | templates/, doc/ |

*(Aggiungi qui ogni nuovo agent, aggiorna la tabella custom)*

---

## 📜 Come aggiungere un nuovo agent

1. Copia da `agent_template/` tutte le cartelle base (manifest.json, templates/, test/, doc/)
2. Compila manifest e README con obiettivi/capability
3. Registra template/demo in agents/agent_nome/templates/
4. (Opzionale) Inserisci esempio call/test in test/
5. Aggiorna questa tabella qui sopra!

---

## 🔗 Quicklinks & reference

- [Onboarding centrale](../wiki/EasyWayData.wiki/onboarding/README.md)
- [Best practice agent e scripting cross-platform](../wiki/EasyWayData.wiki/onboarding/best-practice-scripting.md)
- [Guide sandbox/zero trust](../wiki/EasyWayData.wiki/onboarding/setup-playground-zero-trust.md)
- [Developer & agent experience upgrades](../wiki/EasyWayData.wiki/onboarding/developer-agent-experience-upgrades.md)
- [Knowledge base vettoriale (AI/RAG/LLM)](../wiki/EasyWayData.wiki/ai/knowledge-vettoriale-easyway.md)
- [Documentazione: contesto standard](../wiki/EasyWayData.wiki/onboarding/documentazione-contesto-standard.md)
- [Glossario, FAQ, troubleshooting](../wiki/EasyWayData.wiki/glossario-errori-faq.md)

---

> 📢 Contribuisci migliorando agent, ricette, test e documentazione!  
> Proponi PR, issue o suggerimenti dove vuoi ampliare automazione e best practice.

